PRAGMA foreign_keys = ON;
BEGIN;

-- Page-by-page comparison of pp116-129 of the 10th revised edition (#175).
--
-- «ما يقول بعد الصلاة» (title 16, pp116-121):
-- * the book prints no grade under these items, so hokm is emptied;
-- * item 3 repeats «أستغفر الله» twice, not three times;
-- * item 10, «اللهم لا تخزني يوم القيامة [المسند (١٨٠٥٦)]», is printed and
--   was missing (id 1205);
-- * item 8 reads «تجمع -أو: تبعث- عباد» with dashes;
-- * «ويقرأ آية الكرسي:» and «ويقرأ السور المعوذات:» are printed, the
--   latter quoting the first verse of each sura between ﴿ ﴾;
-- * «ويقول ما تقدم في: (ما يقول بعد الصلاة)» keeps its colon and wording;
-- * footnotes go to `source` after «حاشية:», page numbers are the 10th
--   edition's.
UPDATE contents SET hokm = '' WHERE titleId = 16;

UPDATE contents SET "order" = 33 + "order" WHERE titleId = 16;

UPDATE contents SET "order" = 1,
  source = 'ما يقول بعد الصلاة. (ص116)

حاشية: لِمَا رواه البخاري في «صحيحه» رقم (٨٤٢) بسنده إلى ابن عباس رضي الله عنهما، قال: «كنتُ أعرفُ انقضاء صلاة النبي صلى الله عليه وسلم بالتكبير». وانظر: «فتح الباري» (٣/ ٧٤-٧٦)، ورَوَى ابن أبي شيبة في «مصنفه» رقم (٣١١٨) (٢/ ١٨٤) أنَّ القاسمَ قال: «والله إن كان ابن الزبير ليصنعُ ذلك» أي: كان يُكَبِّرُ ثلاث تكبيرات -أو تهليلات- إذا سَلَّمَ الإمام.'
  WHERE id = 946;
UPDATE contents SET "order" = 2, source = 'ما يقول بعد الصلاة. (ص116)' WHERE id = 1195;
UPDATE contents SET "order" = 3, source = 'ما يقول بعد الصلاة. (ص116)' WHERE id = 134;
UPDATE contents SET "order" = 4, source = 'ما يقول بعد الصلاة. (ص116)',
  body = 'أستغفرُ اللهَ، أستغفرُ اللهَ، اللهمَّ أنتَ السلامُ، ومنكَ السلامُ، تباركتَ يا ذا الجلالِ والإكرامِ',
  search = 'أستغفر الله أستغفر الله اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام'
  WHERE id = 135;
UPDATE contents SET "order" = 5, source = 'ما يقول بعد الصلاة. (ص117)' WHERE id = 136;
UPDATE contents SET "order" = 6, source = 'ما يقول بعد الصلاة — آية الكرسي. (ص117)',
  body = 'ويقرأ آية الكُرْسِيّ:
QuranText[(2:255:255)]',
  search = 'ويقرأ آية الكرسي 2255255'
  WHERE id = 137;
UPDATE contents SET "order" = 7, source = 'ما يقول بعد الصلاة — سور المعوذات. (ص117)',
  body = 'ويقرأ السُّوَرَ المعوِّذاتِ: ﴿ قُلۡ هُوَ ٱللَّهُ أَحَدٌ ﴾، و﴿ قُلۡ أَعُوذُ بِرَبِّ ٱلۡفَلَقِ ﴾، و﴿ قُلۡ أَعُوذُ بِرَبِّ ٱلنَّاسِ ﴾.',
  search = 'ويقرأ السور المعوذات قل هو الله أحد وقل أعوذ برب الفلق وقل أعوذ برب الناس'
  WHERE id = 138;
UPDATE contents SET "order" = 8, source = 'ما يقول بعد الصلاة. (ص117)' WHERE id = 139;
UPDATE contents SET "order" = 9, source = 'ما يقول بعد الصلاة. (ص117)',
  body = 'رَبِّ قِنِي عذابَكَ يومَ تجمعُ -أو: تبعثُ- عبادَكَ',
  search = 'رب قني عذابك يوم تجمع -أو تبعث- عبادك'
  WHERE id = 140;
UPDATE contents SET "order" = 10, source = 'ما يقول بعد الصلاة. (ص117)' WHERE id = 141;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1205, 16, 11, 'اللهمَّ لا تُخزِني يومَ القيامةِ', 1, 'ما يقول بعد الصلاة. [المسند (١٨٠٥٦)]. (ص117)', '', '', 'اللهم لا تخزني يوم القيامة', '');
UPDATE contents SET "order" = 12, source = 'ما يقول بعد الصلاة. (ص118)' WHERE id = 143;
UPDATE contents SET "order" = 13, source = 'ما يقول بعد الصلاة. (ص118)' WHERE id = 144;
UPDATE contents SET "order" = 14, source = 'ما يقول بعد الصلاة. (ص118)' WHERE id = 1196;
UPDATE contents SET "order" = 15, source = 'ما يقول بعد الصلاة — الصيغة الأولى للتسبيح. (ص118)' WHERE id = 947;
UPDATE contents SET "order" = 16, source = 'ما يقول بعد الصلاة — الصيغة الثانية للتسبيح. (ص118)' WHERE id = 145;
UPDATE contents SET "order" = 17, source = 'ما يقول بعد الصلاة — الصيغة الثالثة للتسبيح. (ص118)' WHERE id = 948;
UPDATE contents SET "order" = 18, source = 'ما يقول بعد الصلاة — الصيغة الرابعة للتسبيح. (ص119)' WHERE id = 952;
UPDATE contents SET "order" = 19, source = 'ما يقول بعد الصلاة — الصيغة الخامسة للتسبيح. (ص119)' WHERE id = 956;
UPDATE contents SET "order" = 20, source = 'ما يقول بعد الصلاة — الصيغة السادسة للتسبيح. (ص119)' WHERE id = 959;
UPDATE contents SET "order" = 21, source = 'ما يقول بعد الصلاة. (ص119)' WHERE id = 1197;
UPDATE contents SET "order" = 22, source = 'ما يقول بعد الصلاة. (ص119)' WHERE id = 148;
UPDATE contents SET "order" = 23, source = 'ذكر الله تعالى عقب صلاة الصبح. (ص120)' WHERE id = 1198;
UPDATE contents SET "order" = 24, source = 'ذكر الله تعالى عقب صلاة الصبح. (ص120)' WHERE id = 149;
UPDATE contents SET "order" = 25,
  source = 'ذكر الله تعالى عقب صلاة الصبح. (ص120)

حاشية: انظر (ص116).',
  body = 'ويقول ما تقدَّمَ في: (ما يقول بعد الصلاة).',
  search = 'ويقول ما تقدم في ما يقول بعد الصلاة'
  WHERE id = 1199;
UPDATE contents SET "order" = 26, source = 'ما يقول بعد صلاة المغرب. (ص120)' WHERE id = 1200;
UPDATE contents SET "order" = 27, source = 'ما يقول بعد صلاة المغرب. (ص120)' WHERE id = 962;
UPDATE contents SET "order" = 28,
  source = 'ما يقول بعد صلاة المغرب. (ص120)

حاشية: انظر (ص116).',
  body = 'ويقول ما تقدَّمَ في: (ما يقول بعد الصلاة).',
  search = 'ويقول ما تقدم في ما يقول بعد الصلاة'
  WHERE id = 1201;
UPDATE contents SET "order" = 29, source = 'ما يقول بعد صلاة الوتر. (ص121)' WHERE id = 1202;
UPDATE contents SET "order" = 30, source = 'ما يقول بعد صلاة الوتر. (ص121)' WHERE id = 1203;
UPDATE contents SET "order" = 31, source = 'ما يقول بعد صلاة الوتر؛ يمد بها صوته ويرفع في الثالثة. (ص121)' WHERE id = 151;
UPDATE contents SET "order" = 32,
  source = 'ما يقول بعد صلاة الوتر. (ص121)

حاشية: وهذا يقال في آخر الوتر، قبل السلام أو بعده.'
  WHERE id = 152;

-- «كيفية التكبير في العيدين» (title 115, pp122-123): the Fitr paragraph ends
-- with «[البقرة: ١٨٥]» and «وقبل صلاة العيد…» is a paragraph of its own;
-- «وفي صفة التكبير: آثار موقوفة منها:» was missing; no grade is printed.
UPDATE contents SET hokm = '' WHERE titleId = 115;
UPDATE contents SET "order" = "order" + 2,
  source = 'صفة التكبير؛ آثار موقوفة. (ص123)'
  WHERE id BETWEEN 1025 AND 1029;
UPDATE contents SET
  body = substr(body, 1, instr(body, ' وقبل صلاة العيد') - 1) || ' [البقرة: ١٨٥].',
  search = substr(search, 1, instr(search, ' وقبل صلاة العيد') - 1) || ' البقرة ١٨٥',
  source = 'كيفية التكبير في العيدين. (ص122)'
  WHERE id = 1023;
UPDATE contents SET "order" = 3, source = 'كيفية التكبير في العيدين. (ص122)' WHERE id = 1024;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1206, 115, 2, 'وقبل صلاة العيد يخرج من بيته، فيكبر جهرًا حتى يأتي المصلى، ثم يكبر حتى يخرج الإمام.', 0, 'كيفية التكبير في العيدين. (ص122)', '', '', 'وقبل صلاة العيد يخرج من بيته فيكبر جهرا حتى يأتي المصلى ثم يكبر حتى يخرج الإمام', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1207, 115, 4, 'وفي صفة التكبير: آثارٌ موقوفةٌ منها:', 0, 'كيفية التكبير في العيدين. (ص123)', '', '', 'وفي صفة التكبير آثار موقوفة منها', '');

-- «تكبيرات صلاة العيد» (title 116, p124).
UPDATE contents SET source = 'تكبيرات صلاة العيد، وما يقول بينها. (ص124)' WHERE titleId = 116;

-- «التهنئة يوم العيد» (title 117, p124): the sentence before the greeting is
-- printed text, so it is a passage, not a `source`; no grade is printed.
UPDATE contents SET "order" = 2, hokm = '', source = 'التهنئة يوم العيد. (ص124)' WHERE id = 1032;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1208, 117, 1, 'عن جُبَيْرِ بنِ نُفَيْرٍ، قال: كان أصحابُ النبيِّ صلى الله عليه وسلم إذا الْتَقَوْا يومَ العيدِ يقولُ بعضُهم لبعضٍ:', 0, 'التهنئة يوم العيد. (ص124)', '', '', 'عن جبير بن نفير قال كان أصحاب النبي صلى الله عليه وسلم إذا التقوا يوم العيد يقول بعضهم لبعض', '');

-- «ما يفعل عند كسوف الشمس» (title 118, p125): the sermon paragraph was missing.
UPDATE contents SET source = 'ما يفعل عند كسوف الشمس. (ص125)' WHERE titleId = 118;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1209, 118, 3, 'ثم يخطب الإمام الناس، ويبدأ بحمد الله والثناء عليه سبحانه، ثم يعظ الناس، ويذكرهم بآيات الله عز وجل، ويحثهم على الدعاء والتكبير والصلاة والصدقة، ويحذرهم من أسباب غضب الله وعقابه.', 0, 'ما يفعل عند كسوف الشمس. (ص125)', '', '', 'ثم يخطب الإمام الناس ويبدأ بحمد الله والثناء عليه سبحانه ثم يعظ الناس ويذكرهم بآيات الله عز وجل ويحثهم على الدعاء والتكبير والصلاة والصدقة ويحذرهم من أسباب غضب الله وعقابه', '');

-- «ما يقول عند الاستسقاء» (title 119, pp125-127):
-- * the opening reads «يبدأ الإمام خطبته بالحمد، ويكثر من الاستغفار…» and the
--   verses of Nuh sit on a line of their own (the viewer drops any text on
--   the line of a QuranText);
-- * «ويبالغ في رفع يديه» and the colon after «بالأدعية التالية» were missing,
--   with footnotes 1 and 2;
-- * item 1 is one item as printed: the Fatiha verses, then «لا إله إلا الله،
--   يفعل ما يريد، اللهم أنت الله…» (ids 1037 and 1038 become 1037);
-- * item 2, «اللهم اسقنا» three times, was missing;
-- * footnotes 3 and 4 as printed.
UPDATE contents SET "order" = 1, source = 'ما يقول عند الاستسقاء. (ص125)',
  body = 'يبدأ الإمام خطبته بالحمد، ويكثر من الاستغفار حتى يكون أكثر كلامه، ويذكرهم بقوله تعالى على لسان نوح عليه السلام:
QuranText[(71:10:12)]',
  search = 'يبدأ الإمام خطبته بالحمد ويكثر من الاستغفار حتى يكون أكثر كلامه ويذكرهم بقوله تعالى على لسان نوح عليه السلام 711012'
  WHERE id = 1035;
UPDATE contents SET "order" = 2,
  source = 'ما يقول عند الاستسقاء. (ص126)

حاشية: انظر: دعاء الكرب والدعاء عند الأمور المهمة (ص١٤٢).

حاشية: ويجعل بطون كفيه مما يلي الأرض، وظهورها إلى السماء تفاؤلًا بقلب الحال، أو إشارة إلى نزول السحاب إلى الأرض.',
  body = 'ويكثر من دعاء الكرب، ويبالغ في رفع يديه، ويدعو الله عز وجل في تضرع وتذلل وافتقار ومسكنة بالأدعية التالية:',
  search = 'ويكثر من دعاء الكرب ويبالغ في رفع يديه ويدعو الله عز وجل في تضرع وتذلل وافتقار ومسكنة بالأدعية التالية'
  WHERE id = 1036;
DELETE FROM contents WHERE id = 1038;
UPDATE contents SET "order" = 3, source = 'ما يقول عند الاستسقاء. (ص126)',
  body = 'QuranText[(1:2:4)]
لَا إِلَهَ إِلَّا اللهُ، يَفْعَلُ مَا يُرِيدُ، اللَّهُمَّ أَنْتَ اللهُ، لَا إِلَهَ إِلَّا أَنْتَ الْغَنِيُّ، وَنَحْنُ الْفُقَرَاءُ، أَنْزِلْ عَلَيْنَا الْغَيْثَ، وَاجْعَلْ مَا أَنْزَلْتَ لَنَا قُوَّةً وَبَلَاغًا إِلَى حِينٍ.',
  search = '124 لا إله إلا الله يفعل ما يريد اللهم أنت الله لا إله إلا أنت الغني ونحن الفقراء أنزل علينا الغيث واجعل ما أنزلت لنا قوة وبلاغا إلى حين'
  WHERE id = 1037;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1210, 119, 4, 'اللَّهُمَّ اسْقِنَا، اللَّهُمَّ اسْقِنَا، اللَّهُمَّ اسْقِنَا.', 1, 'ما يقول عند الاستسقاء. (ص126)', '', '', 'اللهم اسقنا اللهم اسقنا اللهم اسقنا', '');
UPDATE contents SET "order" = 5,
  source = 'ما يقول عند الاستسقاء. (ص126)

حاشية: مَرِيئًا: محمود العاقبة.

حاشية: مَرِيعًا: ذا مَراعةٍ وخِصْبٍ، يُقال: أمرعتِ البلادُ: إذا أخصبت، وكَثُر فيها العُشْبُ.'
  WHERE id = 1039;
UPDATE contents SET "order" = 6, source = 'ما يقول عند الاستسقاء. (ص127)' WHERE id = 1040;
UPDATE contents SET "order" = 7, source = 'ما يقول عند الاستسقاء. (ص127)' WHERE id = 1041;

-- «صلاة التوبة» (title 121, pp127-129): the first footnote is printed in
-- full (it was a card of its own); Ibn al-Arabi's saying, «تنبيهان:» and the
-- two notices were missing; the verse sits on a line of its own.
UPDATE contents SET
  source = 'صلاة التوبة. (ص127)

حاشية: المراد بالاستغفار طلب المغفرة المقرون بالتوبة بالندامة والإقلاع والعزم على أن لا يعود إليه أبدًا، وأن يتدارك الحقوق إن كانت هناك.
والندم بالقلب على المعصية هو ركنُ التوبة الأعظم، لحديث: «الندم توبة»، وهذا يكون قبل صلاة التوبة وبعدها، أما التوبة باللسان بمناجاة العبد ربَّه بإعلان الندم على المعصية، وعزمه على عدم العود إليها، وطلب مغفرة الله عز وجل، فيكون بعد صلاة التوبة؛ لأنَّ النبي صلى الله عليه وسلم ذكر الصلاةَ أوّلًا، ثُمَّ عطف عليها الاستغفار الذي هو جزء من التوبة، بحرف «ثُمَّ» الذي يدلُّ على الترتيب، كما قال ابنُ مالكٍ: «وَثُمَّ للترتيبِ بانفصالِ».',
  body = replace(body, ' QuranText[', char(10) || 'QuranText[')
  WHERE id = 1044;
DELETE FROM contents WHERE id = 1045;
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1211, 121, 2, 'قال الإمام ابن العربي رحمه الله: «وفيه استيفاء وجوه الطاعة في التوبة، لأنه نَدِمَ فطهَّر باطنه، ثم توضأ، ثُمَّ صَلَّى، ثُمَّ استغفر».', 0, 'صلاة التوبة. (ص128)

حاشية: «عارضة الأحوذي» (٢/ ١٩٧).', '', '', 'قال الإمام ابن العربي رحمه الله وفيه استيفاء وجوه الطاعة في التوبة لأنه ندم فطهر باطنه ثم توضأ ثم صلى ثم استغفر', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1212, 121, 3, 'تنبيهان:', 0, 'صلاة التوبة. (ص128)', '', '', 'تنبيهان', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1213, 121, 4, 'الأول: يستحب أداء صلاة التوبة عند عزمه على التوبة من الذنب الذي اقترفه، والواجب المبادرة إلى التوبة بعد وقوع المعصية مباشرة، فإن أخرها قبلت ما دامت روحه لم تبلغ الحلقوم ولم يغرغر.', 0, 'صلاة التوبة. (ص128)', '', '', 'الأول يستحب أداء صلاة التوبة عند عزمه على التوبة من الذنب الذي اقترفه والواجب المبادرة إلى التوبة بعد وقوع المعصية مباشرة فإن أخرها قبلت ما دامت روحه لم تبلغ الحلقوم ولم يغرغر', '');
INSERT INTO contents (id, titleId, "order", body, count, source, hokm, fadl, search, sourceIndex) VALUES (1214, 121, 5, 'الثاني: تشرع صلاة التوبة في جميع الأوقات حتى أوقات النهي عن الصلاة؛ لأنها من ذوات الأسباب التي تشرع عند وجود سببها.', 0, 'صلاة التوبة. (ص129)

حاشية: «مجموع الفتاوى» (٢٣/ ٢١٥).', '', '', 'الثاني تشرع صلاة التوبة في جميع الأوقات حتى أوقات النهي عن الصلاة لأنها من ذوات الأسباب التي تشرع عند وجود سببها', '');

-- «صلاة التسبيح» (title 120) and «ما يقرأ في الليل» (title 3) are not in the
-- 10th edition: neither the index (pp445-464) nor pp116-129 prints them.
DELETE FROM contents WHERE titleId IN (120, 3);
DELETE FROM titles WHERE id IN (120, 3);
UPDATE titles SET "order" = 1 WHERE id = 121;

PRAGMA user_version = 146;
COMMIT;
