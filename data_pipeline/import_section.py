#!/usr/bin/env python3
"""
import_section.py — generic importer for Al-Azkar.db sections.

Reads a section scheme (JSON) and inserts it into assets/db/Al-Azkar.db:
  - one stable row in `titles` (name/freq/hierarchy metadata)
  - one row in `contents` per item (contiguous `order` 1..N within section)
  - `search` is derived exactly like the original xlsx tool:
        strip tashkeel, strip hamza-ish/unused, collapse spaces;
        any QuranText[(s:f:to)] becomes its concatenated digits (e.g. 112143 -> 112:1:4? no:
        '112 1 4' -> '11214') matching existing rows like '112141131511416'.
  - bumps PRAGMA user_version (must be mirrored by AzkarDBHelper.dbVersion).

Usage:
  python3 import_section.py <scheme.json> [--db PATH] [--new-version N]
"""

import argparse
import json
import os
import re
import shutil
import sqlite3
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.abspath(
    os.path.join(THIS_DIR, "..", "alazkar", "assets", "db", "Al-Azkar.db")
)

QURAN_BLOCK = re.compile(r"QuranText\[[^\]]*\]")
QURAN_TUPLE = re.compile(r"\((\d+):(\d+):(\d+)\)")


def normalize_for_search(body: str) -> str:
    if not body:
        return ""
    body = re.sub(r"[\u064b-\u0652\u0653-\u065f\u0670\u0640]", "", body)
    body = body.replace("ﷺ", "")
    body = body.replace("(", " ").replace(")", " ")
    body = body.replace("[", " ").replace("]", " ")
    body = body.replace("،", " ").replace("؛", " ").replace(":", " ").replace(".", " ").replace("؟", " ")
    body = body.replace(",", " ").replace("‘", "").replace("’", "")
    body = re.sub(r"\s+", " ", body).strip()
    return body


def build_search(body: str) -> str:
    def quran_digits(m):
        return "".join(f"{s}{f}{t}" for s, f, t in QURAN_TUPLE.findall(m.group(0)))

    if "QuranText" in body:
        # replace each QuranText[...] block with its concatenated sura+from+to digits,
        # matching the original DB (e.g. (112:1:4),(113:1:5),(114:1:6) -> 112141131511416)
        stripped = QURAN_BLOCK.sub(quran_digits, body)
        return normalize_for_search(stripped)
    return normalize_for_search(body)


def read_scheme(path: str) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def connect(db_path: str) -> sqlite3.Connection:
    con = sqlite3.connect(db_path)
    con.execute("PRAGMA foreign_keys = ON;")
    return con


def backup(db_path: str) -> str:
    bak = db_path + ".bak"
    shutil.copy2(db_path, bak)
    return bak


def validate_node(title: dict, items: list) -> str:
    node_type = title.get("nodeType", "content")
    if node_type not in {"category", "content"}:
        raise ValueError("title.nodeType must be 'category' or 'content'")
    if node_type == "content" and not items:
        raise ValueError("content titles require at least one item")
    if node_type == "category" and items:
        raise ValueError("category titles cannot contain items")
    return node_type


def validate_parent(cur: sqlite3.Cursor, parent_id: int | None) -> None:
    if parent_id is None:
        return
    parent = cur.execute(
        "SELECT nodeType FROM titles WHERE id = ?", (parent_id,)
    ).fetchone()
    if parent is None:
        raise ValueError(f"parentId {parent_id} does not exist")
    if parent[0] != "category":
        raise ValueError(f"parentId {parent_id} is not a category")


def next_title_order(cur: sqlite3.Cursor, parent_id: int | None) -> int:
    if parent_id is None:
        return cur.execute(
            "SELECT COALESCE(MAX(`order`),0)+1 FROM titles WHERE parentId IS NULL"
        ).fetchone()[0]
    return cur.execute(
        "SELECT COALESCE(MAX(`order`),0)+1 FROM titles WHERE parentId = ?",
        (parent_id,),
    ).fetchone()[0]


def upsert_title(cur: sqlite3.Cursor, title: dict) -> tuple[int, int, list[int]]:
    existing = cur.execute(
        "SELECT id, `order` FROM titles WHERE name = ?", (title["name"],)
    ).fetchall()
    if len(existing) > 1:
        raise ValueError(f"duplicate title name: {title['name']}")
    if existing:
        return update_title(cur, title, existing[0])
    return insert_title(cur, title)


def update_title(
    cur: sqlite3.Cursor,
    title: dict,
    existing: tuple[int, int],
) -> tuple[int, int, list[int]]:
    title_id, current_order = existing
    content_ids = [
        row[0]
        for row in cur.execute(
            "SELECT id FROM contents WHERE titleId = ? ORDER BY `order`",
            (title_id,),
        ).fetchall()
    ]
    deleted_contents = cur.execute(
        "DELETE FROM contents WHERE titleId = ?", (title_id,)
    ).rowcount
    title_order = title.get("order", current_order)
    cur.execute(
        """UPDATE titles
           SET `order` = ?, name = ?, freq = ?, parentId = ?, nodeType = ?
           WHERE id = ?""",
        (
            title_order,
            title["name"],
            title["freq"],
            title["parentId"],
            title["nodeType"],
            title_id,
        ),
    )
    print(f"updated existing title id {title_id} ({deleted_contents} contents removed)")
    return title_id, title_order, content_ids


def insert_title(cur: sqlite3.Cursor, title: dict) -> tuple[int, int, list[int]]:
    title_id = title.get("id") or cur.execute(
        "SELECT COALESCE(MAX(id),0)+1 FROM titles"
    ).fetchone()[0]
    title_order = title.get("order") or next_title_order(cur, title["parentId"])
    cur.execute(
        """INSERT INTO titles (id, `order`, name, freq, parentId, nodeType)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (
            title_id,
            title_order,
            title["name"],
            title["freq"],
            title["parentId"],
            title["nodeType"],
        ),
    )
    return title_id, title_order, []


def replace_contents(
    cur: sqlite3.Cursor, title_id: int, existing_ids: list[int], items: list
) -> None:
    next_id = cur.execute("SELECT COALESCE(MAX(id),0)+1 FROM contents").fetchone()[0]
    for content_order, item in enumerate(items, start=1):
        if item.get("id") is not None:
            content_id = int(item["id"])
        elif content_order <= len(existing_ids):
            content_id = existing_ids[content_order - 1]
        else:
            content_id = next_id
            next_id += 1
        body = item["body"].strip()
        cur.execute(
            """INSERT INTO contents
               (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                content_id,
                title_id,
                content_order,
                body,
                1 if item.get("count") is None else int(item["count"]),
                (item.get("source") or "").strip(),
                (item.get("hokm") or "").strip(),
                (item.get("fadl") or "").strip(),
                build_search(body),
                "",
            ),
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("scheme", help="path to section scheme JSON")
    parser.add_argument("--db", default=DEFAULT_DB)
    parser.add_argument("--new-version", type=int, help="PRAGMA user_version to set")
    args = parser.parse_args()

    scheme = read_scheme(args.scheme)
    title = scheme["title"]
    items = scheme.get("items", [])
    try:
        node_type = validate_node(title, items)
    except ValueError as error:
        print(f"ERROR: {error}")
        return 1

    bak = backup(args.db)
    print(f"backup -> {bak}")

    con = connect(args.db)
    cur = con.cursor()
    try:
        cur.execute("BEGIN")

        parent_id = title.get("parentId")
        validate_parent(cur, parent_id)
        title["parentId"] = parent_id
        title["nodeType"] = node_type
        next_title_id, next_title_order, existing_content_ids = upsert_title(cur, title)
        print(f"title {next_title_id}: {title['name']} (order {next_title_order}, freq {title['freq']})")
        replace_contents(cur, next_title_id, existing_content_ids, items)

        # version
        if args.new_version is not None:
            cur.execute(f"PRAGMA user_version = {args.new_version}")
            print(f"user_version -> {args.new_version}")

        con.commit()
    except Exception:
        con.rollback()
        raise
    finally:
        con.close()

    # verification
    con = connect(args.db)
    cur = con.cursor()
    print("\n=== verify ===")
    print("titles  :", cur.execute("SELECT COUNT(*) FROM titles").fetchone()[0])
    print("contents:", cur.execute("SELECT COUNT(*) FROM contents").fetchone()[0])
    print("titleId :", next_title_id, "contents rows:", cur.execute("SELECT COUNT(*) FROM contents WHERE titleId=?", (next_title_id,)).fetchone()[0])
    print("contiguous order breaks:",
          cur.execute(
              "SELECT COUNT(*) FROM contents GROUP BY titleId HAVING COUNT(*) + MIN(`order`) - 1 <> MAX(`order`) OR MIN(`order`) <> 1"
          ).fetchall())
    print("broken rows (null body/count/titleId):",
          cur.execute("SELECT COUNT(*) FROM contents WHERE body IS NULL OR count IS NULL OR titleId IS NULL").fetchone()[0])
    print("orphan titleId:",
          cur.execute("SELECT COUNT(*) FROM contents WHERE titleId NOT IN (SELECT id FROM titles)").fetchone()[0])
    print("hokm outside set:",
          cur.execute("SELECT COUNT(*) FROM contents WHERE hokm IS NULL OR (hokm NOT IN ('صحيح','حسن','ضعيف','موضوع','أثر','قرآني') AND hokm <> '')").fetchone()[0])
    print("user_version:", cur.execute("PRAGMA user_version").fetchone()[0])
    cur.execute(
        "SELECT id, `order`, name, freq, parentId, nodeType FROM titles WHERE id=?",
        (next_title_id,),
    )
    print("title row:", cur.fetchone())
    cur.execute("SELECT `order`, COUNT(*), substr(REPLACE(body,'\n',' '), 1, 42) FROM contents WHERE titleId=? GROUP BY `order`", (next_title_id,))
    for r in cur.fetchall():
        print(" content", r)
    con.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
