PRAGMA foreign_keys = ON;
BEGIN;

-- «سبحان الله وبحمده … أو: سبحان الله العظيم وبحمده» is one choice counted
-- a hundred times (p14, p19), not two azkar: one card, both sources.
UPDATE contents SET
  body = body || char(10) || (SELECT body FROM contents WHERE id = 22),
  source = source || char(10) || char(10) || (SELECT source FROM contents WHERE id = 22),
  search = search || ' ' || (SELECT search FROM contents WHERE id = 22)
WHERE id = 21;
DELETE FROM contents WHERE id = 22;
UPDATE contents SET "order" = "order" - 1 WHERE titleId = 1 AND "order" > 22;

UPDATE contents SET
  body = body || char(10) || (SELECT body FROM contents WHERE id = 50),
  source = source || char(10) || char(10) || (SELECT source FROM contents WHERE id = 50),
  search = search || ' ' || (SELECT search FROM contents WHERE id = 50)
WHERE id = 49;
DELETE FROM contents WHERE id = 50;
UPDATE contents SET "order" = "order" - 1 WHERE titleId = 2 AND "order" > 21;

-- At-Tawbah 129 as the book quotes it, from «حسبي الله» (p13, p19, p152),
-- cut word for word from the Mushaf text so the Uthmani spelling holds.
UPDATE contents SET
  body = '﴿ حَسۡبِيَ ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَۖ عَلَيۡهِ تَوَكَّلۡتُۖ وَهُوَ رَبُّ ٱلۡعَرۡشِ ٱلۡعَظِيمِ ﴾',
  search = 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم'
WHERE id IN (18, 46, 414);

-- «قرآني» was a label of the original app, not of the book, and it marked
-- even azkar that are not Quran.
UPDATE contents SET hokm = '' WHERE hokm = 'قرآني';

PRAGMA user_version = 139;
COMMIT;
