PRAGMA foreign_keys = ON;
BEGIN;

-- «صيغ الاستغفار من القرآن/من السنة»، «صيغ التسبيح/الحمد/التكبير» are not
-- headings of the book: its table of contents (pp237-238) has «الاستغفار:
-- فضله وبعض الصيغ المأثورة فيه» (p188) and «التسبيح والتحميد والتكبير…»
-- (p190), and pages 188-195 are hadiths on these virtues with no list of
-- forms. The sections were compiled by the original app; their Quranic
-- forms are not in the book. Removed by the owner's decision, as 78-80 were.
DELETE FROM contents WHERE titleId IN (71, 72, 74, 75, 76);
DELETE FROM titles WHERE id IN (71, 72, 74, 75, 76);

PRAGMA user_version = 141;
COMMIT;
