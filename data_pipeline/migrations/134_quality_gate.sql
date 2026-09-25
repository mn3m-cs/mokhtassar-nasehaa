PRAGMA foreign_keys = ON;
BEGIN;

-- Sections inherited from the original app whose texts are not on the cited pages.
DELETE FROM contents WHERE titleId IN (78, 79, 80);
DELETE FROM titles WHERE id IN (78, 79, 80);

-- Book chapter headings as categories.
INSERT INTO titles (id, `order`, name, freq, parentId, nodeType) VALUES (162, -162, 'الأذكار والدعوات للأمور العارضة', 'd', NULL, 'category');
INSERT INTO titles (id, `order`, name, freq, parentId, nodeType) VALUES (163, -163, 'الأذكار المتفرقة', 'd', NULL, 'category');
INSERT INTO titles (id, `order`, name, freq, parentId, nodeType) VALUES (161, -161, 'تمهيد الصلاة على النبي ﷺ', 'd', NULL, 'content');

-- Park every title that moves on a unique negative order first.
UPDATE titles SET `order` = -id WHERE parentId IS NULL OR parentId IN (113, 142) OR id IN (3, 114) OR id BETWEEN 32 AND 40 OR id IN (66, 67);

UPDATE titles SET parentId = NULL, `order` = 1 WHERE id = 99;
UPDATE titles SET parentId = NULL, `order` = 2 WHERE id = 100;
UPDATE titles SET parentId = NULL, `order` = 3 WHERE id = 4;
UPDATE titles SET parentId = NULL, `order` = 4 WHERE id = 94;
UPDATE titles SET parentId = NULL, `order` = 5 WHERE id = 95;
UPDATE titles SET parentId = NULL, `order` = 6 WHERE id = 5;
UPDATE titles SET parentId = NULL, `order` = 7 WHERE id = 6;
UPDATE titles SET parentId = NULL, `order` = 8 WHERE id = 7;
UPDATE titles SET parentId = NULL, `order` = 9 WHERE id = 108;
UPDATE titles SET parentId = NULL, `order` = 10 WHERE id = 9;
UPDATE titles SET parentId = NULL, `order` = 11 WHERE id = 114;
UPDATE titles SET parentId = NULL, `order` = 12 WHERE id = 96;
UPDATE titles SET parentId = NULL, `order` = 13 WHERE id = 122;
UPDATE titles SET parentId = NULL, `order` = 14 WHERE id = 162;
UPDATE titles SET parentId = NULL, `order` = 15 WHERE id = 123;
UPDATE titles SET parentId = NULL, `order` = 16 WHERE id = 124;
UPDATE titles SET parentId = NULL, `order` = 17 WHERE id = 48;
UPDATE titles SET parentId = NULL, `order` = 18 WHERE id = 128;
UPDATE titles SET parentId = NULL, `order` = 19 WHERE id = 133;
UPDATE titles SET parentId = NULL, `order` = 20 WHERE id = 60;
UPDATE titles SET parentId = NULL, `order` = 21 WHERE id = 61;
UPDATE titles SET parentId = NULL, `order` = 22 WHERE id = 62;
UPDATE titles SET parentId = NULL, `order` = 23 WHERE id = 63;
UPDATE titles SET parentId = NULL, `order` = 24 WHERE id = 64;
UPDATE titles SET parentId = NULL, `order` = 25 WHERE id = 65;
UPDATE titles SET parentId = NULL, `order` = 26 WHERE id = 163;
UPDATE titles SET parentId = NULL, `order` = 27 WHERE id = 68;
UPDATE titles SET parentId = NULL, `order` = 28 WHERE id = 140;
UPDATE titles SET parentId = NULL, `order` = 29 WHERE id = 158;

UPDATE titles SET parentId = 162, `order` = 1 WHERE id = 32;
UPDATE titles SET parentId = 162, `order` = 2 WHERE id = 33;
UPDATE titles SET parentId = 162, `order` = 3 WHERE id = 34;
UPDATE titles SET parentId = 162, `order` = 4 WHERE id = 35;
UPDATE titles SET parentId = 162, `order` = 5 WHERE id = 36;
UPDATE titles SET parentId = 162, `order` = 6 WHERE id = 37;
UPDATE titles SET parentId = 162, `order` = 7 WHERE id = 38;
UPDATE titles SET parentId = 162, `order` = 8 WHERE id = 39;
UPDATE titles SET parentId = 162, `order` = 9 WHERE id = 40;
UPDATE titles SET parentId = 163, `order` = 1 WHERE id = 66;
UPDATE titles SET parentId = 163, `order` = 2 WHERE id = 67;
UPDATE titles SET parentId = 113, `order` = 1 WHERE id = 120;
UPDATE titles SET parentId = 113, `order` = 2 WHERE id = 121;
UPDATE titles SET parentId = 113, `order` = 3 WHERE id = 3;
UPDATE titles SET parentId = 142, `order` = 1 WHERE id = 161;
UPDATE titles SET parentId = 142, `order` = 2 WHERE id = 151;
UPDATE titles SET parentId = 142, `order` = 3 WHERE id = 70;

-- The owner chose plain navigation names: drop the editorial suffixes.
UPDATE titles SET name = trim(replace(replace(name, '— تصنيف تنظيمي', ''), '— عنوان تنظيمي', '')) WHERE name LIKE '%تنظيمي%';

-- Verbatim introduction of «ثانيًا: الصلاة على النبي ﷺ» (pp. 174-176), replacing a paraphrase.
DELETE FROM contents WHERE id = 1089;
UPDATE contents SET `order` = `order` + 1000 WHERE titleId = 151;
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1089, 161, 1, 'ذكر الواحدي عن الأصمعي قال: سمعت المهدي على منبر البصرة يقول: «إن الله أمركم بأمر بدأ فيه بنفسه، وثنى بملائكته، فقال تشريفًا لنبيه وتكريمًا: ﴿إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا﴾ [الأحزاب: 56]، آثره بها من بين الرسل الكرام، وأتحفكم بها من بين الأنام، فقابلوا نعمته بالشكر، وأكثروا من الصلاة عليه في الذكر».', 0, 'ثانيًا: الصلاة على النبي ﷺ. (ص174)', '', '', 'ذكر الواحدي عن الأصمعي قال سمعت المهدي على منبر البصرة يقول «إن الله أمركم بأمر بدأ فيه بنفسه وثنى بملائكته فقال تشريفا لنبيه وتكريما ﴿إن الله وملائكته يصلون على النبي يا أيها الذين آمنوا صلوا عليه وسلموا تسليما﴾ الأحزاب 56 آثره بها من بين الرسل الكرام وأتحفكم بها من بين الأنام فقابلوا نعمته بالشكر وأكثروا من الصلاة عليه في الذكر»', '');
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1187, 161, 2, 'ليجتمع الثناء عليه ﷺ من أهل العالمين العلوي والسفلي.

قال أبو العالية: «صلاة الله على نبيه: ثناؤه عليه وتعظيمه، وصلاة الملائكة وغيرهم عليه: طلب ذلك له من الله، والمراد طلب الزيادة، لا طلب أصل الصلاة» ذكره الحافظ في «الفتح»، وردَّ القول المشهور أن صلاة الرب الرحمة، وفصَّل ذلك ابن القيم في «جلاء الأفهام» بما لا مزيد عليه، فراجعه، وانظر أيضًا: «النهاية» لابن الأثير (3/ 50).

ثم إن الخطباء سلكوا من بعد ذلك مسلكه امتثالًا لأمر الله تعالى، وأداءً لحقه ﷺ، فانتشرت من بعده على المنابر.', 0, 'حواشي أثر المهدي كما وردت في الكتاب. (ص174)', '', '', 'ليجتمع الثناء عليه من أهل العالمين العلوي والسفلي قال أبو العالية «صلاة الله على نبيه ثناؤه عليه وتعظيمه وصلاة الملائكة وغيرهم عليه طلب ذلك له من الله والمراد طلب الزيادة لا طلب أصل الصلاة» ذكره الحافظ في «الفتح» ورد القول المشهور أن صلاة الرب الرحمة وفصل ذلك ابن القيم في «جلاء الأفهام» بما لا مزيد عليه فراجعه وانظر أيضا «النهاية» لابن الأثير 3/ 50 ثم إن الخطباء سلكوا من بعد ذلك مسلكه امتثالا لأمر الله تعالى وأداء لحقه فانتشرت من بعده على المنابر', '');
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1188, 161, 3, 'وقال سهل بن عبد الله رحمه الله: «الصلاة على النبي ﷺ أفضل العبادات؛ لأن الله تعالى تولاها، هو وملائكته، ثم أمر بها المؤمنين، وسائر العبادات ليست كذلك».', 0, 'ثانيًا: الصلاة على النبي ﷺ. (ص174)', '', '', 'وقال سهل بن عبد الله رحمه الله «الصلاة على النبي أفضل العبادات لأن الله تعالى تولاها هو وملائكته ثم أمر بها المؤمنين وسائر العبادات ليست كذلك»', '');
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1189, 161, 4, 'وقال العز بن عبد السلام رحمه الله تعالى: «ليست صلاتنا عليه شفاعة منا له، فإن مثلنا لا يشفع لمثله ﷺ، ولكن الله تعالى أمرنا بالمكافأة لمن أحسن إلينا، وأنعم علينا، فإن عجزنا عنها كافأناه بالدعاء، فأرشدنا لما علم عجزنا عن مكافأة نبينا إلى الصلاة عليه لتكون صلاتنا عليه مكافأة بإحسانه إلينا، وإفضاله علينا، إذ لا إحسان أفضل من إحسانه ﷺ» اهـ.', 0, 'ثانيًا: الصلاة على النبي ﷺ. (ص175)', '', '', 'وقال العز بن عبد السلام رحمه الله تعالى «ليست صلاتنا عليه شفاعة منا له فإن مثلنا لا يشفع لمثله ولكن الله تعالى أمرنا بالمكافأة لمن أحسن إلينا وأنعم علينا فإن عجزنا عنها كافأناه بالدعاء فأرشدنا لما علم عجزنا عن مكافأة نبينا إلى الصلاة عليه لتكون صلاتنا عليه مكافأة بإحسانه إلينا وإفضاله علينا إذ لا إحسان أفضل من إحسانه » اه', '');
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1190, 161, 5, 'وقال ابن قيم الجوزية رحمه الله تعالى: «أمر الله تعالى بالصلاة عليه ﷺ عقب إخباره بأنه وملائكته يصلون عليه، والمعنى: أنه إذا كان الله وملائكته يصلون على رسوله ﷺ فصلوا أنتم أيضًا عليه، فأنتم أحق بأن تصلوا عليه وتسلموا تسليمًا، لما نالكم ببركة رسالته، ويمن سفارته من خير شرف الدنيا والآخرة».', 0, 'ثانيًا: الصلاة على النبي ﷺ. (ص175)', '', '', 'وقال ابن قيم الجوزية رحمه الله تعالى «أمر الله تعالى بالصلاة عليه عقب إخباره بأنه وملائكته يصلون عليه والمعنى أنه إذا كان الله وملائكته يصلون على رسوله فصلوا أنتم أيضا عليه فأنتم أحق بأن تصلوا عليه وتسلموا تسليما لما نالكم ببركة رسالته ويمن سفارته من خير شرف الدنيا والآخرة»', '');
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1191, 161, 6, 'ثم قال رحمه الله: «.. والصلاة المأمور بها -في قوله تعالى: ﴿صَلُّوا عَلَيْهِ﴾- هي الطلب من الله عز وجل ما أخبر به عن صلاته وصلاة ملائكته، وهي: ثناء عليه، وإظهار لفضله وشرفه، وإرادة تكريمه وتقريبه، فهي تتضمن الخبر والطلب».', 0, 'ثانيًا: الصلاة على النبي ﷺ. (ص175)؛ «جلاء الأفهام» (ص168، 169).', '', '', 'ثم قال رحمه الله « والصلاة المأمور بها -في قوله تعالى ﴿صلوا عليه﴾- هي الطلب من الله عز وجل ما أخبر به عن صلاته وصلاة ملائكته وهي ثناء عليه وإظهار لفضله وشرفه وإرادة تكريمه وتقريبه فهي تتضمن الخبر والطلب»', '');
INSERT INTO contents (id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex) VALUES (1192, 151, 1, 'والأحاديث في فضلها والحث عليها أكثر من أن تحصر، ولكن نشير إلى أحرف من ذلك تنبيهًا على ما سواها، وتبركًا بذكرها:', 0, 'فضل الصلاة على النبي ﷺ. (ص176)', '', '', 'والأحاديث في فضلها والحث عليها أكثر من أن تحصر ولكن نشير إلى أحرف من ذلك تنبيها على ما سواها وتبركا بذكرها', '');
UPDATE contents SET `order` = `order` - 1000 WHERE titleId = 151 AND `order` > 1000;

PRAGMA user_version = 134;
COMMIT;
