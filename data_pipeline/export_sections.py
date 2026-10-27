#!/usr/bin/env python3
"""
export_sections.py — write data_pipeline/sections/*.json from Al-Azkar.db.

The database is the source (#236); every title gets one section file, a copy
of its row and of its contents rows in order. Run it in the same change as
any migration that touches `titles` or `contents`;
alazkar/test/section_files_test.dart fails until the files match.

A title keeps its current file, found by `title.id`, or by the title's name
for an old file without one. A title with no file gets `section_<id>.json`.
A file whose title is no longer in the database is deleted.

Usage:
  python3 export_sections.py [--db PATH] [--sections DIR]
"""

import argparse
import json
import os
import sqlite3
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.abspath(
    os.path.join(THIS_DIR, "..", "alazkar", "assets", "db", "Al-Azkar.db")
)
DEFAULT_SECTIONS = os.path.join(THIS_DIR, "sections")


def read_titles(con: sqlite3.Connection) -> dict[int, dict]:
    titles = {}
    for id_, order, name, freq, parent_id, node_type in con.execute(
        'SELECT id, "order", name, freq, parentId, nodeType FROM titles ORDER BY id'
    ):
        title = {"id": id_, "order": order, "name": name, "freq": freq}
        if parent_id is not None:
            title["parentId"] = parent_id
        title["nodeType"] = node_type
        titles[id_] = title
    return titles


def read_items(con: sqlite3.Connection) -> dict[int, list[dict]]:
    items: dict[int, list[dict]] = {}
    for id_, title_id, body, count, hokm, source, fadl, style in con.execute(
        """SELECT id, titleId, body, count, hokm, source, fadl, style
           FROM contents ORDER BY titleId, "order\""""
    ):
        item = {
            "id": id_,
            "body": body,
            "count": count,
            "hokm": hokm,
            "source": source,
            "fadl": fadl,
        }
        if style:
            item["style"] = style
        items.setdefault(title_id, []).append(item)
    return items


def current_files(sections: str, titles: dict[int, dict]) -> dict[int, str]:
    ids_by_name: dict[str, list[int]] = {}
    for title in titles.values():
        ids_by_name.setdefault(title["name"], []).append(title["id"])

    file_of: dict[int, str] = {}
    orphans = []
    for name in sorted(os.listdir(sections)):
        if not name.endswith(".json"):
            continue
        with open(os.path.join(sections, name), encoding="utf-8") as f:
            title = json.load(f)["title"]
        title_id = title.get("id")
        if title_id is None:
            ids = ids_by_name.get(title["name"], [])
            if len(ids) != 1:
                raise ValueError(f"{name}: no title.id, and {len(ids)} titles named {title['name']}")
            title_id = ids[0]
        if title_id not in titles:
            orphans.append(name)
            continue
        if title_id in file_of:
            raise ValueError(f"{name}: title {title_id} already in {file_of[title_id]}")
        file_of[title_id] = name

    for name in orphans:
        os.remove(os.path.join(sections, name))
        print(f"deleted {name}: its title is not in the database")
    return file_of


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=DEFAULT_DB)
    parser.add_argument("--sections", default=DEFAULT_SECTIONS)
    args = parser.parse_args()

    con = sqlite3.connect(f"file:{args.db}?mode=ro", uri=True)
    try:
        titles = read_titles(con)
        items = read_items(con)
    finally:
        con.close()

    try:
        file_of = current_files(args.sections, titles)
    except ValueError as error:
        print(f"ERROR: {error}")
        return 1

    written = 0
    for title_id, title in titles.items():
        name = file_of.get(title_id, f"section_{title_id}.json")
        path = os.path.join(args.sections, name)
        text = json.dumps(
            {"title": title, "items": items.get(title_id, [])},
            ensure_ascii=False,
            indent=2,
        ) + "\n"
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                if f.read() == text:
                    continue
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        written += 1

    print(f"{len(titles)} titles, {written} files written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
