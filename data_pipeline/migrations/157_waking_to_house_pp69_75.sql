PRAGMA foreign_keys = ON;
BEGIN;

-- Pages 69-75 of the 10th revised edition (#172): waking, the toilet,
-- ablution, clothing, and entering and leaving the house, compared page by
-- page with the book.
-- * the book prints no ruling under any of these dhikr, so `hokm` is empty;
--   `source` keeps the heading printed above each dhikr, the bracketed
--   attribution where the book prints one («المسند» on p70, «مسلم» on p75) and
--   the page, then the footnotes after «حاشية:»; the narrations, gradings and
--   comments the app had written in `source` are not in these pages and go;
-- * bodies are set as the book prints them («باسم الله» with its alif,
--   commas where the book has them);
-- * p72: «يُسَمِّيه باسمه، ثُمَّ يقول:» is a passage of its own (count 0) and
--   carries the footnote the app had put under the supplication;
-- * p73: the footnote on «وأخلق» is completed as printed;
-- * p74: «ثُمَّ لْيُسَلِّمْ على أهله.» is an instruction (count 0), the
--   an-Nur verse the app quoted is not printed, and the line about the
--   siwak is a passage of its own;
-- * title 7 takes the comma the book prints in «أذكار دخول البيت، والخروج منه».

DELETE FROM contents WHERE titleId IN (4, 94, 95, 5, 6, 7);

-- 4: أذكار الاستيقاظ
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (57, 4, 1, 'الحمدُ للهِ الذي أحيانا بعد ما أماتنا، وإليه النشور', 1, 'ما يقول إذا استيقظ من نومه. (ص69)', '', '', 'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (58, 4, 2, 'الحمدُ لله الذي رَدَّ عَلَيَّ رُوحِي، وعافاني في جسدي، وأَذِنَ لي بذِكْرِه', 1, 'ما يقول إذا استيقظ من نومه. (ص69)', '', '', 'الحمد لله الذي رد علي روحي وعافاني في جسدي وأذن لي بذكره', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (59, 4, 3, 'أعوذُ بالله من الشيطانِ الرجيم
QuranText[(113:1:5),(114:1:6)]', 1, 'ما يقول إذا استيقظ من نومه. [«المسند» (١٧٢٩٦)]. (ص69–70)', '', '', 'أعوذ بالله من الشيطان الرجيم 1131511416', '', '');

-- 94: ما يقول إذا أراد دخول الخلاء
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (889, 94, 1, 'باسم الله', 1, 'ما يقول إذا أراد دخولَ الخلاء. (ص70)', '', '', 'باسم الله', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (890, 94, 2, 'اللهم إنِّي أعوذُ بِكَ من الخُبُثِ والخبائث', 1, 'ما يقول إذا أراد دخولَ الخلاء. (ص70)', '', '', 'اللهم إني أعوذ بك من الخبث والخبائث', '', '');

-- 95: ما يقول إذا خرج من الخلاء
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (891, 95, 1, 'غُفْرَانك', 1, 'ما يقول إذا خرج من الخلاء. (ص70)', '', '', 'غفرانك', '', '');

-- 5: أذكار الوضوء
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (60, 5, 1, 'باسم الله', 1, 'ما يقول على وضوئه. (ص71)', '', '', 'باسم الله', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (61, 5, 2, 'أشهدُ أن لا إله إلا الله وحدَه، لا شريكَ له، وأشهدُ أنَّ مُحَمَّدًا عبدُه ورسولُه', 1, 'ما يقول إذا فرغ من وضوئه. (ص71)', '', '', 'أشهد أن لا إله إلا الله وحده لا شريك له وأشهد أن محمدا عبده ورسوله', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (62, 5, 3, 'سبحانك اللهم وبحمدك، أشهدُ أن لا إله إلا أنتَ، أستغفِرُك، وأتوبُ إليك', 1, 'ما يقول إذا فرغ من وضوئه. (ص71)', '', '', 'سبحانك اللهم وبحمدك أشهد أن لا إله إلا أنت أستغفرك وأتوب إليك', '', '');

-- 6: أذكار اللباس
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (63, 6, 1, 'الحمدُ لله الذي كساني هذا، ورَزَقَنِيه من غير حَولٍ مني ولا قوة', 1, 'ما يقول إذا لَبِسَ ثَوبَه. (ص72)', '', '', 'الحمد لله الذي كساني هذا ورزقنيه من غير حول مني ولا قوة', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (1639, 6, 2, 'يُسَمِّيه باسمه، ثُمَّ يقول:', 0, 'ما يقول إذا لَبِسَ ثوبًا جديدًا أونعلًا أو شبهه. (ص72)

حاشية: «يسميه باسمه: يعني: فيقول مثلًا: اللهم أنت كسوتني هذه العمامة، أو هذا القميص، أو هذا الرداء، أو نحو ذلك، ثم يقول: أسألك خيرَه» إلخ.اهـ. من «نزل الأبرار» (ص٣٣٨).', '', '', 'يسميه باسمه ثم يقول', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (64, 6, 3, 'اللهم لك الحمدُ، أنت كَسَوْتَنِيهِ، أسألُكَ خيرَه، وخيرَ ما صُنِعَ له، وأعوذُ بكَ مِنْ شَرِّه، وشَرِّ ما صُنِعَ له', 1, 'ما يقول إذا لَبِسَ ثوبًا جديدًا أونعلًا أو شبهه. (ص72)', '', '', 'اللهم لك الحمد أنت كسوتنيه أسألك خيره وخير ما صنع له وأعوذ بك من شره وشر ما صنع له', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (65, 6, 4, 'الحمد لله الذي كساني هذا، وَرَزَقَنِيهِ من غيرِ حَوْلٍ مني ولا قوة', 1, 'ما يقول إذا لَبِسَ ثوبًا جديدًا أونعلًا أو شبهه. (ص72)', '', '', 'الحمد لله الذي كساني هذا ورزقنيه من غير حول مني ولا قوة', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (66, 6, 5, 'باسم الله', 1, 'ما يقول إذا خلع ثوبه لِغُسْلٍ أو نومٍ أو نحوهما. (ص73)', '', '', 'باسم الله', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (67, 6, 6, 'تُبْلِي، ويُخْلِفُ اللهُ تعالى', 1, 'ما يقول لصاحبه إذا رأى عليه ثوبًا جديدًا. (ص73)', '', '', 'تبلي ويخلف الله تعالى', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (68, 6, 7, 'أَبْلِ وأَخْلِقْ، ثُمَّ أَبْلِ وأخلق، ثم أبلِ وأخلِقْ', 1, 'ما يقول لصاحبه إذا رأى عليه ثوبًا جديدًا. (ص73)

حاشية: وأخلِق: تُطلِقُ العربُ ذلك، وتريد الدعاء بطول البقاء للمخاطَب بذلك، أي أنه تطول حياته حتى يبلى الثوب ويخلق. انظر: «فتح الباري» (١٠/ ٢٨٠).', '', '', 'أبل وأخلق ثم أبل وأخلق ثم أبل وأخلق', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (69, 6, 8, 'اِلْبَسْ جديدًا، وَعِشْ حميدًا، وَمُتْ شهيدًا، ويَرزقُكَ اللهُ قُرَّةَ عينٍ في الدنيا والآخرة', 1, 'ما يقول لصاحبه إذا رأى عليه ثوبًا جديدًا. (ص73)', '', '', 'البس جديدا وعش حميدا ومت شهيدا ويرزقك الله قرة عين في الدنيا والآخرة', '', '');
UPDATE titles SET name = 'أذكار دخول البيت، والخروج منه' WHERE id = 7;

-- 7: أذكار دخول البيت، والخروج منه
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (70, 7, 1, 'باسم اللهِ، توكَّلْتُ على اللهِ، لا حولَ ولا قوَّةَ إلَّا بالله', 1, 'ما يقول إذا خرجَ من بيته. (ص74)', '', '', 'باسم الله توكلت على الله لا حول ولا قوة إلا بالله', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (71, 7, 2, 'اللهم إنِّي أعوذُ بكَ أنْ أَضِلَّ أو أُضَلَّ، أو أَزِلَّ أو أُزَلَّ، أو أظلِمَ أو أُظْلَمَ، أو أَجْهَلَ أو يُجْهَلَ عَلَيَّ', 1, 'ما يقول إذا خرجَ من بيته. (ص74)', '', '', 'اللهم إني أعوذ بك أن أضل أو أضل أو أزل أو أزل أو أظلم أو أظلم أو أجهل أو يجهل علي', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (72, 7, 3, 'اللهم إني أسألُكَ خيرَ المَوْلَجِ، وخيرَ المَخْرَجِ، باسمِ اللهِ وَلَجْنا، وباسم اللهِ خَرَجْنا، وعلى اللهِ رَبِّنا توكَّلنا', 1, 'ما يقول إذا دخل بيته. (ص74)', '', '', 'اللهم إني أسألك خير المولج وخير المخرج باسم الله ولجنا وباسم الله خرجنا وعلى الله ربنا توكلنا', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (73, 7, 4, 'ثُمَّ لْيُسَلِّمْ على أهله.', 0, 'ما يقول إذا دخل بيته. (ص74)', '', '', 'ثم ليسلم على أهله', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (1640, 7, 5, 'وكان ﷺ إذا دَخَلَ بيته بدأ بالسِّواك.', 0, 'ما يقول إذا دخل بيته. (ص74)', '', '', 'وكان إذا دخل بيته بدأ بالسواك', '', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex, style) VALUES (74, 7, 6, 'اللهم إنِّي ظلمتُ نفسي ظُلْمًا كثيرًا، ولا يغفرُ الذنوبَ إلا أنت، فاغفِرْ لي مغفرةً من عندِكَ، وارحمني، إنَّك أنتَ الغفورُ الرحيم', 1, 'ما يدعو به في بيته. [مُسلم: ٢٧٠٥]. (ص75)

حاشية: وفي رواية: كبيرًا.', '', '', 'اللهم إني ظلمت نفسي ظلما كثيرا ولا يغفر الذنوب إلا أنت فاغفر لي مغفرة من عندك وارحمني إنك أنت الغفور الرحيم', '', '');

PRAGMA user_version = 157;
COMMIT;
