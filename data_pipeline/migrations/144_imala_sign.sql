PRAGMA foreign_keys = ON;
BEGIN;

-- Hud 41 «مَجۡر۪ىٰهَا» carries the imala sign as the Madinah Mushaf encodes it,
-- U+06EA ARABIC EMPTY CENTRE LOW STOP, not U+065C ARABIC VOWEL SIGN DOT BELOW,
-- which the Hafs font (UthmanicHafs_v2-1) draws as a dotted circle.

UPDATE contents SET body = replace(body, char(0x065C), char(0x06EA)) WHERE id = 304;

PRAGMA user_version = 144;
COMMIT;
