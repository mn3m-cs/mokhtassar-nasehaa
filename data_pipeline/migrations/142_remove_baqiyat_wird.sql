PRAGMA foreign_keys = ON;
BEGIN;

-- «ورد الباقيات الصالحات» is not a heading of the book: its three records
-- were combinations of «سبحان الله، والحمد لله، ولا إله إلا الله، والله
-- أكبر» taken from inside the hadiths on p191. Removed by the owner's
-- decision, as the «صيغ» sections were (#119).
DELETE FROM contents WHERE titleId = 73;
DELETE FROM titles WHERE id = 73;

PRAGMA user_version = 142;
COMMIT;
