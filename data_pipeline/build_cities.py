"""Builds alazkar/assets/data/cities.json, the city list the reminders use
to name the device location, choose the calculation method, and stand in
when the location is refused.

Places, coordinates and countries: GeoNames cities15000 (CC BY 4.0).
Arabic names: Wikidata labels (CC0), matched by GeoNames ID; failing that, by
English name and country, accepted only when GeoNames lists the same Arabic
name for the place; failing that, the place's only Arabic name in GeoNames.

Run from the repository root: python3 data_pipeline/build_cities.py
"""

import csv
import io
import json
import re
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

GEONAMES = "https://download.geonames.org/export/dump/cities15000.zip"
SPARQL = "https://query.wikidata.org/sparql"
AGENT = "zaad-al-dhakir-cities/1.0 (support@menemlabs.tech)"
OUT = Path(__file__).resolve().parent.parent / "alazkar" / "assets" / "data" / "cities.json"

ARAB = {
    "EG", "SA", "YE", "AE", "QA", "KW", "BH", "OM", "JO", "PS", "LB", "SY",
    "IQ", "SD", "LY", "TN", "DZ", "MA", "MR", "SO", "DJ", "KM",
}
MUSLIM = {
    "TR", "IR", "PK", "AF", "BD", "ID", "MY", "BN", "MV", "AZ", "KZ", "UZ",
    "TM", "KG", "TJ", "AL", "XK", "BA", "SN", "ML", "NE", "TD", "GM", "GN",
    "SL", "BF", "NG",
}
ARAB_MIN = 150_000
MUSLIM_MIN = 700_000
OTHER_MIN = 2_000_000


def selected(row):
    code, feature, population = row[8], row[7], int(row[14] or 0)
    if feature == "PPLC":
        return True
    if code in ARAB:
        return population >= ARAB_MIN
    if code in MUSLIM:
        return population >= MUSLIM_MIN
    return population >= OTHER_MIN


ARABIC = re.compile(r"^[\u0621-\u064A ]+$")


def fold(name):
    """Folds the spellings that differ between sources: hamza forms, taa marbuta, alif maqsura."""
    return re.sub("[أإآ]", "ا", name).replace("ة", "ه").replace("ى", "ي").strip()


def arabic_alternates(row):
    return [name for name in row[3].split(",") if ARABIC.match(name)]


def fallback_name(row, english_match):
    """The Arabic name for a place Wikidata did not link by GeoNames ID."""
    alternates = arabic_alternates(row)
    if english_match and fold(english_match) in {fold(name) for name in alternates}:
        return english_match
    if len(alternates) == 1:
        return alternates[0]
    return None


def entries(rows, city_names, country_names):
    out, seen = [], set()
    for row in rows:
        name, country = city_names.get(row[0]), country_names.get(row[8])
        if not name or not country or (name, row[8]) in seen:
            continue
        seen.add((name, row[8]))
        out.append([name, country, row[8], round(float(row[4]), 4), round(float(row[5]), 4)])
    out.sort(key=lambda entry: (entry[1], entry[0]))
    return out


def sparql(query):
    request = urllib.request.Request(
        SPARQL,
        data=urllib.parse.urlencode({"query": query}).encode(),
        headers={"Accept": "application/sparql-results+json", "User-Agent": AGENT},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.load(response)["results"]["bindings"]


def arabic_by_english_name(rows):
    labels = {}
    for start in range(0, len(rows), 100):
        chunk = " ".join(f'({json.dumps(r[2])}@en "{r[8]}")' for r in rows[start:start + 100])
        query = (
            f"SELECT ?n ?c ?l WHERE {{ VALUES (?n ?c) {{ {chunk} }} "
            "?i rdfs:label ?n ; wdt:P17 ?k ; wdt:P31/wdt:P279* wd:Q486972 ; rdfs:label ?l . "
            '?k wdt:P297 ?c . FILTER(lang(?l) = "ar") }'
        )
        for binding in sparql(query):
            labels.setdefault((binding["n"]["value"], binding["c"]["value"]), []).append(binding["l"]["value"])
        time.sleep(1)
    return labels


def arabic_labels(prefix, prop, values):
    labels = {}
    for start in range(0, len(values), 200):
        chunk = " ".join(f'"{value}"' for value in values[start:start + 200])
        query = (
            f"SELECT ?v ?l WHERE {{ VALUES ?v {{ {chunk} }} "
            f'?i wdt:{prop} ?v . ?i rdfs:label ?l FILTER(lang(?l) = "ar") }}'
        )
        for binding in sparql(query):
            labels.setdefault(binding["v"]["value"], binding["l"]["value"])
        time.sleep(1)
    print(f"{prefix}: {len(labels)} of {len(values)} have an Arabic name")
    return labels


def main():
    with urllib.request.urlopen(GEONAMES, timeout=120) as response:
        archive = zipfile.ZipFile(io.BytesIO(response.read()))
    text = archive.read("cities15000.txt").decode("utf-8")
    rows = [r for r in csv.reader(io.StringIO(text), delimiter="\t", quoting=csv.QUOTE_NONE) if selected(r)]
    print(f"selected {len(rows)} places")
    cities = arabic_labels("cities", "P1566", sorted({r[0] for r in rows}))
    missing = [r for r in rows if r[0] not in cities]
    by_english = arabic_by_english_name(missing)
    for row in missing:
        candidates = by_english.get((row[2], row[8]), [])
        name = next((n for n in (fallback_name(row, c) for c in candidates) if n), None) or fallback_name(row, None)
        if name:
            cities[row[0]] = name
    still = [f"{r[8]} {r[2]}" for r in rows if r[0] not in cities]
    print(f"fallback named {len(missing) - len(still)} of {len(missing)}; left out: {', '.join(still)}")
    countries = arabic_labels("countries", "P297", sorted({r[8] for r in rows}))
    result = entries(rows, cities, countries)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = ",\n".join(json.dumps(entry, ensure_ascii=False) for entry in result)
    OUT.write_text(f"[\n{lines}\n]\n", encoding="utf-8")
    print(f"wrote {len(result)} places to {OUT}")


if __name__ == "__main__":
    main()
