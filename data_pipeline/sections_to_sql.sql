-- Prints the SQL that rewrites the rows of the sections listed in `files`, read
-- from their JSON, so the JSON and the database come from the same text:
--
--   sqlite3 alazkar/assets/db/Al-Azkar.db < data_pipeline/sections_to_sql.sql
--
-- Run from the repository root. The rows of every listed section are deleted
-- first, then inserted again in the file's order, so an id can move from one
-- section to another. `search` is derived as import_section.py's
-- normalize_for_search does for a body without QuranText: tashkeel and tatweel
-- out, ﷺ out, punctuation and line breaks to spaces, spaces collapsed.
WITH RECURSIVE
files(fidx, path) AS (VALUES
  (1, 'data_pipeline/sections/absolute_adhkar_introduction.json'),
  (2, 'data_pipeline/sections/quran_introduction.json'),
  (3, 'data_pipeline/sections/quran_recitation_virtues.json'),
  (4, 'data_pipeline/sections/quran_tahzib.json')
),
docs(fidx, doc) AS (
  SELECT fidx, CAST(readfile(path) AS TEXT) FROM files WHERE readfile(path) IS NOT NULL
),
items(fidx, tid, ord, id, body, cnt, source, hokm, fadl) AS (
  SELECT docs.fidx, json_extract(docs.doc, '$.title.id'), CAST(je.key AS INTEGER) + 1,
         json_extract(je.value, '$.id'), json_extract(je.value, '$.body'),
         json_extract(je.value, '$.count'), json_extract(je.value, '$.source'),
         json_extract(je.value, '$.hokm'), json_extract(je.value, '$.fadl')
  FROM docs, json_each(docs.doc, '$.items') AS je
),
cp(n) AS (SELECT 1611 UNION ALL SELECT n + 1 FROM cp WHERE n < 1631),
steps(k, f, t) AS (
  SELECT n - 1610, char(n), '' FROM cp
  UNION ALL SELECT 22, char(1648), ''
  UNION ALL SELECT 23, char(1600), ''
  UNION ALL SELECT 24, char(65018), ''
  UNION ALL SELECT 25, '(', ' '
  UNION ALL SELECT 26, ')', ' '
  UNION ALL SELECT 27, '[', ' '
  UNION ALL SELECT 28, ']', ' '
  UNION ALL SELECT 29, char(1548), ' '
  UNION ALL SELECT 30, char(1563), ' '
  UNION ALL SELECT 31, ':', ' '
  UNION ALL SELECT 32, '.', ' '
  UNION ALL SELECT 33, char(1567), ' '
  UNION ALL SELECT 34, ',', ' '
  UNION ALL SELECT 35, char(8216), ''
  UNION ALL SELECT 36, char(8217), ''
  UNION ALL SELECT 37, char(10), ' '
  UNION ALL SELECT 38, char(13), ' '
  UNION ALL SELECT 39, '  ', ' '
  UNION ALL SELECT 40, '  ', ' '
  UNION ALL SELECT 41, '  ', ' '
  UNION ALL SELECT 42, '  ', ' '
  UNION ALL SELECT 43, '  ', ' '
  UNION ALL SELECT 44, '  ', ' '
  UNION ALL SELECT 45, '  ', ' '
  UNION ALL SELECT 46, '  ', ' '
),
norm(fidx, ord, k, s) AS (
  SELECT fidx, ord, 0, body FROM items
  UNION ALL
  SELECT norm.fidx, norm.ord, norm.k + 1,
         replace(norm.s, (SELECT f FROM steps WHERE steps.k = norm.k + 1),
                         (SELECT t FROM steps WHERE steps.k = norm.k + 1))
  FROM norm WHERE norm.k < 46
),
lines(phase, fidx, ord, line) AS (
  SELECT DISTINCT 0, fidx, 0, 'DELETE FROM contents WHERE titleId = ' || tid || ';' FROM items
  UNION ALL
  SELECT 1, items.fidx, items.ord,
         'INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES ('
         || items.id || ', ' || items.tid || ', ' || items.ord || ', ' || quote(items.body) || ', '
         || items.cnt || ', ' || quote(items.source) || ', ' || quote(items.hokm) || ', '
         || quote(items.fadl) || ', ' || quote(trim(norm.s)) || ', '''', '''');'
  FROM items JOIN norm ON norm.fidx = items.fidx AND norm.ord = items.ord AND norm.k = 46
)
SELECT line FROM lines ORDER BY phase, fidx, ord;
