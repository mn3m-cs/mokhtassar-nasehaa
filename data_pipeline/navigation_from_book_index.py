#!/usr/bin/env python3
"""
navigation_from_book_index.py — writes migration 167 (#220).

The navigation tree becomes a copy of the book's index (docs/book-index.json):
every chapter a category, every index line a section, in the printed order.
A line the book prints only in a footnote ("notASection") is no section
(decisions 5 and 13).

Each section's rows are given below as the row id where the line starts in the
book; the rows up to the next line's start belong to it. Rows printed under a
category before its first line belong to the first section under it. Only
`titleId` and `order` of `contents` change.

An old content section keeps its id on the line whose name it carries (أذكار
الصباح -> أولًا: أذكار الصباح); otherwise on the section that receives its
first row. A section left without an id (its rows spread to other sections)
is listed in MOVED, so the favourites saved on it follow its first row.

Run it against the database at dbVersion 166:
  python3 navigation_from_book_index.py [--db PATH] [--apply]
It writes migrations/167_navigation_as_book_index.sql and, with --apply, runs
it on the database and sets user_version 167.
"""

import argparse
import json
import os
import re
import sqlite3
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(THIS_DIR, ".."))
DEFAULT_DB = os.path.join(ROOT, "alazkar", "assets", "db", "Al-Azkar.db")
INDEX = os.path.join(ROOT, "docs", "book-index.json")
OUT = os.path.join(THIS_DIR, "migrations", "167_navigation_as_book_index.sql")
VERSION = 167

# The root category the index does not cover (decision 7).
ABOUT_BOOK = 99

# Old sections whose rows each index unit (a category holding sections)
# covers, in book order.
UNITS = {
    "أذكارُ الصَّباحِ والمساء": [1, 2, 3, 106],
    "أذكار الاستيقاظ": [4, 94, 95],
    "أذكار الوضوء": [5],
    "أذكار اللِّباس": [6],
    "أذكار دخول البيت، والخروج منه": [7],
    "أذكار المسجد": [8, 167, 109, 168, 169],
    "أذكار الأذان": [9, 114],
    "أذكار الصلاة": [10, 11, 12, 13, 17, 14, 15, 16, 115, 116, 117, 118, 119, 121],
    "أذكار النَّوْمِ": [18, 30, 31, 170],
    "الأذكار والدعوات للأمور العارضة": list(range(32, 41)),
    "أذكار المَرَض": [41, 42, 43, 44],
    "أذكار الموت": [45, 46],
    "أذكار الصيام": [48],
    "أذكار المُسافِر": [139, 49],
    "أدعية الحَجِّ والعُمْرَةِ والزِّيارة": [50, 51, 52, 164, 53, 136, 54, 55, 56, 59],
    "أذكار الغزو والجهاد": [60],
    "أذكار الأكل والشرب": [61, 62],
    "أذكار النكاح": [63, 64],
    "أذكار تتعلق بالأمور العلوية": [65],
    "أولًا: من القرآن الكريم": [66],
    "ثانيًا: أذكار متفرِّقة من السُّنَّةِ الشَّرِيفَة": [67, 68],
    # The six lines of the second part that stand before its first chapter.
    None: [147],
    "أنواع وصِيَغ الأوراد المأثورة": [
        148, 149, 165, 152, 69, 161, 151, 70, 153, 71, 72, 154, 176, 74,
        177, 75, 172, 76, 155, 156, 157, 181, 182, 184, 185, 187, 188, 190,
        178, 179,
    ],
    "النوع الرابعَ عَشَرَ: أدعية القرآن الكريم والسُّنَّة الصحيحة (الأدعية المطلقة)": [159, 160, 166],
    "جامعُ أدعيةِ القرآنِ المجيدِ والسُّنَّةِ الصحيحة (الأدعية المُطلقة)": [92, 82, 83, 84, 93, 86, 87, 88, 89, 90, 91],
}

# Rows that move to another unit's place in the book order:
# (row id, unit, row id it follows).
ROW_MOVES = [
    # p32: the end of «اختلاف العلماء…», stored at the top of the evening.
    (1235, "أذكارُ الصَّباحِ والمساء", 1232),
    # pp263-264: the opening of «أنواع وصيغ الأوراد المأثورة».
    (1435, "أنواع وصِيَغ الأوراد المأثورة", None),
    (1436, "أنواع وصِيَغ الأوراد المأثورة", 1435),
]

# Where each line starts: the id of its first row. The first line of a unit
# always starts at the unit's first row.
STARTS = {
    "أذكارُ الصَّباحِ والمساء": [1232, 1, 32, 53, 1013],
    "أذكار الاستيقاظ": [889, 891],
    "أذكار الوضوء": [61],
    "أذكار اللِّباس": [1639, 66, 67],
    "أذكار دخول البيت، والخروج منه": [72, 74],
    "أذكار المسجد": [76, 1010, 78, 1532, 894],
    "أذكار الأذان": [1539, 1540, 1541, 900, 1015],
    "أذكار الصلاة": [
        912, 1213, 920, 1214, 103, 116, 1217, 1218, 1221, 1223, 1224, 946,
        1198, 1200, 1202, 1023, 1030, 1253, 1033, 1035, 1044,
    ],
    "أذكار النَّوْمِ": [1644, 214, 216],
    "الأذكار والدعوات للأمور العارضة": [218, 227, 236, 242, 243, 1264, 245, 246],
    "أذكار المَرَض": [248, 1599, 1602, 253, 1611, 1612],
    "أذكار الموت": [1620, 1625, 1626, 1629, 1631, 1632, 1633, 1635, 284, 286, 287, 1637],
    "أذكار الصيام": [1313, 1314, 1315, 1317],
    "أذكار المُسافِر": [1278, 310, 311, 1281, 1282, 1283, 315, 1284, 1286, 1288],
    "أدعية الحَجِّ والعُمْرَةِ والزِّيارة": [
        1322, 1326, 1329, 1333, 1338, 1345, 1350, 1360, 1361, 1366, 1372,
        1374, 1376, 1380, 1381, 1384, 1385, 1389, 348,
    ],
    "أذكار الغزو والجهاد": [353, 354, 355, 1292, 1295, 1296],
    "أذكار الأكل والشرب": [1301, 1302, 1303, 1304, 1305, 1306],
    "أذكار النكاح": [393, 1267, 881, 398],
    "أذكار تتعلق بالأمور العلوية": [1268, 1270, 1271, 409, 410, 411],
    "أولًا: من القرآن الكريم": [414, 415, 418, 419, 1580, 422, 425, 428, 429, 430, 1581],
    "ثانيًا: أذكار متفرِّقة من السُّنَّةِ الشَّرِيفَة": [
        1584, 1585, 1586, 1587, 1588, 1592, 1593, 1594, 1595, 1596, 1597,
        1598, 1550, 1551, 1554, 1556, 1557, 1558, 1559, 1561, 464, 465, 1564,
        1565, 1567, 1569, 1572, 1573, 1574, 1575, 1576, 1579,
    ],
    None: [1395, 1400, 1409, 1413, 1429],
    "أنواع وصِيَغ الأوراد المأثورة": [
        # النوع الأول
        1447, 1448, 1453, 1455, 1460, 1464,
        # النوع الثاني: its opening (pp281-283) goes to its first line
        1474, 1486,
        # النوع الثالث
        1487, 1498, 1501, 1503,
        # النوع الرابع
        1700, 1717, 1737,
        # النوع الخامس
        1750,
        # النوع السادس
        1761, 1775, 1782,
        # النوع السابع, then «من صيغ الحمد:»
        1808, 1824, 1830,
        # النوع الثامن
        1836, 1841, 1859,
        # النوع التاسع
        1866, 1868,
        # النوع العاشر
        1870, 1890,
        # النوع الحادي عشر
        1904, 1914,
        # النوع الثاني عشر
        1924,
        # النوع الثالث عشر
        1941, 1947, 1949, 1963, 1971, 1976, 1980,
    ],
    "النوع الرابعَ عَشَرَ: أدعية القرآن الكريم والسُّنَّة الصحيحة (الأدعية المطلقة)": [1176, 1507],
    "جامعُ أدعيةِ القرآنِ المجيدِ والسُّنَّةِ الصحيحة (الأدعية المُطلقة)": [647, 646, 606, 2016, 833, 2037, 710, 2063, 2075, 828],
}

# Categories kept under their id with the index's name; the others are new.
CATEGORY_IDS = {
    "أذكارُ الصَّباحِ والمساء": 100,
    "أذكار المسجد": 108,
    "أذكار الصلاة": 96,
    "أذكار النَّوْمِ": 122,
    "الأذكار والدعوات للأمور العارضة": 162,
    "أذكار المَرَض": 123,
    "أذكار الموت": 124,
    "أذكار المُسافِر": 133,
    "أدعية الحَجِّ والعُمْرَةِ والزِّيارة": 128,
    "الأذكار المتفرِّقة": 163,
    "أنواع وصِيَغ الأوراد المأثورة": 140,
    "النوع الأول: تلاوة القرآن الكريم": 141,
    "النوع الثاني: وِرْدُ التهليل (لا إله إلَّا الله)": 143,
    "النوع الثالث: وِرْدُ الصَّلاةِ والسَّلامِ عَلَى سَيِّدِ الأنامِ ﷺ": 142,
    "النوع الرابع: الاستغفار": 144,
    "النوع الخامس: وِرْدُ الباقياتِ الصَّالحات": 145,
    "النوع السادس: وِرْدُ التَّسْبيح": 173,
    "النوع السابع: وِرْدُ التحميد": 174,
    "النوع الثامن: وِرْدُ التكبير": 175,
    "النوع التاسع: وِرْدُ الحَوْلَقة": 146,
    "النوع العاشر: وِرْدُ الدعاء بالعافية": 180,
    "النوع الحادي عشر: وِرْدُ الحَسْبَلة": 183,
    "النوع الثاني عشر: وِرْدُ الدعاء للوالدين في حياتهما وبعدَ موتهما": 186,
    "النوع الثالثَ عشَرَ: التعوُّذات": 189,
    "النوع الرابعَ عَشَرَ: أدعية القرآن الكريم والسُّنَّة الصحيحة (الأدعية المطلقة)": 158,
    "جامعُ أدعيةِ القرآنِ المجيدِ والسُّنَّةِ الصحيحة (الأدعية المُطلقة)": 191,
}

# Sections that keep their id on a line other than the one the rules above
# would pick, because an introduction section (139, 161) lands on the same
# line first: «أذكار المسافر» (49, a default favourite) and «فضل الصلاة على
# النبي ﷺ» (151) keep their ids on the lines that hold their rows.
ID_OVERRIDES = {
    49: "ما يقول المسافر ومَن يُودِّعه",
    151: "فضل الصلاة والسلام على رسول الله ﷺ",
}


def norm(s):
    s = re.sub(r"[ً-ٰٟـ]", "", s or "")
    s = s.replace("ﷺ", "")
    for a, b in (("أ", "ا"), ("إ", "ا"), ("آ", "ا"), ("ى", "ي"), ("ة", "ه")):
        s = s.replace(a, b)
    s = re.sub(r"[^ء-ي ]", " ", s)
    s = re.sub(r"^(اولا|ثانيا|ثالثا) ", "", re.sub(r"\s+", " ", s).strip())
    return s


def is_section(node):
    return "children" not in node and "notASection" not in node


def units(entries):
    """(unit key, the unit's category node or None, its sections)"""
    loose = [e for e in entries if is_section(e)]
    yield None, None, loose
    stack = [e for e in entries if "children" in e]
    for node in stack:
        sections = [c for c in node["children"] if is_section(c)]
        nested = [c for c in node["children"] if "children" in c]
        if node["name"] in UNITS:
            # a unit takes the sections of its nested categories too
            def flat(n):
                for c in n["children"]:
                    if "children" in c:
                        yield from flat(c)
                    elif is_section(c):
                        yield c
            yield node["name"], node, list(flat(node))
        else:
            assert not sections, node["name"]
            stack.extend(nested)


def build(db):
    index = json.load(open(INDEX, encoding="utf-8"))
    titles = {
        r[0]: {"id": r[0], "order": r[1], "name": r[2], "freq": r[3], "parentId": r[4], "nodeType": r[5]}
        for r in db.execute('SELECT id, "order", name, freq, parentId, nodeType FROM titles')
    }
    rows_of = {}
    for cid, tid in db.execute('SELECT id, titleId FROM contents ORDER BY titleId, "order"'):
        rows_of.setdefault(tid, []).append(cid)

    moved_rows = {r for r, _, _ in ROW_MOVES}
    # the book-ordered rows of each unit
    seq = {}
    for key, tids in UNITS.items():
        seq[key] = [r for t in tids for r in rows_of[t] if r not in moved_rows]
    for row, key, after in ROW_MOVES:
        s = seq[key]
        s.insert(0 if after is None else s.index(after) + 1, row)

    covered = sorted(r for s in seq.values() for r in s)
    in_units = sorted(r for t in (t for ts in UNITS.values() for t in ts) for r in rows_of[t])
    assert covered == in_units, "every row of the units is placed once"
    content_ids = {t for t, v in titles.items() if v["nodeType"] == "content"}
    outside = content_ids - {t for ts in UNITS.values() for t in ts}
    assert all(titles[t]["parentId"] == ABOUT_BOOK for t in outside), outside

    # rows of each line
    line_rows = {}  # id(node) -> rows
    nodes = {}
    for key, node, sections in units(index["entries"]):
        starts = STARTS[key]
        assert len(starts) == len(sections) - 1, (key, len(starts), len(sections))
        s = seq[key]
        cut = [0] + [s.index(r) for r in starts] + [len(s)]
        assert cut == sorted(cut) and len(set(cut)) == len(cut), key
        for sec, a, b in zip(sections, cut, cut[1:]):
            line_rows[id(sec)] = s[a:b]
            nodes[id(sec)] = sec

    # ids of the sections
    old_first = {t: rows_of[t][0] for t in content_ids if t in rows_of}
    section_of_row = {r: k for k, rs in line_rows.items() for r in rs}
    sid = {}
    for k, sec in nodes.items():
        for t in (t for ts in UNITS.values() for t in ts):
            if norm(titles[t]["name"]) == norm(sec["name"]):
                assert k not in sid, sec["name"]
                sid[k] = t
    for t, name in ID_OVERRIDES.items():
        k = next(k for k, n in nodes.items() if n["name"] == name)
        assert k not in sid, name
        sid[k] = t
    taken = set(sid.values())
    for t in (t for ts in UNITS.values() for t in ts):
        if t in taken:
            continue
        k = section_of_row[old_first[t]]
        if k in sid:
            continue
        sid[k] = t
        taken.add(t)
    moved = {
        t: section_of_row[old_first[t]]
        for t in (t for ts in UNITS.values() for t in ts)
        if t not in taken
    }
    next_id = max(titles) + 1

    def new_id():
        nonlocal next_id
        next_id += 1
        return next_id - 1

    for k in nodes:
        if k not in sid:
            sid[k] = new_id()

    # the tree
    out_titles = []  # (id, order, name, parentId, nodeType)
    contents = []  # (row id, titleId, order)
    used_cats = set()

    def emit(node, parent, order):
        if "children" in node:
            cid = CATEGORY_IDS.get(node["name"]) or new_id()
            used_cats.add(cid)
            out_titles.append((cid, order, node["name"], parent, "category"))
            o = 0
            for ch in node["children"]:
                if "children" in ch or is_section(ch):
                    o += 1
                    emit(ch, cid, o)
        else:
            t = sid[id(node)]
            out_titles.append((t, order, node["name"], parent, "content"))
            for i, r in enumerate(line_rows[id(node)], 1):
                contents.append((r, t, i))

    o = 1  # «حول الكتاب» stays first
    for e in index["entries"]:
        if "children" in e or is_section(e):
            o += 1
            emit(e, None, o)

    kept = {t for t, *_ in out_titles} | {ABOUT_BOOK} | {
        t for t, v in titles.items() if v["parentId"] == ABOUT_BOOK
    }
    dropped = sorted(set(titles) - kept)
    for t in dropped:
        assert titles[t]["nodeType"] == "category" or t in moved, t
    moved_to = {t: sid[k] for t, k in moved.items()}
    return titles, out_titles, contents, dropped, moved_to


def sql_str(s):
    return "'" + s.replace("'", "''") + "'"


def write_sql(titles, out_titles, contents, dropped, moved_to):
    lines = [
        "PRAGMA foreign_keys = ON;",
        "BEGIN;",
        "",
        "-- #220: the navigation is the book's index (pp446-464), copied in",
        "-- docs/book-index.json and written out by",
        "-- data_pipeline/navigation_from_book_index.py. Every chapter is a",
        "-- category and every index line a section, in the printed order; a line",
        "-- the book prints only in a footnote is no section. Only `titleId` and",
        "-- `order` of `contents` change; no text does.",
        "-- Sections no longer in the tree, with the section their favourites",
        "-- move to: " + ", ".join(f"{a}->{b}" for a, b in sorted(moved_to.items())),
        "",
        "-- Park every node at the root with a free order, so the unique sibling",
        "-- orders hold while the tree is rebuilt.",
        'UPDATE titles SET parentId = NULL, "order" = 1000 + id WHERE id <> 99 AND parentId IS NOT 99;',
    ]
    old = set(titles)
    for t, order, name, parent, kind in out_titles:
        if t in old:
            continue
        lines.append(
            "INSERT INTO titles (id, \"order\", name, freq, parentId, nodeType) "
            f"VALUES ({t}, {1000 + t}, {sql_str(name)}, 'd', NULL, '{kind}');"
        )
    # contents move before node types change
    for r, t, i in contents:
        lines.append(f'UPDATE contents SET titleId = {t}, "order" = {i} WHERE id = {r};')
    for t, order, name, parent, kind in out_titles:
        lines.append(
            f"UPDATE titles SET nodeType = '{kind}', name = {sql_str(name)} WHERE id = {t};"
        )
    for t in dropped:
        lines.append(f"DELETE FROM titles WHERE id = {t};")
    # parents top-down, then the printed orders
    for t, order, name, parent, kind in out_titles:
        if parent is not None:
            lines.append(f"UPDATE titles SET parentId = {parent} WHERE id = {t};")
    for t, order, name, parent, kind in out_titles:
        lines.append(f'UPDATE titles SET "order" = {order} WHERE id = {t};')
    lines += [f"PRAGMA user_version = {VERSION};", "COMMIT;", ""]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=DEFAULT_DB)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    db = sqlite3.connect(a.db)
    assert db.execute("PRAGMA user_version").fetchone()[0] == VERSION - 1
    titles, out_titles, contents, dropped, moved_to = build(db)
    sql = write_sql(titles, out_titles, contents, dropped, moved_to)
    open(OUT, "w", encoding="utf-8").write(sql)
    print(f"wrote {OUT}: {len(out_titles)} titles, {len(contents)} rows, dropped {dropped}")
    print("moved favourites:", moved_to)
    if a.apply:
        db.executescript(sql)
        db.execute("VACUUM")
        print("applied; user_version", db.execute("PRAGMA user_version").fetchone()[0])


if __name__ == "__main__":
    sys.exit(main())
