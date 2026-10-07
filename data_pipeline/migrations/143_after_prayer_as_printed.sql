PRAGMA foreign_keys = ON;
BEGIN;

-- «ما يقول بعد الصلاة» as pp68-71 print it:
-- * the tasbih (item 12) is one choice of six forms; each form is one card
--   as printed, counted for its total, the second on opening with «أو:»;
-- * the instructions «ويقول:»، «ثم يقول:»، «يعقدهن بأنامله» and the sub-
--   headings after Fajr, after Maghrib and after Witr are passages to read;
-- * item 1 reads «يكبر الله عز وجل», item 8 keeps «(أو: تبعث)» as printed,
--   and «سبحان الملك القدوس» is printed three times with its instruction.

DELETE FROM contents WHERE id IN (146, 147, 949, 950, 951, 953, 954, 955, 957, 958, 960, 961);
UPDATE contents SET "order" = -"order" WHERE titleId = 16;
UPDATE contents SET "order" = 1, body = 'يُكَبِّرُ اللهَ عزَّ وجلَّ', search = 'يكبر الله عز وجل' WHERE id = 946;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1195, 16, 2, 'ويقول:', 0, 'ما يقول بعد الصلاة. (ص68)', '', '', 'ويقول', '');
UPDATE contents SET "order" = 3 WHERE id = 134;
UPDATE contents SET "order" = 4 WHERE id = 135;
UPDATE contents SET "order" = 5 WHERE id = 136;
UPDATE contents SET "order" = 6 WHERE id = 137;
UPDATE contents SET "order" = 7 WHERE id = 138;
UPDATE contents SET "order" = 8 WHERE id = 139;
UPDATE contents SET "order" = 9, body = 'رَبِّ قِنِي عذابَكَ يومَ تجمعُ (أو: تبعثُ) عبادَكَ', search = 'رب قني عذابك يوم تجمع أو تبعث عبادك' WHERE id = 140;
UPDATE contents SET "order" = 10 WHERE id = 141;
UPDATE contents SET "order" = 11 WHERE id = 143;
UPDATE contents SET "order" = 12 WHERE id = 144;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1196, 16, 13, 'ثم يقول:', 0, 'ما يقول بعد الصلاة. (ص69)', '', '', 'ثم يقول', '');
UPDATE contents SET "order" = 14 WHERE id = 947;
UPDATE contents SET "order" = 15, body = 'أو: «سبحانَ اللهِ» (٣٣)، «الحمدُ للهِ» (٣٣)، «اللهُ أكبرُ» (٣٤)', search = 'أو سبحان الله الحمد لله الله أكبر', count = 100 WHERE id = 145;
UPDATE contents SET "order" = 16, body = 'أو: «سبحانَ اللهِ» (٣٣)، «الحمدُ للهِ» (٣٣)، «اللهُ أكبرُ» (٣٣)، ثم يقول: «لا إلهَ إلا اللهُ وحدَه لا شريكَ له، له المُلْكُ، وله الحمدُ، وهو على كلِّ شيءٍ قديرٌ»', search = 'أو سبحان الله الحمد لله الله أكبر ثم يقول لا إله إلا الله وحده لا شريك له له الملك وله الحمد وهو على كل شيء قدير', count = 100 WHERE id = 948;
UPDATE contents SET "order" = 17, body = 'أو: «سبحانَ اللهِ» (٢٥)، «الحمدُ للهِ» (٢٥)، «لا إلهَ إلا اللهُ» (٢٥)، «اللهُ أكبرُ» (٢٥)', search = 'أو سبحان الله الحمد لله لا إله إلا الله الله أكبر', count = 100 WHERE id = 952;
UPDATE contents SET "order" = 18, body = 'أو: «سبحانَ اللهِ» (١١)، «الحمدُ للهِ» (١١)، «اللهُ أكبرُ» (١١)', search = 'أو سبحان الله الحمد لله الله أكبر', count = 33 WHERE id = 956;
UPDATE contents SET "order" = 19, body = 'أو: «سبحانَ اللهِ» (١٠)، «الحمدُ للهِ» (١٠)، «اللهُ أكبرُ» (١٠)', search = 'أو سبحان الله الحمد لله الله أكبر', count = 30 WHERE id = 959;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1197, 16, 20, '- يَعْقِدُهُنَّ بأناملِه.', 0, 'ما يقول بعد الصلاة. (ص70)', '', '', 'يعقدهن بأنامله', '');
UPDATE contents SET "order" = 21 WHERE id = 148;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1198, 16, 22, 'ذكر الله تعالى عقب صلاة الصبح
(وهو أشرف أوقات الذكر في النهار)', 0, 'ذكر الله تعالى عقب صلاة الصبح. (ص70)', '', '', 'ذكر الله تعالى عقب صلاة الصبح وهو أشرف أوقات الذكر في النهار', '');
UPDATE contents SET "order" = 23 WHERE id = 149;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1199, 16, 24, 'ويقول ما تقدم في (ما يقول بعد الصلاة).', 0, 'ذكر الله تعالى عقب صلاة الصبح. (ص71)

حاشية: انظر (ص68).', '', '', 'ويقول ما تقدم في ما يقول بعد الصلاة', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1200, 16, 25, 'ما يقول بعد صلاة المغرب', 0, 'ما يقول بعد صلاة المغرب. (ص71)', '', '', 'ما يقول بعد صلاة المغرب', '');
UPDATE contents SET "order" = 26 WHERE id = 962;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1201, 16, 27, 'ويقول ما تقدم في (ما يقال بعد الصلاة).', 0, 'ما يقول بعد صلاة المغرب. (ص71)

حاشية: انظر (ص68).', '', '', 'ويقول ما تقدم في ما يقال بعد الصلاة', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1202, 16, 28, 'ما يقول بعد صلاة الوتر', 0, 'ما يقول بعد صلاة الوتر. (ص71)', '', '', 'ما يقول بعد صلاة الوتر', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1203, 16, 29, 'إذا سلَّم من الوتر قال:', 0, 'ما يقول بعد صلاة الوتر. (ص71)', '', '', 'إذا سلم من الوتر قال', '');
UPDATE contents SET "order" = 30, body = 'سبحانَ الملكِ القُدُّوسِ،
سبحانَ الملكِ القُدُّوسِ،
سبحانَ الملكِ القُدُّوسِ.
(هكذا ثلاثًا، ويمدُّ بها صوتَه، ويرفعُ في الثالثة)', search = 'سبحان الملك القدوس سبحان الملك القدوس سبحان الملك القدوس هكذا ثلاثا ويمد بها صوته ويرفع في الثالثة', count = 1 WHERE id = 151;
UPDATE contents SET "order" = 31 WHERE id = 152;

PRAGMA user_version = 143;
COMMIT;
