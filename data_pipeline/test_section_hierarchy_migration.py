import sqlite3
import tempfile
import unittest
from pathlib import Path


MIGRATION = Path(__file__).parent / "migrations" / "126_section_hierarchy.sql"


class SectionHierarchyMigrationTest(unittest.TestCase):
    def test_migration_preserves_legacy_title_and_content_ids(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            database_path = Path(temporary_directory) / "legacy.db"
            connection = sqlite3.connect(database_path)
            connection.executescript(
                """
                PRAGMA foreign_keys = ON;
                CREATE TABLE titles (
                  id INTEGER NOT NULL PRIMARY KEY,
                  "order" INTEGER NOT NULL,
                  name TEXT,
                  freq TEXT
                );
                CREATE TABLE contents (
                  id INTEGER NOT NULL PRIMARY KEY,
                  titleId INTEGER NOT NULL REFERENCES titles(id),
                  "order" INTEGER NOT NULL,
                  body TEXT NOT NULL,
                  count INTEGER NOT NULL,
                  source TEXT,
                  hokm TEXT,
                  fadl TEXT,
                  search TEXT,
                  sourceIndex TEXT
                );
                INSERT INTO titles VALUES (10, 12, 'دعاء الاستفتاح', 'd');
                INSERT INTO contents VALUES
                  (907, 10, 1, 'نص تجريبي', 1, '', 'صحيح', '', 'نص تجريبي', '');
                PRAGMA user_version = 125;
                """
            )

            connection.executescript(MIGRATION.read_text(encoding="utf-8"))

            self.assertEqual(connection.execute("PRAGMA user_version").fetchone()[0], 126)
            self.assertEqual(
                connection.execute(
                    "SELECT id, parentId, nodeType FROM titles"
                ).fetchall(),
                [(10, None, "content")],
            )
            self.assertEqual(
                connection.execute("SELECT id, titleId FROM contents").fetchall(),
                [(907, 10)],
            )
            self.assertEqual(connection.execute("PRAGMA foreign_key_check").fetchall(), [])
            connection.close()


if __name__ == "__main__":
    unittest.main()
