#!/usr/bin/env python3
"""
honorific_glyphs.py — the book's honorific glyphs and the words they stand for.

«مختصر النصيحة» prints the honorifics as glyphs: ﷺ, ﵁, ﷿ and the rest
(#213). The app stores them the same way in `body`, `source` and `fadl`,
while `search` keeps the words, so a reader who types «رضي الله عنه» finds
the zikr.

Run as a script, it writes the migration that turns the words into glyphs in
Al-Azkar.db, and a fixture of every cell it changes, as it was before:
  python3 honorific_glyphs.py <out.sql> <before.json> --version N [--db PATH]
"""

import argparse
import json
import os
import re
import sqlite3
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.abspath(
    os.path.join(THIS_DIR, "..", "alazkar", "assets", "db", "Al-Azkar.db")
)

# Longest first: «رضي الله عنهما» before «رضي الله عنهم» before «رضي الله عنه».
# «صلى الله عليه وآله وسلم» stays in words (#226).
GLYPHS = [
    ("صلى الله عليه وسلم", "ﷺ"),
    ("رضي الله عنهما", "﵄"),
    ("رضي الله عنهم", "﵃"),
    ("رضي الله عنها", "﵂"),
    ("رضي الله عنه", "﵁"),
    ("رحمه الله", "﵀"),
    ("سبحانه وتعالى", "﷾"),
    ("عز وجل", "﷿"),
]
WORDS = {glyph: words for words, glyph in GLYPHS}

COLUMNS = ("body", "source", "fadl")
_MARKS = "[ً-ْٰـ]*"
_LETTER = "[ء-ي]"


def _pattern(words: str) -> re.Pattern:
    letters = [_MARKS.join(re.escape(ch) for ch in word) + _MARKS for word in words.split()]
    return re.compile(rf"(?<!{_LETTER}){r'\s+'.join(letters)}(?!{_LETTER})")


_PATTERNS = [(_pattern(words), glyph) for words, glyph in GLYPHS]


def to_glyphs(text: str) -> str:
    """The text with each honorific in words, marked or bare, as its glyph.
    Quran between ﴿ ﴾ is left as it is."""
    parts = re.split(r"(﴿.*?﴾)", text)
    for i in range(0, len(parts), 2):
        for pattern, glyph in _PATTERNS:
            parts[i] = pattern.sub(glyph, parts[i])
    return "".join(parts)


def to_words(text: str) -> str:
    for glyph, words in WORDS.items():
        text = text.replace(glyph, words)
    return text


def _sql_str(text: str) -> str:
    return "'" + text.replace("'", "''") + "'"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("sql")
    parser.add_argument("fixture")
    parser.add_argument("--db", default=DEFAULT_DB)
    parser.add_argument("--version", type=int, required=True)
    args = parser.parse_args()

    con = sqlite3.connect(f"file:{args.db}?mode=ro", uri=True)
    rows = con.execute(f"SELECT id, {', '.join(COLUMNS)} FROM contents ORDER BY id").fetchall()
    con.close()

    lines = [
        "PRAGMA foreign_keys = ON;",
        "BEGIN;",
        "",
        "-- The book prints the honorifics as glyphs (#213): ﷺ ﵁ ﵂ ﵃ ﵄ ﵀ ﷾ ﷿.",
        "-- Written by data_pipeline/honorific_glyphs.py. Only the words of an",
        "-- honorific change; `search` keeps the words.",
        "",
    ]
    before: dict[str, dict[str, str]] = {}
    for id_, *texts in rows:
        changed = {}
        for column, text in zip(COLUMNS, texts):
            if text and to_glyphs(text) != text:
                changed[column] = text
        if changed:
            before[str(id_)] = changed
            sets = ", ".join(f"{c} = {_sql_str(to_glyphs(t))}" for c, t in changed.items())
            lines.append(f"UPDATE contents SET {sets} WHERE id = {id_};")
    lines += ["", f"PRAGMA user_version = {args.version};", "COMMIT;", ""]

    with open(args.sql, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    with open(args.fixture, "w", encoding="utf-8") as f:
        json.dump(before, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"{len(before)} rows, {sum(len(c) for c in before.values())} cells")
    return 0


if __name__ == "__main__":
    sys.exit(main())
