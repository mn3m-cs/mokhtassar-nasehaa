BEGIN;

-- quran.ar.uthmani.v2.db, UthmaniRepository.dbVersion 3: Hud 41 «مَجۡر۪ىٰهَا»
-- carries the imala sign as U+06EA, not U+065C (see 144_imala_sign.sql).

UPDATE arabic_text SET text = replace(text, char(0x065C), char(0x06EA)) WHERE sura = 11 AND ayah = 41;

COMMIT;
