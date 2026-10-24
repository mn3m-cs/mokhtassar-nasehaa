import 'dart:io';

import 'package:alazkar/src/core/helpers/db_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The sections as they stood before the navigation became the book's index
/// (#220, dbVersion 167). Most checks below were written one old section at a
/// time; they read `former_contents`, which gives every row the id of its old
/// section as `titleId` and its place among that section's rows as `order`.
///
/// Each old section that was split or merged is listed with the parts that now
/// hold its rows, in book order: a section, or a section with the first and
/// last place of the rows that came from the old one. Every other section
/// holds the rows it held before.
final Map<int, List<(int, int?, int?)>> _formerSections = {
  1: [(197, null, null), (198, 1, 1), (1, null, null)],
  2: [(198, 2, 2), (2, null, null)],
  5: _whole([5, 199]),
  6: _whole([6, 200, 201, 202]),
  7: _whole([7, 203, 204]),
  9: _whole([9, 206, 207, 208, 209]),
  10: _whole([10, 210, 211]),
  11: _whole([11, 212]),
  13: _whole([13, 213]),
  14: _whole([14, 214]),
  16: _whole([16, 215, 216, 217]),
  41: _whole([41, 218, 219, 220]),
  45: _whole([45, 221, 222, 223, 224, 225, 226]),
  46: _whole([46, 227, 228, 229, 230, 231]),
  48: _whole([48, 232, 233, 234, 235]),
  139: [(49, 1, 1)],
  49: [
    (49, 2, null),
    ..._whole([for (var id = 236; id <= 245; id++) id])
  ],
  50: _whole([50, 246, 247, 248]),
  52: _whole([52, 249]),
  54: _whole([54, 250, 251, 252]),
  55: _whole([55, 253]),
  56: _whole([56, 254, 255]),
  60: _whole([60, 256, 257, 258, 259, 260, 261]),
  61: _whole([61, 262, 263, 264, 265, 266]),
  63: _whole([63, 267, 268, 269]),
  65: _whole([65, 270, 271, 272, 273, 274, 275]),
  66: _whole([66, for (var id = 290; id <= 300; id++) id]),
  67: _whole([67, for (var id = 301; id <= 330; id++) id]),
  68: _whole([68, 331]),
  176: [(74, 1, 13)],
  74: [
    (74, 14, null),
    ..._whole([282, 283])
  ],
  75: _whole([75, 284]),
  147: [
    ..._whole([147, 192, 193, 194, 195, 196]),
    (148, 1, 2)
  ],
  148: [(148, 3, null), (149, 1, 1)],
  149: [(149, 2, null)],
  161: [(151, 1, 7)],
  151: [
    (151, 8, null),
    ..._whole([280, 281])
  ],
  156: [(156, 1, 5)],
  157: [(156, 6, null)],
  165: _whole([165, 276, 277, 278, 279]),
  168: _whole([168, 205]),
  172: _whole([172, 285]),
  179: _whole([179, 288, 289]),
  187: [(188, 1, 11)],
  188: [(188, 12, null)],
  190: _whole([190, 286, 287]),
};

List<(int, int?, int?)> _whole(List<int> ids) =>
    [for (final id in ids) (id, null, null)];

/// Creates the `former_contents` view described at [_formerSections]. The
/// bundled database opens read-only, so the parts are a `VALUES` list in the
/// view itself.
Future<void> _createFormerContents(Database database) async {
  final parts = [
    for (final MapEntry(key: formerId, value: parts) in _formerSections.entries)
      for (final (part, (titleId, first, last)) in parts.indexed)
        '($formerId, $part, $titleId, ${first ?? 1}, ${last ?? 1000000})',
  ].join(', ');
  await database.execute('''
    CREATE TEMP VIEW IF NOT EXISTS former_contents AS
    WITH former_parts(formerId, part, titleId, first, last) AS (
      VALUES $parts
    )
    SELECT contents.id, former_parts.formerId AS titleId,
           ROW_NUMBER() OVER (
             PARTITION BY former_parts.formerId
             ORDER BY former_parts.part, contents."order"
           ) AS "order",
           contents.body, contents.count, contents.source, contents.hokm,
           contents.fadl, contents.search, contents.sourceIndex, contents.style
    FROM contents
    JOIN former_parts ON former_parts.titleId = contents.titleId
     AND contents."order" BETWEEN former_parts.first AND former_parts.last
    UNION ALL
    SELECT id, titleId, "order", body, count, source, hokm, fadl, search,
           sourceIndex, style
    FROM contents
    WHERE titleId NOT IN (SELECT titleId FROM former_parts)
  ''');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled azkar database satisfies content invariants', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final foreignKeyViolations =
        await database.rawQuery('PRAGMA foreign_key_check');
    final titleCount = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM titles
    ''');
    final hierarchyColumns = await database.rawQuery('''
      SELECT name
      FROM pragma_table_info('titles')
      WHERE name IN ('parentId', 'nodeType')
      ORDER BY name
    ''');
    final invalidHierarchyNodes = await database.rawQuery('''
      SELECT id
      FROM titles
      WHERE nodeType NOT IN ('category', 'content')
         OR (nodeType = 'category' AND EXISTS (
           SELECT 1 FROM former_contents WHERE former_contents.titleId = titles.id
         ))
         OR (nodeType = 'content' AND EXISTS (
           SELECT 1 FROM titles AS children WHERE children.parentId = titles.id
         ))
    ''');
    final duplicateSiblingOrder = await database.rawQuery('''
      SELECT parentId, "order"
      FROM titles
      WHERE parentId IS NOT NULL
      GROUP BY parentId, "order"
      HAVING COUNT(*) > 1
    ''');
    final duplicateRootOrder = await database.rawQuery('''
      SELECT "order"
      FROM titles
      WHERE parentId IS NULL
      GROUP BY "order"
      HAVING COUNT(*) > 1
    ''');
    final wirdCounts = await database.rawQuery('''
      SELECT COUNT(former_contents.id) AS count
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.parentId = 191
      GROUP BY titles.id
      ORDER BY titles."order"
    ''');
    final eveningSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 2
    ''');
    final morningSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 1
    ''');
    final nightSection = await database.rawQuery('''
      SELECT
        titles.name,
        COUNT(former_contents.id) AS count,
        MIN(former_contents."order") AS first,
        MAX(former_contents."order") AS last
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id = 3
      GROUP BY titles.id
    ''');
    final unprintedSections = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles WHERE id = 120) AS titles,
        (SELECT COUNT(*) FROM titles
         WHERE name IN ('ما يُقرأ في الليل', 'صلاة التسبيح')) AS named,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 120) AS contents
    ''');
    final khalaSections = await database.rawQuery('''
      SELECT titles."order", titles.name, COUNT(former_contents.id) AS count
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id IN (94, 95)
      GROUP BY titles.id
      ORDER BY titles."order"
    ''');
    final mosqueSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 8
    ''');
    final adhanListenerSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 9
    ''');
    final duaAlistiftahSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 10
    ''');
    final rukuAndRisingSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 11
    ''');
    final sujudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM(search LIKE '%واجعل من فوقي نورا%واجعل خلفي نورا%') AS complete_light_dua
      FROM former_contents
      WHERE titleId = 12
    ''');
    final betweenProstrationsSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM(search = '٢- اللهم اغفر لي وارحمني واجبرني وارفعني واهدني وعافني وارزقني') AS correct_between_dua,
        SUM(search LIKE '%فتبارك%') AS unprinted_tilawa_ending,
        SUM(search LIKE '٢- اللهم اكتب لي بها عندك أجرا وضع عني بها وزرا%') AS ordered_tilawa_dua
      FROM former_contents
      WHERE titleId = 13
    ''');
    final prayerSectionOrder = await database.rawQuery('''
      SELECT id, "order", name
      FROM titles
      WHERE id IN (13, 14, 15, 16, 17)
      ORDER BY CASE id
        WHEN 13 THEN 1 WHEN 17 THEN 2 WHEN 14 THEN 3
        WHEN 15 THEN 4 WHEN 16 THEN 5 END
    ''');
    final qunutSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM(search LIKE 'اللهم عذب الكفرة الذين يصدون%ويقاتلون أولياءك%إله الحق') AS combat_dua,
        SUM(search LIKE 'اللهم إنا نستعينك%اللهم إياك نعبد%عذابك الجد بالكفار ملحق' AND search NOT LIKE '%قاتل%') AS closing_dua,
        SUM(search LIKE 'اللهم اغفر للمؤمنين والمؤمنات%واجعلنا منهم') AS third_paragraph,
        SUM(search LIKE 'ويشرع القنوت في الصلوات الخمس للنازلة%' AND count = 0) AS calamity_guidance
      FROM former_contents
      WHERE titleId = 17
    ''');
    final tashahhudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 7 AND search LIKE '٥- التحيات لله الزاكيات لله%') AS fifth_tashahhud,
        SUM("order" = 9 AND search LIKE '١- اللهم صل على محمد وعلى آل محمد%') AS first_salawat,
        SUM("order" = 15 AND search LIKE '٧- اللهم صل على محمد وعلى آل محمد وبارك%') AS seventh_salawat,
        SUM("order" = 4 AND count = 0 AND body = 'وفي روايةٍ: «عبدُهُ ورسولُه».') AS second_tashahhud_variant,
        SUM(count = 0) AS passages
      FROM former_contents
      WHERE titleId = 14
    ''');
    final postTashahhudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 13 AND search LIKE '١١- أحسن الكلام كلام الله وأحسن الهدي هدي محمد%') AS prophetic_guidance,
        SUM("order" = 15 AND search LIKE '١٢- اللهم اغفر لي ما قدمت%') AS closing_dua,
        SUM(count = 0) AS passages
      FROM former_contents
      WHERE titleId = 15
    ''');
    final afterPrayerSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND search = '١- يكبر الله عز وجل' AND count = 1) AS opening_takbir,
        SUM("order" = 15 AND search = '١٣- سبحان الله والحمد لله والله أكبر ٣٣ مرة' AND count = 33) AS combined_tasbih,
        SUM("order" BETWEEN 16 AND 20 AND body LIKE 'أو: %') AS tasbih_alternatives,
        SUM("order" = 18 AND count = 100 AND body LIKE '%(٢٥)%') AS fourth_formula,
        SUM("order" = 21 AND count = 0) AS fingers_note,
        SUM("order" = 24 AND count = 10 AND source LIKE '%صلاة الصبح%') AS morning_dhikr,
        SUM("order" = 27 AND count = 10 AND source LIKE '%صلاة المغرب%') AS sunset_dhikr,
        SUM("order" = 31 AND search LIKE 'سبحان الملك القدوس سبحان الملك القدوس سبحان الملك القدوس%') AS witr_dhikr,
        SUM(count = 0) AS passages,
        SUM("order" = 4 AND search LIKE '٣- أستغفر الله أستغفر الله اللهم%') AS two_istighfar,
        SUM("order" = 11 AND count = 1 AND hokm = ''
            AND search = '١٠- اللهم لا تخزني يوم القيامة'
            AND source LIKE '%المسند (١٨٠٥٦)%') AS printed_dua,
        SUM("order" = 9 AND body LIKE '%-أو: %-%') AS dashed_alternative,
        SUM("order" = 6 AND body LIKE '٥- ويقرأ آية الكُرْسِيّ:%QuranText[(2:255:255)]') AS ayat_alkursi,
        SUM("order" = 7 AND body LIKE '٦- ويقرأ السُّوَرَ المعوِّذاتِ:%') AS mu_awwidhat,
        SUM("order" IN (25, 28) AND body LIKE 'ويقول ما تقدَّمَ في: (%'
            AND source LIKE '%حاشية: انظر (ص116).') AS earlier_pointer,
        SUM(hokm != '') AS graded,
        SUM(source LIKE '%(ص6_)%' OR source LIKE '%(ص7_)%') AS old_edition_pages
      FROM former_contents
      WHERE titleId = 16
    ''');
    final sleepSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 2 AND count = 3
            AND body LIKE '٢- (يجمع كَفَّيْهِ%﴿ قُلۡ هُوَ ٱللَّهُ أَحَدٌ ﴾، والمعوِّذتين%'
            AND body NOT LIKE '%QuranText%') AS printed_mu_awwidhatayn,
        SUM(count = 0) AS lead_ins,
        SUM("order" = 11 AND search LIKE '%لا إله إلا أنت رب كل شيء%'
            AND search NOT LIKE '%أشهد%') AS printed_tahlil,
        SUM("order" = 12 AND search LIKE '%والفرقان%' AND search NOT LIKE '%والقرآن%') AS printed_furqan,
        SUM("order" = 14 AND search LIKE '١٣- باسم الله وضعت جنبي%وثقل ميزاني%') AS printed_mizan,
        SUM("order" BETWEEN 17 AND 25) AS tasbih_rows,
        SUM("order" IN (20, 23) AND body = 'أو: اللهُ أكبرُ [٣٣ مرة]') AS tasbih_alternatives,
        SUM("order" = 17 AND count = 34) AS first_takbir,
        SUM("order" = 24 AND count = 34) AS third_tasbih,
        SUM("order" = 26 AND source LIKE '%[موقوفٌ على عائشة رضي الله عنها]%') AS stopped_report,
        SUM("order" = 27 AND body LIKE '١٧- يقرأ سورة:%QuranText[(109:1:6)]%حتى يخْتِمَها.') AS kafirun,
        SUM(hokm != '') AS graded,
        SUM(source LIKE '%(ص7_)%' OR source LIKE '%(ص8_)%') AS old_edition_pages
      FROM former_contents
      WHERE titleId = 18
    ''');
    final visionSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM(body IN ('الحمدُ للهِ', 'أعوذُ باللهِ من شرِّها',
                     'أعوذُ باللهِ من الشيطانِ الرجيمِ')) AS app_wording,
        SUM("order" = 4 AND count = 0 AND search = '١- فليستعذ بالله من شره') AS seek_refuge,
        SUM("order" = 5 AND count = 3) AS left_breathing,
        SUM("order" = 6 AND count = 3
            AND search = '٣- ويتعوذ بالله من الشيطان الرجيم ثلاثا') AS satan_refuge,
        SUM(count = 0) AS prose_rows,
        SUM(hokm != '') AS graded
      FROM former_contents
      WHERE titleId = 30
    ''');
    final nightAwakeningSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND count = 0
            AND body LIKE 'قال رسول الله ﷺ: «من تَعارَّ%قُبِلت صلاتُه».'
            AND source LIKE '%[الحج: ٢٤]».اهـ.') AS taarra_hadith,
        SUM("order" = 3 AND search LIKE '%وما بينهما العزيز الغفار') AS tadawwur_dhikr,
        SUM("order" = 4 AND body LIKE '%مَن آوَى إلى فِراشِهِ طاهِرًا%') AS pure_sleeper,
        SUM("order" = 6 AND search LIKE 'باسمك اللهم وضعت جنبي%') AS return_to_bed,
        SUM(hokm != '') AS graded
      FROM former_contents
      WHERE titleId = 31
    ''');
    // p139 prints its own heading (index p450); p130's «من آداب النوم» is a footnote.
    final nightExitSection = await database.rawQuery('''
      SELECT
        titles.name,
        titles.parentId,
        titles."order",
        COUNT(former_contents.id) AS count,
        SUM(former_contents."order" = 1 AND former_contents.search LIKE '%3190200') AS al_imran_ending,
        SUM(former_contents.count = 0 AND former_contents.body LIKE 'وقال ﷺ: «%') AS hadiths,
        (SELECT COUNT(*) FROM titles WHERE id = 125) AS sleep_etiquette_titles,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 125) AS sleep_etiquette_rows
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id = 170
    ''');
    final istikharaSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId = 32
        AND search LIKE 'اللهم إني أستخيرك بعلمك%ثم رضني به'
        AND source LIKE '%ص140–141%'
    ''');
    final distressSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 10 AND search LIKE '%ابن أمتك في قبضتك ناصيتي بيدك%') AS complete_distress_dua
      FROM former_contents
      WHERE titleId = 33
    ''');
    final fearSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND search = '١- ﴿ رب نجني من ٱلۡقوۡم ٱلظلمين ﴾') AS qasas_dua
      FROM former_contents
      WHERE titleId = 34
    ''');
    final satanSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 4 AND count = 3) AS repeated_refuge,
        SUM("order" = 5 AND count = 3) AS repeated_curse
      FROM former_contents
      WHERE titleId = 35
    ''');
    final situationalSections = await database.rawQuery('''
      SELECT titles.id, titles.name, COUNT(former_contents.id) AS count
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id BETWEEN 36 AND 40
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final illnessAndDeathSections = await database.rawQuery('''
      SELECT titles.id, titles.name, COUNT(former_contents.id) AS count,
             MIN(former_contents."order") AS first, MAX(former_contents."order") AS last
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id BETWEEN 41 AND 47
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final illnessAndDeathRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 42 AND search LIKE 'اللهم أحيني ما كانت الحياة خيرا لي%') AS no_death_wish,
        SUM(titleId = 42 AND search LIKE 'اللهم ارزقني شهادة في سبيلك%') AS medina_death_dua,
        SUM(titleId = 43 AND search = '٥- اللهم اشف «فلانا» ثلاث مرات' AND count = 3) AS named_patient_dua,
        SUM(titleId = 44 AND search LIKE '٢- يقرأ بفاتحة الكتاب%') AS fatiha_ruqya,
        SUM(titleId = 46 AND search = '١- اللهم اجعله لنا سلفا وفرطا وأجرا') AS child_funeral_dua,
        SUM(titleId = 47) AS misplaced_child_dua,
        SUM(titleId = 46 AND source LIKE 'ما يقول زائرُ القبور. %' AND search LIKE '%السلام%') AS grave_visit_forms
      FROM former_contents
      WHERE titleId BETWEEN 41 AND 47
    ''');
    final fastingTravelAndPilgrimageSections = await database.rawQuery('''
      SELECT titles.id, COUNT(former_contents.id) AS count,
             MIN(former_contents."order") AS first, MAX(former_contents."order") AS last
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id BETWEEN 48 AND 60 OR titles.id = 164
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final fastingTravelAndPilgrimageRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 48 AND search LIKE '%لك صمت%') AS app_only_iftar_dua,
        SUM(titleId = 48 AND search = 'ذهب الظمأ وابتلت العروق وثبت الأجر إن شاء الله تعالى') AS iftar_dua_as_printed,
        SUM(titleId = 48 AND count = 0 AND body IN (
          'ما يقول إذا رأى الهلال', 'ما يقول إذا أفطر على الماء',
          'ما يقول إذا صادف ليلة القدر')) AS fasting_headings,
        SUM(titleId = 50 AND search = 'لبيك اللهم بعمرة') AS umra_intention,
        SUM(titleId = 50 AND search LIKE 'أو لبيك اللهم بحجة وعمرة%') AS qiran_intention,
        SUM(titleId = 50 AND search = 'أو لبيك ذا المعارج لبيك ذا الفواضل') AS talbiya_variant,
        SUM(titleId = 50 AND search = 'اللهم بعمرة') AS umra_without_talbiya,
        SUM(titleId = 164 AND search LIKE 'الله أكبر الله أكبر لا إله إلا الله وحده%هزم الأحزاب وحده' AND count = 3) AS safa_dhikr_two_takbirs,
        SUM(titleId = 164 AND search LIKE 'الله أكبر الله أكبر الله أكبر%') AS safa_dhikr_three_takbirs,
        SUM(titleId = 164 AND body = 'QuranText[(2:158:158)]') AS safa_verse,
        SUM(titleId IN (48, 50, 51, 52, 53, 54, 55, 56, 59, 136, 164)
            AND (hokm != '' OR fadl != '')) AS rulings_the_book_does_not_print,
        SUM(titleId = 52 AND search LIKE 'وليس للطواف ذكر خاص%') AS tawaf_prose,
        SUM(titleId = 54 AND search LIKE 'ويظل واقفا في عرفات%') AS arafah_prose,
        SUM(titleId = 55 AND body = 'ما يقول عند ذبح الأضحية') AS sacrifice_heading,
        SUM(titleId = 56 AND search = 'السلام عليك يا أبا بكر') AS visit_abu_bakr,
        SUM(titleId = 59 AND count = 1) AS baqi_forms,
        SUM(titleId = 60 AND body IN ('QuranText[(17:81:81)]', 'QuranText[(34:49:49)]')) AS misplaced_munkar_verses
      FROM former_contents
      WHERE titleId BETWEEN 48 AND 60 OR titleId IN (136, 164)
    ''');
    final removedPilgrimageSections = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles WHERE id IN (57, 58, 134, 135, 137, 138)) AS titles,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId IN (57, 58, 134, 135, 137, 138)) AS contents
    ''');
    final foodMarriageAndMajlisSections = await database.rawQuery('''
      SELECT titles.id, COUNT(former_contents.id) AS count,
             MIN(former_contents."order") AS first, MAX(former_contents."order") AS last
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id IN (61, 62, 63, 64, 65, 68)
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final foodMarriageAndMajlisRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 61 AND search = 'اللهم إني أسألك من فضلك ورحمتك فإنه لا يملكها إلا أنت') AS guest_dua,
        SUM(titleId = 62 AND search = 'يرحمنا الله وإياكم ويغفر لنا ولكم') AS ibn_umar_reply,
        SUM(titleId = 63 AND search LIKE 'اللهم إني أسألك من خيرها%') AS wife_dua,
        SUM(titleId = 64 AND body = '٤-' || char(10) || 'QuranText[(2:128:128)]') AS offspring_dua,
        SUM(titleId = 65 AND count = 0 AND search = 'يقرأ سورتي الفلق والناس') AS severe_weather_surahs,
        SUM(titleId = 68 AND count = 0 AND body LIKE '%﴿ وَٱلۡعَصۡرِ ١ إِنَّ ٱلۡإِنسَٰنَ لَفِي خُسۡرٍ ﴾ [سورة العصر]%') AS meeting_departure_asr
      FROM former_contents
      WHERE titleId IN (61, 62, 63, 64, 65, 68)
    ''');
    final foodMarriageAndMajlisJudgments = await database.rawQuery('''
      SELECT id, hokm
      FROM former_contents
      WHERE titleId IN (61, 62, 63, 64, 65, 68)
        AND hokm NOT IN ('', 'صحيح', 'حسن', 'ضعيف', 'موضوع', 'أثر')
    ''');
    final absoluteDhikrAndWirdSections = await database.rawQuery('''
      SELECT titles.id, COUNT(former_contents.id) AS count,
             MIN(former_contents."order") AS first, MAX(former_contents."order") AS last
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id IN (66, 67, 69, 70, 82,
                           83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final absoluteDhikrAndWirdRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 70) AS salawat_forms,
        SUM(titleId = 70 AND search LIKE '%وعلى أهل بيته%') AS household_salawat,
        SUM(titleId = 92 AND "order" = 1) AS first_wird_starts_at_one,
        SUM(titleId = 91 AND "order" = 33) AS eleventh_wird_ends_at_33
      FROM former_contents
      WHERE titleId IN (66, 67, 69, 70, 82,
                         83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
    ''');
    final absoluteDhikrAndWirdJudgments = await database.rawQuery('''
      SELECT former_contents.id, former_contents.hokm
      FROM former_contents
      WHERE former_contents.titleId IN
            (66, 67, 69, 70, 82,
              83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
        AND former_contents.hokm NOT IN
            ('', 'صحيح', 'حسن', 'ضعيف', 'موضوع', 'أثر')
    ''');
    final absoluteDhikrHierarchy = await database.rawQuery('''
      WITH RECURSIVE descendants(id, depth) AS (
        SELECT id, 0 FROM titles WHERE id = 140
        UNION ALL
        SELECT titles.id, descendants.depth + 1
        FROM titles
        JOIN descendants ON titles.parentId = descendants.id
      )
      SELECT COUNT(*) AS nodes, MAX(depth) AS max_depth
      FROM descendants
    ''');
    final absoluteDhikrContent = await database.rawQuery('''
      SELECT titleId, COUNT(*) AS count,
             SUM(count = 0) AS zero_count,
             MIN("order") AS first, MAX("order") AS last
      FROM former_contents
      WHERE titleId BETWEEN 149 AND 157 OR titleId = 165
      GROUP BY titleId
      ORDER BY titleId
    ''');
    final absoluteDhikrParents = await database.rawQuery('''
      SELECT id, parentId, "order"
      FROM titles
      WHERE id BETWEEN 69 AND 77
      ORDER BY id
    ''');
    final absoluteDhikrSamples = await database.rawQuery('''
      SELECT
        SUM(titleId = 149 AND search LIKE '%ولا يستطيعها البطلة%') AS quran,
        SUM(titleId = 151 AND search LIKE '%تكفى همك%') AS salawat,
        SUM(titleId = 152 AND search LIKE '%أكثروا من شهادة أن لا إله إلا الله%') AS tahlil,
        SUM(titleId = 153 AND search LIKE '%سيد الاستغفار%') AS istighfar,
        SUM(titleId = 154 AND body LIKE '%الباقيات الصالحات%') AS baqiyat,
        SUM(titleId = 155 AND search LIKE '%لا حول في دفع شر%') AS meaning,
        SUM(titleId = 156 AND search LIKE '%كنز من كنوز الجنة%') AS hawqala,
        SUM(titleId = 157 AND body LIKE '%كلمة استعانة%') AS notice
      FROM former_contents
      WHERE titleId BETWEEN 149 AND 157
    ''');
    final unsupportedJudgments = await database.rawQuery('''
      SELECT id, hokm
      FROM former_contents
      WHERE titleId BETWEEN 33 AND 60
        AND hokm NOT IN ('', 'صحيح', 'حسن', 'ضعيف', 'موضوع', 'أثر')
    ''');
    final prayerPilot = await database.rawQuery('''
      SELECT
        (SELECT parentId FROM titles WHERE id = 10) AS opening_parent,
        (SELECT parentId FROM titles WHERE id = 16) AS after_prayer_parent,
        (SELECT nodeType FROM titles WHERE id = 96) AS prayer_type,
        (SELECT COUNT(*) FROM titles WHERE id = 97) AS inside_prayer_titles,
        (SELECT COUNT(*) FROM titles WHERE id = 98) AS introduction_titles,
        (SELECT COUNT(*) FROM former_contents WHERE id = 1006) AS introduction_rows,
        (SELECT source LIKE '%حاشية: هذا ما ورد من الأذكار في دعاء التوجُّه، فيستحب الجمع بينها كلُّها%'
         FROM former_contents WHERE id = 907) AS introduction_as_footnote
    ''');
    final prayerPages91To115 = await database.rawQuery('''
      SELECT
        COUNT(*) AS rows,
        SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
        SUM(source LIKE '%(ص4%' OR source LIKE '%(ص5%' OR source LIKE '%(ص6%'
            OR source LIKE '%(ص7%' OR source LIKE '%(ص8%') AS earlier_edition_pages,
        SUM(source LIKE '%(مسلم)%' OR source LIKE '%(البخاري%'
            OR source LIKE '%(أبو داود%' OR source LIKE '%(الترمذي%') AS unprinted_takhrij,
        SUM(search LIKE '%والمهدي من هديت%' OR search LIKE '%أنا بك وإليك%') AS unprinted_opening_words,
        SUM(titleId = 10 AND search LIKE 'الله أكبر الله أكبر الله أكبر ذو%') AS third_takbir,
        SUM(titleId = 10 AND search = '٤- الله أكبر الله أكبر ذو الملكوت والجبروت والكبرياء والعظمة') AS two_takbirs_row,
        SUM(titleId = 10 AND count = 10) AS ten_times_cards,
        SUM(titleId = 10 AND count = 3) AS three_times_cards,
        SUM(titleId = 10 AND count = 0) AS opening_passages,
        SUM(titleId = 11 AND count = 0) AS ruku_passages,
        SUM(titleId = 12 AND count = 0) AS sujud_passages,
        SUM(titleId = 13 AND count = 0) AS tilawa_passages,
        SUM(titleId = 17 AND count = 0) AS qunut_passages,
        SUM(titleId = 14 AND count = 0) AS tashahhud_passages,
        SUM(titleId = 15 AND count = 0) AS after_tashahhud_passages
      FROM former_contents
      WHERE titleId IN (10, 11, 12, 13, 14, 15, 17)
    ''');
    final incidentalPages140To149 = await database.rawQuery('''
      SELECT
        COUNT(*) AS rows,
        SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
        SUM(source LIKE '%(ص8%' OR source LIKE '%(ص9%') AS earlier_edition_pages,
        SUM(count = 0) AS passages,
        SUM(titleId = 32 AND count = 0 AND search LIKE 'إذا هم بالأمر فليركع%ينوي بهما الاستخارة%') AS istikhara_instruction,
        SUM(titleId = 32 AND count = 1 AND source LIKE '%ينوي بهما%') AS istikhara_in_source,
        SUM(titleId = 32 AND count = 0 AND search LIKE 'تنبيه مما لا أصل له%') AS istikhara_note,
        SUM(titleId = 33 AND count = 0 AND search = '٥- وليكن أكثر دعائه أن يقول') AS most_of_his_dua,
        SUM(titleId = 33 AND "order" = 6 AND body LIKE '﴿%ءَاتِنَا%﴾') AS verse_201,
        SUM(titleId = 33 AND source LIKE '%جَهْد البلاء: بفتح الجيم؛ كُلُّ ما%') AS jahd_footnote_in_book_order,
        SUM(titleId = 35 AND count = 0 AND search = 'ويقول') AS satan_says,
        SUM(titleId = 35 AND search LIKE '%إلا طارقا يطرق بخير يا رحمن')
          AS knocker_without_comma,
        SUM(titleId = 35 AND body LIKE '%طارقٍ يطرقُ، إلَّا طارقًا يَطرُقُ بخيرٍ يا رحمن'
            AND source LIKE '%تنوير الحوالك%') AS knocker_footnote,
        SUM(titleId = 36 AND body LIKE '%(أو: قَدَرُ اللهِ)%') AS or_alternative,
        SUM(titleId = 37 AND source LIKE '%غليظ الأرض%') AS hazn_footnote,
        SUM(titleId = 38 AND count = 0 AND search LIKE 'يمضي فيها متوكلا%') AS tira_instruction,
        SUM(titleId = 38 AND count = 1 AND source LIKE '%أنت سبحانك%') AS tira_footnote
      FROM former_contents
      WHERE titleId BETWEEN 32 AND 40
    ''');
    final pilgrimageGuide = await database.rawQuery('''
      WITH RECURSIVE ancestry(id, depth) AS (
        SELECT id, 1 FROM titles WHERE parentId IS NULL
        UNION ALL
        SELECT child.id, ancestry.depth + 1
        FROM titles AS child
        JOIN ancestry ON child.parentId = ancestry.id
      )
      SELECT
        (SELECT MAX(depth) FROM ancestry WHERE id BETWEEN 50 AND 59 OR id BETWEEN 128 AND 139 OR id = 164) AS depth,
        (SELECT COUNT(*) FROM titles
         WHERE id BETWEEN 128 AND 133 AND nodeType = 'category') AS categories,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId = 139 AND count = 0) AS prose_rows,
        (SELECT parentId FROM titles WHERE id = 49) AS traveler_parent,
        (SELECT parentId FROM titles WHERE id = 50) AS ihram_parent,
        (SELECT parentId FROM titles WHERE id = 52) AS tawaf_parent,
        (SELECT parentId FROM titles WHERE id = 164) AS safa_parent,
        (SELECT parentId FROM titles WHERE id = 54) AS arafah_parent,
        (SELECT parentId FROM titles WHERE id = 56) AS prophet_mosque_parent
    ''');

    final guidanceNotes = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles
         WHERE id BETWEEN 122 AND 124 AND nodeType = 'category') AS categories,
        (SELECT COUNT(*) FROM titles
         WHERE id BETWEEN 125 AND 127) AS removed_guidance,
        (SELECT parentId FROM titles WHERE id = 18) AS sleep_parent,
        (SELECT parentId FROM titles WHERE id = 41) AS illness_parent,
        (SELECT parentId FROM titles WHERE id = 45) AS death_parent
    ''');

    final prayerSupplementCategories = await database.rawQuery('''
      SELECT id, name, parentId, "order", nodeType
      FROM titles
      WHERE id BETWEEN 110 AND 113
      ORDER BY id
    ''');
    final prayerSupplementSections = await database.rawQuery('''
      SELECT titles.id, titles.name, titles.parentId,
             COUNT(former_contents.id) AS count,
             MIN(former_contents."order") AS first,
             MAX(former_contents."order") AS last
      FROM titles
      JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id BETWEEN 114 AND 121
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final prayerSupplementRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 114 AND count != 0) AS counted_imam_guidance,
        SUM(titleId = 115 AND "order" <= 4 AND count != 0) AS counted_eid_guidance,
        SUM(titleId = 115 AND "order" BETWEEN 5 AND 9
            AND count = 1 AND hokm = '') AS eid_reports,
        SUM(titleId = 115 AND "order" = 4
            AND body = 'وفي صفة التكبير: آثارٌ موقوفةٌ منها:') AS eid_reports_heading,
        SUM(titleId = 115 AND "order" = 1
            AND body LIKE '%﴾ [البقرة: ١٨٥].') AS fitr_verse_reference,
        SUM(titleId = 115 AND "order" = 2
            AND body LIKE 'وقبل صلاة العيد يخرج من بيته%') AS fitr_exit_paragraph,
        SUM(titleId = 117 AND "order" = 1 AND count = 0
            AND body LIKE 'عن جُبَيْرِ بنِ نُفَيْرٍ%') AS greeting_report,
        SUM(titleId = 117 AND "order" = 2 AND hokm = ''
            AND source NOT LIKE '%جبير%') AS greeting_source,
        SUM(titleId = 118 AND "order" = 3 AND count = 0
            AND body LIKE 'ثُمَّ يَخْطُبُ الإمامُ النَّاسَ%') AS eclipse_sermon,
        SUM(titleId = 119 AND "order" <= 2 AND count != 0) AS counted_rain_guidance,
        SUM(titleId = 119 AND "order" = 1
            AND body LIKE 'يبدأ الإمامُ خُطبَتَهُ بالحمدِ%:' || char(10) || 'QuranText[(71:10:12)]')
          AS rain_opening,
        SUM(titleId = 119 AND "order" = 2
            AND body LIKE '%ويُبالِغُ في رَفْعِ يديه%بالأدعية التالية:'
            AND source LIKE '%حاشية: انظر: دعاء الكرب%(ص١٤٢)%حاشية: ويجعل بطون كفيه%')
          AS rain_guidance_footnotes,
        SUM(titleId = 119 AND "order" = 3
            AND body LIKE '١-' || char(10) || 'QuranText[(1:2:4)]' || char(10) || 'لَا إِلَهَ إِلَّا اللهُ، يَفْعَلُ مَا يُرِيدُ، اللَّهُمَّ أَنْتَ اللهُ%')
          AS rain_first_supplication,
        SUM(titleId = 119 AND "order" = 4 AND count = 1
            AND search = '٢- اللهم اسقنا اللهم اسقنا اللهم اسقنا') AS rain_second_supplication,
        SUM(titleId = 119 AND "order" = 5
            AND source LIKE '%حاشية: مَرِيئًا: محمود العاقبة.%حاشية: مَرِيعًا:%وكَثُر فيها العُشْبُ.')
          AS rain_footnotes,
        SUM(titleId = 121 AND "order" = 1
            AND body LIKE '%ثم قرأ هذه الآية:' || char(10) || 'QuranText[(3:135:135)]'
            AND source LIKE '%حاشية: المراد بالاستغفار%وَثُمَّ للترتيبِ بانفصالِ».')
          AS repentance_footnote,
        SUM(titleId = 121 AND "order" = 2 AND count = 0
            AND body LIKE 'قال الإمام ابن العربي رحمه الله:%'
            AND source LIKE '%حاشية: «عارضة الأحوذي» (٢/ ١٩٧).') AS ibn_alarabi,
        SUM(titleId = 121 AND "order" = 3 AND body = 'تنبيهان:') AS two_notices_heading,
        SUM(titleId = 121 AND "order" IN (4, 5) AND count = 0
            AND body LIKE 'ال%: %') AS two_notices,
        SUM(titleId = 121 AND "order" = 5
            AND source LIKE '%حاشية: «مجموع الفتاوى» (٢٣/ ٢١٥).') AS second_notice_footnote,
        SUM(titleId BETWEEN 115 AND 121 AND hokm != '') AS graded
      FROM former_contents
      WHERE titleId BETWEEN 114 AND 121
    ''');

    final bookContext = await database.rawQuery('''
      SELECT
        (SELECT nodeType FROM titles WHERE id = 99) AS about_book_type,
        (SELECT nodeType FROM titles WHERE id = 100) AS morning_evening_type,
        (SELECT nodeType FROM titles WHERE id = 108) AS mosque_type,
        (SELECT parentId FROM titles WHERE id = 1) AS morning_parent,
        (SELECT parentId FROM titles WHERE id = 2) AS evening_parent,
        (SELECT parentId FROM titles WHERE id = 8) AS mosque_parent,
        (SELECT COUNT(*) FROM titles WHERE parentId = 99) AS about_book_children,
        (SELECT COUNT(*) FROM titles WHERE parentId = 100) AS morning_evening_children,
        (SELECT COUNT(*) FROM titles WHERE parentId = 108) AS mosque_children,
        (SELECT COUNT(*) FROM former_contents
         WHERE id BETWEEN 1007 AND 1013 AND count = 0) AS zero_count_prose,
        (SELECT COUNT(*) FROM former_contents
         WHERE id BETWEEN 1007 AND 1013) AS prose_count,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId = 102
           AND search LIKE '%فهذا مختصر%الأذكار والأدعية الصحيحة%')
          AS introduction_searchable,
        (SELECT search LIKE '%كل يوم يعيشه المؤمن غنيمة%'
         FROM former_contents WHERE id = 1013) AS etiquette_searchable,
        (SELECT COUNT(*) FROM titles WHERE id IN (105, 107)) AS removed_sections
    ''');
    final absoluteDuaContext = await database.rawQuery('''
      SELECT
        (SELECT nodeType FROM titles WHERE id = 158) AS root_type,
        (SELECT COUNT(*) FROM titles WHERE parentId = 158) AS child_count,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId IN (159, 160, 166) AND count = 0) AS zero_count,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 159) AS introduction_count,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 160) AS virtues_count,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 166) AS times_count,
        (SELECT name FROM titles WHERE id = 159) AS introduction_name,
        (SELECT "order" FROM titles WHERE id = 166) AS times_order,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId = 159
           AND (body LIKE '%الطواف بالكعبة%' OR body LIKE '%وقفة المزدلفة%'
             OR body LIKE '%في السفر%')) AS introduction_times_left,
        (SELECT source LIKE '%حاشية: وبعض هذه الدعوات%'
         FROM former_contents WHERE id = 1160) AS introduction_footnote_kept,
        (SELECT search LIKE '%أوراد الدعاء المطلق%'
         FROM former_contents WHERE id = 1160) AS introduction_wirds,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId = 160 AND body LIKE '%وفي الدعاء معان%') AS meanings_left,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId = 160 AND body LIKE 'وقال زكريا عليه السلام%') AS zakariyya,
        (SELECT search LIKE '%الدعاء هو العبادة%'
         FROM former_contents WHERE id = 1178) AS worship_hadith,
        (SELECT body LIKE 'وعنه رضي الله عنه%'
         FROM former_contents WHERE id = 1183) AS hadith_opens_as_printed,
        (SELECT source LIKE '%حاشية: وذلك لأنه إما قانط%'
             AND source NOT LIKE '%فيض القدير%'
         FROM former_contents WHERE id = 1184) AS anger_footnote_as_printed,
        (SELECT source LIKE '%وبُنَيُّ آدمَ حين يُسألُ يَغضَبُ%'
             AND source LIKE '%«وأبخل الناس» أي: أمنعهم للفضل%'
         FROM former_contents WHERE id = 1185) AS weakest_people_footnotes,
        (SELECT body LIKE '%﴿ ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ ﴾%'
         FROM former_contents WHERE titleId = 166 AND "order" = 7) AS fatiha_time,
        (SELECT body FROM former_contents
         WHERE titleId = 166 AND "order" = 18) AS last_time
    ''');
    final absoluteDuaWirds = await database.rawQuery('''
      SELECT id, parentId, "order"
      FROM titles
      WHERE id IN (92, 82, 83, 84, 93, 86, 87, 88, 89, 90, 91)
      ORDER BY "order"
    ''');

    expect(await database.getVersion(), 167);
    expect(titleCount.single, {'count': 295});
    expect(foreignKeyViolations, isEmpty);
    expect(
        hierarchyColumns.map((row) => row['name']), ['nodeType', 'parentId']);
    expect(invalidHierarchyNodes, isEmpty);
    expect(duplicateSiblingOrder, isEmpty);
    expect(duplicateRootOrder, isEmpty);
    expect(prayerPilot.single, {
      // #220: «أذكار الصلاة» (96) holds its index lines; the index prints no
      // «أذكار داخل الصلاة» (97).
      'opening_parent': 96,
      'after_prayer_parent': 96,
      'prayer_type': 'category',
      'inside_prayer_titles': 0,
      'introduction_titles': 0,
      'introduction_rows': 0,
      'introduction_as_footnote': 1,
    });
    // pp140-149 (#177): what the book prints, no more and no less.
    expect(incidentalPages140To149.single, {
      'rows': 35,
      'judgments_or_virtues': 0,
      'earlier_edition_pages': 0,
      'passages': 5,
      'istikhara_instruction': 1,
      'istikhara_in_source': 0,
      'istikhara_note': 1,
      'most_of_his_dua': 1,
      'verse_201': 1,
      'jahd_footnote_in_book_order': 1,
      'satan_says': 1,
      'knocker_without_comma': 1,
      'knocker_footnote': 1,
      'or_alternative': 1,
      'hazn_footnote': 1,
      'tira_instruction': 1,
      'tira_footnote': 1,
    });
    // pp91-115 (#174): what the book prints, no more and no less.
    expect(prayerPages91To115.single, {
      'rows': 95,
      'judgments_or_virtues': 0,
      'earlier_edition_pages': 0,
      'unprinted_takhrij': 0,
      'unprinted_opening_words': 0,
      'third_takbir': 0,
      'two_takbirs_row': 1,
      'ten_times_cards': 7,
      'three_times_cards': 2,
      'opening_passages': 1,
      'ruku_passages': 2,
      'sujud_passages': 1,
      'tilawa_passages': 1,
      'qunut_passages': 3,
      'tashahhud_passages': 3,
      'after_tashahhud_passages': 3,
    });
    expect(pilgrimageGuide.single, {
      // #220: the hajj chapter (128) holds its index lines directly; the
      // app's own groups 129-132 are gone (decision 8).
      'depth': 2,
      'categories': 2,
      'prose_rows': 1,
      'traveler_parent': 133,
      'ihram_parent': 128,
      'tawaf_parent': 128,
      'safa_parent': 128,
      'arafah_parent': 128,
      'prophet_mosque_parent': 128,
    });
    expect(guidanceNotes.single, {
      'categories': 3,
      'removed_guidance': 0,
      'sleep_parent': 122,
      'illness_parent': 123,
      'death_parent': 124,
    });
    expect(
      prayerSupplementCategories,
      isEmpty,
      reason: '#220: the eid, eclipse, rain and repentance sections are lines '
          'of «أذكار الصلاة» as the index prints them, not groups of the app',
    );
    expect(
      prayerSupplementSections.map((row) => row['count']),
      [9, 9, 2, 2, 3, 7, 5],
    );
    expect(
      prayerSupplementSections.every(
        (row) => row['first'] == 1 && row['last'] == row['count'],
      ),
      isTrue,
    );
    expect(prayerSupplementRegression.single, {
      'counted_imam_guidance': 0,
      'counted_eid_guidance': 0,
      'eid_reports': 5,
      'eid_reports_heading': 1,
      'fitr_verse_reference': 1,
      'fitr_exit_paragraph': 1,
      'greeting_report': 1,
      'greeting_source': 1,
      'eclipse_sermon': 1,
      'counted_rain_guidance': 0,
      'rain_opening': 1,
      'rain_guidance_footnotes': 1,
      'rain_first_supplication': 1,
      'rain_second_supplication': 1,
      'rain_footnotes': 1,
      'repentance_footnote': 1,
      'ibn_alarabi': 1,
      'two_notices_heading': 1,
      'two_notices': 2,
      'second_notice_footnote': 1,
      'graded': 0,
    });
    expect(bookContext.single, {
      'about_book_type': 'category',
      'morning_evening_type': 'category',
      'mosque_type': 'category',
      'morning_parent': 100,
      'evening_parent': 100,
      'mosque_parent': 108,
      'about_book_children': 3,
      'morning_evening_children': 6,
      'mosque_children': 6,
      'zero_count_prose': 5,
      'prose_count': 5,
      'introduction_searchable': 1,
      'etiquette_searchable': 1,
      'removed_sections': 0,
    });
    expect(absoluteDuaContext.single, {
      'root_type': 'category',
      'child_count': 3,
      'zero_count': 34,
      'introduction_count': 3,
      'virtues_count': 13,
      'times_count': 18,
      'introduction_name': 'ما هي الأدعية المطلقة؟',
      'times_order': 3,
      'introduction_times_left': 0,
      'introduction_footnote_kept': 1,
      'introduction_wirds': 1,
      'meanings_left': 0,
      'zakariyya': 1,
      'worship_hadith': 1,
      'hadith_opens_as_printed': 1,
      'anger_footnote_as_printed': 1,
      'weakest_people_footnotes': 1,
      'fatiha_time': 1,
      'last_time': '١٨- عند حضور الميت، وعند تغميضه.',
    });
    // pp372-380 (#183), p381 (#167): the eleven wirds follow the times of
    // answer, under the heading the book prints over them.
    expect(absoluteDuaWirds, [
      {'id': 92, 'parentId': 191, 'order': 1},
      {'id': 82, 'parentId': 191, 'order': 2},
      {'id': 83, 'parentId': 191, 'order': 3},
      {'id': 84, 'parentId': 191, 'order': 4},
      {'id': 93, 'parentId': 191, 'order': 5},
      {'id': 86, 'parentId': 191, 'order': 6},
      {'id': 87, 'parentId': 191, 'order': 7},
      {'id': 88, 'parentId': 191, 'order': 8},
      {'id': 89, 'parentId': 191, 'order': 9},
      {'id': 90, 'parentId': 191, 'order': 10},
      {'id': 91, 'parentId': 191, 'order': 11},
    ]);
    expect(
      wirdCounts.map((row) => row['count']),
      [22, 21, 20, 15, 25, 22, 17, 22, 20, 25, 33],
    );
    expect(morningSection.single, {'count': 34, 'first': 1, 'last': 34});
    expect(eveningSection.single, {'count': 23, 'first': 1, 'last': 23});
    expect(nightSection.single, {
      'name': 'ثالثًا: ما يُقالُ في الليل (وأوله بعد المغرب)',
      'count': 9,
      'first': 1,
      'last': 9,
    });
    expect(
      unprintedSections.single,
      {'titles': 0, 'named': 0, 'contents': 0},
      reason: '«صلاة التسبيح» is not in the 10th edition (#175); the night '
          'section stays under the name p50 prints (#171)',
    );
    expect(khalaSections, [
      {
        'order': 2,
        'name': 'ما يقول إذا أرادَ دخولَ الخلاء',
        'count': 2,
      },
      {'order': 3, 'name': 'ما يقول إذا خرج من الخلاء', 'count': 1},
    ]);
    expect(mosqueSection.single, {'count': 2, 'first': 1, 'last': 2});
    expect(adhanListenerSection.single, {'count': 26, 'first': 1, 'last': 26});
    expect(
      duaAlistiftahSection.single,
      {'count': 22, 'first': 1, 'last': 22},
      reason: 'dua_alistiftah (titleId=10) as pp91-96 print it (#174): '
          '5 opening + 2 tahajjud + 7 ten-times cards + 3 closing tahajjud '
          'cards + the instruction and 3 taawwudh forms',
    );
    expect(
      rukuAndRisingSection.single,
      {'count': 17, 'first': 1, 'last': 17},
      reason: 'azkar_alkuru (titleId=11) as pp97-100 print it (#174): '
          '8 ruku dhikr, the two instructions, «سمع الله لمن حمده» and the '
          'six forms of the rising',
    );

    // Verify presence of specific formulas as requested in #19
    final ruku8thFormula = await database.rawQuery(
      "SELECT 1 FROM former_contents WHERE titleId=11 AND body LIKE '%وعليك توكلت%دمي ولحمي%'",
    );
    expect(ruku8thFormula, isNotEmpty,
        reason: 'Missing 8th independent ruku formula');

    final hamdAlternatives = await database.rawQuery(
      "SELECT search FROM former_contents WHERE titleId=11 AND search IN "
      "('١- ربنا لك الحمد أو ربنا ولك الحمد', '٢- أو اللهم ربنا ولك الحمد')",
    );
    expect(hamdAlternatives.length, 2,
        reason: 'p99 prints the first two forms of the rising with «أو:»');
    expect(sujudSection.single, {
      'count': 14,
      'first': 1,
      'last': 14,
      'complete_light_dua': 1,
    });
    expect(betweenProstrationsSection.single, {
      'count': 5,
      'first': 1,
      'last': 5,
      'correct_between_dua': 1,
      'unprinted_tilawa_ending': 0,
      'ordered_tilawa_dua': 1,
    });
    expect(prayerSectionOrder, [
      {'id': 13, 'order': 7, 'name': 'ما يقول بين السجدتين'},
      {'id': 17, 'order': 9, 'name': 'قنوت الوتر في رمضان وغيره'},
      {'id': 14, 'order': 10, 'name': 'التشهُّد في الصلاة'},
      {'id': 15, 'order': 12, 'name': 'الدعاء بعد التَّشَهُّدِ الأخير'},
      {'id': 16, 'order': 13, 'name': 'ما يقول بعد الصلاة'},
    ]);
    expect(qunutSection.single, {
      'count': 7,
      'first': 1,
      'last': 7,
      'combat_dua': 1,
      'closing_dua': 1,
      'third_paragraph': 1,
      'calamity_guidance': 1,
    });
    expect(tashahhudSection.single, {
      'count': 15,
      'first': 1,
      'last': 15,
      'fifth_tashahhud': 1,
      'first_salawat': 1,
      'seventh_salawat': 1,
      'second_tashahhud_variant': 1,
      'passages': 3,
    });
    expect(postTashahhudSection.single, {
      'count': 15,
      'first': 1,
      'last': 15,
      'prophetic_guidance': 1,
      'closing_dua': 1,
      'passages': 3,
    });
    expect(
        afterPrayerSection.single,
        {
          'count': 32,
          'first': 1,
          'last': 32,
          'opening_takbir': 1,
          'combined_tasbih': 1,
          'tasbih_alternatives': 5,
          'fourth_formula': 1,
          'fingers_note': 1,
          'morning_dhikr': 1,
          'sunset_dhikr': 1,
          'witr_dhikr': 1,
          'passages': 9,
          'two_istighfar': 1,
          'printed_dua': 1,
          'dashed_alternative': 1,
          'ayat_alkursi': 1,
          'mu_awwidhat': 1,
          'earlier_pointer': 2,
          'graded': 0,
          'old_edition_pages': 0,
        },
        reason: "pp116-121: six tasbih forms as one choice, with the book's "
            "instructions and sub-headings, and no grade the book does not "
            "print (#175)");
    // pp130-139 (#176): what the book prints, no more and no less.
    expect(sleepSection.single, {
      'count': 29,
      'first': 1,
      'last': 29,
      'printed_mu_awwidhatayn': 1,
      'lead_ins': 3,
      'printed_tahlil': 1,
      'printed_furqan': 1,
      'printed_mizan': 1,
      'tasbih_rows': 9,
      'tasbih_alternatives': 2,
      'first_takbir': 1,
      'third_tasbih': 1,
      'stopped_report': 1,
      'kafirun': 1,
      'graded': 0,
      'old_edition_pages': 0,
    });
    expect(visionSection.single, {
      'count': 12,
      'first': 1,
      'last': 12,
      'app_wording': 0,
      'seek_refuge': 1,
      'left_breathing': 1,
      'satan_refuge': 1,
      'prose_rows': 8,
      'graded': 0,
    });
    expect(nightAwakeningSection.single, {
      'count': 6,
      'first': 1,
      'last': 6,
      'taarra_hadith': 1,
      'tadawwur_dhikr': 1,
      'pure_sleeper': 1,
      'return_to_bed': 1,
      'graded': 0,
    });
    expect(nightExitSection.single, {
      'name': 'ما يقول إذا استيقظَ في الليل، وخرج من بيته',
      'parentId': 122,
      'order': 4,
      'count': 3,
      'al_imran_ending': 1,
      'hadiths': 2,
      'sleep_etiquette_titles': 0,
      'sleep_etiquette_rows': 0,
    });
    expect(istikharaSection.single, {'count': 1, 'first': 2, 'last': 2});
    expect(distressSection.single, {
      'count': 10,
      'first': 1,
      'last': 10,
      'complete_distress_dua': 1,
    });
    expect(fearSection.single, {
      'count': 9,
      'first': 1,
      'last': 9,
      'qasas_dua': 1,
    });
    expect(satanSection.single, {
      'count': 7,
      'first': 1,
      'last': 7,
      'repeated_refuge': 1,
      'repeated_curse': 1,
    });
    expect(situationalSections, [
      {'id': 36, 'name': 'ما يقول إذا غَلَبَه أمرٌ', 'count': 1},
      {'id': 37, 'name': 'ما يقولُ إذا استصعبَ عليه أمرٌ', 'count': 1},
      {
        'id': 38,
        'name': 'ما يقول مَنْ رَدَّتْه الطِّيَرَةُ عَنْ حاجَتِه',
        'count': 2
      },
      {
        'id': 39,
        'name': 'ما يقول إذا أصابته نكبةٌ قليلةٌ أو كثيرة',
        'count': 1,
      },
      {'id': 40, 'name': 'ما يقول إذا كان عليه دَيْنٌ عَجَزَ عنه', 'count': 1},
    ]);
    expect(illnessAndDeathSections, [
      {
        'id': 41,
        'name': 'ما يَقرَأ على الملدوغ',
        'count': 10,
        'first': 1,
        'last': 10,
      },
      {
        'id': 42,
        'name': 'ما يقوله المريض',
        'count': 18,
        'first': 1,
        'last': 18
      },
      {
        'id': 43,
        'name': 'ما يُقَال عند المريض، ويُقْرَأ عليه',
        'count': 8,
        'first': 1,
        'last': 8,
      },
      {'id': 44, 'name': 'رقية المريض', 'count': 8, 'first': 1, 'last': 8},
      {
        'id': 45,
        'name': 'ما يقول إذا استشعر حُضُورَ أَجَلِه',
        'count': 31,
        'first': 1,
        'last': 31,
      },
      {
        'id': 46,
        'name': 'أذكار الصلاة على الميت',
        'count': 21,
        'first': 1,
        'last': 21,
      },
    ]);
    expect(illnessAndDeathRegression.single, {
      'no_death_wish': 1,
      'medina_death_dua': 1,
      'named_patient_dua': 1,
      'fatiha_ruqya': 1,
      'child_funeral_dua': 1,
      'misplaced_child_dua': 0,
      'grave_visit_forms': 4,
    });
    expect(
      fastingTravelAndPilgrimageSections.map((row) => row['count']),
      [13, 41, 23, 8, 16, 4, 16, 7, 17, 4, 23, 15],
    );
    expect(
      fastingTravelAndPilgrimageSections
          .every((row) => row['first'] == 1 && row['last'] == row['count']),
      isTrue,
    );
    expect(fastingTravelAndPilgrimageRegression.single, {
      'app_only_iftar_dua': 0,
      'iftar_dua_as_printed': 1,
      'fasting_headings': 3,
      'umra_intention': 1,
      'qiran_intention': 1,
      'talbiya_variant': 1,
      'umra_without_talbiya': 0,
      'safa_dhikr_two_takbirs': 1,
      'safa_dhikr_three_takbirs': 0,
      'safa_verse': 1,
      'rulings_the_book_does_not_print': 0,
      'tawaf_prose': 1,
      'arafah_prose': 1,
      'sacrifice_heading': 1,
      'visit_abu_bakr': 1,
      'baqi_forms': 4,
      // p213 of the 10th edition prints «ما يقول من رأى مُنكرًا» at the end of
      // the fighting dhikr (#180).
      'misplaced_munkar_verses': 2,
    });
    expect(
      removedPilgrimageSections.single,
      {'titles': 0, 'contents': 0},
      reason: 'the app guides and the sections the book has no heading for',
    );
    expect(
      foodMarriageAndMajlisSections.map((row) => row['count']),
      [22, 15, 13, 5, 14, 8],
    );
    expect(
      foodMarriageAndMajlisSections.every(
        (row) => row['first'] == 1 && row['last'] == row['count'],
      ),
      isTrue,
    );
    expect(foodMarriageAndMajlisRegression.single, {
      'guest_dua': 1,
      'ibn_umar_reply': 1,
      'wife_dua': 1,
      'offspring_dua': 1,
      'severe_weather_surahs': 1,
      'meeting_departure_asr': 1,
    });
    expect(foodMarriageAndMajlisJudgments, isEmpty);
    expect(
      absoluteDhikrAndWirdSections.map((row) => row['count']),
      [
        23,
        89,
        6,
        4,
        21,
        20,
        15,
        22,
        17,
        22,
        20,
        25,
        33,
        22,
        25,
      ],
    );
    expect(
      absoluteDhikrAndWirdSections.every(
        (row) => row['first'] == 1 && row['last'] == row['count'],
      ),
      isTrue,
    );
    expect(absoluteDhikrAndWirdRegression.single, {
      'salawat_forms': 4,
      'household_salawat': 0,
      'first_wird_starts_at_one': 1,
      'eleventh_wird_ends_at_33': 1,
    });
    expect(absoluteDhikrAndWirdJudgments, isEmpty);
    expect(absoluteDhikrHierarchy.single, {'nodes': 55, 'max_depth': 3},
        reason: '#220: «من صِيَغ الحمد:» is a group inside «النوع السابع» '
            '(decision 10), one level below the kinds');
    expect(
      absoluteDhikrContent,
      [
        {'titleId': 149, 'count': 16, 'zero_count': 16, 'first': 1, 'last': 16},
        {'titleId': 151, 'count': 10, 'zero_count': 10, 'first': 1, 'last': 10},
        {'titleId': 152, 'count': 15, 'zero_count': 15, 'first': 1, 'last': 15},
        {'titleId': 153, 'count': 22, 'zero_count': 22, 'first': 1, 'last': 22},
        {'titleId': 154, 'count': 14, 'zero_count': 14, 'first': 1, 'last': 14},
        {'titleId': 155, 'count': 4, 'zero_count': 4, 'first': 1, 'last': 4},
        {'titleId': 156, 'count': 5, 'zero_count': 5, 'first': 1, 'last': 5},
        {'titleId': 157, 'count': 3, 'zero_count': 3, 'first': 1, 'last': 3},
        {'titleId': 165, 'count': 26, 'zero_count': 26, 'first': 1, 'last': 26},
      ],
    );
    expect(absoluteDhikrParents, [
      // #220: each in its kind at the place of its index line.
      {'id': 69, 'parentId': 143, 'order': 2},
      {'id': 70, 'parentId': 142, 'order': 4},
      {'id': 71, 'parentId': 144, 'order': 2},
      {'id': 72, 'parentId': 144, 'order': 3},
      {'id': 74, 'parentId': 173, 'order': 1},
      {'id': 75, 'parentId': 344, 'order': 1},
      {'id': 76, 'parentId': 175, 'order': 3},
    ]);
    expect(absoluteDhikrSamples.single, {
      'quran': 1,
      'salawat': 1,
      'tahlil': 1,
      'istighfar': 1,
      'baqiyat': 3,
      'meaning': 0,
      'hawqala': 1,
      'notice': 1,
    });
    expect(unsupportedJudgments, isEmpty);
  });

  test("absolute dhikr pages 247-293 are the book's rows (#182)", () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final sections = await database.rawQuery('''
      SELECT titleId, COUNT(*) AS count, SUM(count <> 0) AS counted,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(source LIKE '%(ص1__)%' OR source LIKE '%(ص1__–%') AS old_edition_pages
      FROM former_contents
      WHERE titleId IN (147, 148, 149, 165, 152, 161, 151, 70)
      GROUP BY titleId
      ORDER BY titleId
    ''');
    final tahlilWird = await database.rawQuery('''
      SELECT "order", count, source LIKE '%(ص28_)%' AS printed_page
      FROM former_contents WHERE titleId = 69 ORDER BY "order"
    ''');

    expect(
      tahlilWird.map((row) => row['count']),
      [0, 1, 1, 1, 3, 10],
      reason: 'the heading, then the five tahlil forms with the bracketed '
          'counts of pp285-286',
    );
    expect(tahlilWird.every((row) => row['printed_page'] == 1), isTrue);
    expect(sections.map((row) => '${row['titleId']}:${row['count']}'), [
      '70:4',
      '147:48',
      '148:7',
      '149:16',
      '151:10',
      '152:15',
      '161:7',
      '165:26',
    ]);
    expect(
      sections.every((row) =>
          row['counted'] == 0 &&
          row['judgments_or_virtues'] == 0 &&
          row['old_edition_pages'] == 0),
      isTrue,
    );
    expect(sections.length, 8);
  });

  test("absolute dhikr pages 294-338 are the book's rows (#184)", () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final titles = await database.rawQuery('''
      SELECT id, parentId, name FROM titles
      WHERE id IN (153, 71, 72, 154, 173, 176, 74, 174, 177, 75, 175, 172, 76)
      ORDER BY parentId, "order"
    ''');
    final sections = await database.rawQuery('''
      SELECT titleId, COUNT(*) AS count,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(body LIKE '%حاشية%') AS footnotes_in_body,
             SUM(source NOT LIKE '%(ص2__)%' AND source NOT LIKE '%(ص3__)%'
                 AND source NOT LIKE '%(ص2__–___)%'
                 AND source NOT LIKE '%(ص3__–3__)%') AS without_page
      FROM former_contents
      WHERE titleId IN (153, 71, 72, 154, 176, 74, 177, 75, 172, 76)
      GROUP BY titleId
      ORDER BY titleId
    ''');
    Future<List<Object?>> counts(int titleId) async {
      final rows = await database.rawQuery(
        'SELECT count FROM former_contents WHERE titleId = ? ORDER BY "order"',
        [titleId],
      );
      return rows.map((row) => row['count']).toList();
    }

    final regression = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM former_contents WHERE id IN (1118, 1119, 1122, 1125,
          1126, 1127, 1128, 1129, 1130, 1131, 1133, 1134, 1135, 1136, 1137,
          1138)) AS hadiths_not_printed_here,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 153
          AND body LIKE 'وعن عائشةَ رضي الله عنها قال%') AS aisha_corrected,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 154
          AND body LIKE '%[الكهف: ٤٦]%') AS kahf_reference_corrected,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 154
          AND body LIKE '%أقرئْ%') AS aqri_corrected,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 172
          AND body LIKE '%عن إدراكِهِ%') AS idrak_corrected,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 153
          AND body LIKE '%لأتيتُكَ بقُرابِها%'
          AND source LIKE '%حاشية: قُرابُ الأرضِ: ما يقارب مَلْأَها.')
          AS qurab_footnote,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 74
          AND body = '٩- سبحان الله وبحمده، سبحان الله العظيم.'
          AND source LIKE '%حاشية: عن أبي هريرةَ%' AND source LIKE '%تنبيه:%')
          AS two_light_words_footnote,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 71
          AND body LIKE '%-' || char(10) || 'QuranText%') AS whole_verses,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 71
          AND body LIKE '%- ﴿ %﴾') AS quoted_parts,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 76 AND "order" = 1
          AND source LIKE '%حاشية: تقدَّمت (ص١٢٣).') AS takbir_heading_footnote
    ''');

    expect(
        titles.map((row) => '${row['parentId']}:${row['id']}:${row['name']}'), [
      // #220: the index's lines; «ورد التسبيح» (176) is no line of it.
      '140:173:النوع السادس: وِرْدُ التَّسْبيح',
      '140:174:النوع السابع: وِرْدُ التحميد',
      '140:175:النوع الثامن: وِرْدُ التكبير',
      '144:153:من فضائلِ الاستغفار',
      '144:71:من صِيَغ الاستغفار في القرآن الكريم',
      '144:72:من صِيَغ الاستغفار في السُّنَّةِ الشَّرِيفَةِ',
      '145:154:من فضائل «الباقيات الصالحات»',
      '173:74:صِيَغُ التَّسبيحِ في القُرآنِ والسُّنَّة',
      '174:177:فضائل التحميد',
      '175:172:أَمْرُ اللهِ بالتكبير والحكمة منه',
      '175:76:من صيغ التكبير',
      '344:75:أولًا: في القرآن الكريم',
    ]);
    expect(sections.map((row) => '${row['titleId']}:${row['count']}'), [
      '71:20',
      '72:13',
      '74:34',
      '75:12',
      '76:7',
      '153:22',
      '154:14',
      '172:23',
      '176:13',
      '177:16',
    ]);
    expect(
      sections.every((row) =>
          row['judgments_or_virtues'] == 0 &&
          row['footnotes_in_body'] == 0 &&
          row['without_page'] == 0),
      isTrue,
    );
    expect(await counts(71), [0, ...List.filled(19, 1)],
        reason: 'pp302-305: the heading, then 19 forms without a bracket');
    expect(await counts(72), [0, 1, 100, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        reason: 'p306: «[كثيرًا]» has no number, «[مئة مرة]» is 100, and '
            'the twelfth item of p308 is prose');
    expect(await counts(76), [0, 1, 1, 1, 1, 1, 1]);
    expect(regression.single, {
      'hadiths_not_printed_here': 0,
      'aisha_corrected': 1,
      'kahf_reference_corrected': 1,
      'aqri_corrected': 1,
      'idrak_corrected': 1,
      'qurab_footnote': 1,
      'two_light_words_footnote': 1,
      'whole_verses': 4,
      'quoted_parts': 13,
      'takbir_heading_footnote': 1,
    });
  });

  test(
      "absolute dhikr introduction and Quran sections keep the book's "
      'words, footnotes and the removed sections stay removed (#182)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final sections = await database.rawQuery('''
      SELECT titleId, COUNT(*) AS count, SUM(count <> 0) AS counted,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(source LIKE '%(ص1__)%' OR source LIKE '%(ص1__–%') AS old_edition_pages
      FROM former_contents
      WHERE titleId IN (147, 148, 149, 165)
      GROUP BY titleId
      ORDER BY titleId
    ''');
    final removedTitle = await database.rawQuery(
      'SELECT COUNT(*) AS rows FROM titles WHERE id = 150',
    );
    final tahzib = await database.rawQuery('''
      SELECT name, parentId, nodeType,
             (SELECT body FROM former_contents WHERE titleId = 165 AND "order" = 1) AS heading
      FROM titles WHERE id = 165
    ''');
    final inventedOrOldWording = await database.rawQuery('''
      SELECT COUNT(*) AS rows
      FROM former_contents
      WHERE titleId IN (147, 148, 149, 165)
        AND (search LIKE '%الأذكار المطلقة هي أذكار ثبت فضلها%'
          OR search LIKE '%إنكم لا ترجعون إلى الله بشيء أفضل%'
          OR search LIKE '%فضائل عظيمة لتلاوة القرآن مطلقا%')
    ''');
    final footnotes = await database.rawQuery('''
      SELECT
        SUM(titleId = 149 AND source LIKE '%حاشية: البطلة: السحرة%') AS footnote_in_source,
        SUM(body LIKE '%حاشية%') AS footnote_in_body,
        SUM(titleId = 147 AND source LIKE '%طاقة وَرْد في فقه الوِرْد%') AS book_footnote,
        SUM(titleId = 148 AND body LIKE '%وَرَتِّلِ%' AND body LIKE '%[المزمل: ٤]%') AS partial_verse,
        SUM(titleId = 147 AND search LIKE '%مراقبة الأوقات وعمارتها بالأوراد%') AS closing_line
      FROM former_contents
    ''');

    expect(sections, [
      {
        'titleId': 147,
        'count': 48,
        'counted': 0,
        'judgments_or_virtues': 0,
        'old_edition_pages': 0,
      },
      {
        'titleId': 148,
        'count': 7,
        'counted': 0,
        'judgments_or_virtues': 0,
        'old_edition_pages': 0,
      },
      {
        'titleId': 149,
        'count': 16,
        'counted': 0,
        'judgments_or_virtues': 0,
        'old_edition_pages': 0,
      },
      {
        'titleId': 165,
        'count': 26,
        'counted': 0,
        'judgments_or_virtues': 0,
        'old_edition_pages': 0,
      },
    ]);
    expect(removedTitle.single, {'rows': 0});
    expect(tahzib.single, {
      'name': 'تحزيب القرآن المجيد',
      'parentId': 141,
      'nodeType': 'content',
      'heading': 'تحزيب القرآن المجيد',
    });
    expect(inventedOrOldWording.single, {'rows': 0});
    expect(footnotes.single, {
      'footnote_in_source': 1,
      'footnote_in_body': 0,
      'book_footnote': 1,
      'partial_verse': 1,
      'closing_line': 1,
    });
  });

  test('bundled azkar database follows the book (quality gate #52)', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    Future<List<Object?>> childIds(String parentFilter) async {
      final rows = await database.rawQuery('''
        SELECT id FROM titles WHERE $parentFilter ORDER BY "order"
      ''');
      return rows.map((row) => row['id']).toList();
    }

    final removedSections = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles WHERE id IN (73, 78, 79, 80)) AS titles,
        (SELECT COUNT(*) FROM former_contents WHERE titleId IN (73, 78, 79, 80))
          AS contents
    ''');
    final editorialSuffixes = await database.rawQuery('''
      SELECT id FROM titles WHERE name LIKE '%تنظيمي%'
    ''');
    final salawatIntroduction = await database.rawQuery('''
      SELECT id FROM former_contents WHERE titleId = 161 ORDER BY "order"
    ''');
    final salawatIntroductionText = await database.rawQuery('''
      SELECT
        SUM(body LIKE 'عن الأصمعي%') AS mahdi_report,
        SUM(body LIKE 'وقال سهل بن عبد الله%') AS sahl,
        SUM(body LIKE 'وقال العز بن عبد السلام%') AS izz,
        SUM(body LIKE 'وقال ابن قيم الجوزية%') AS ibn_qayyim_long,
        SUM(body LIKE 'وقال ابن القيم%') AS ibn_qayyim,
        SUM(count = 0 AND hokm = '') AS prose
      FROM former_contents
      WHERE titleId = 161
    ''');
    final paraphrasedSummaries = await database.rawQuery('''
      SELECT id FROM former_contents WHERE body LIKE '%وقد ذكر الكتاب%'
    ''');
    final salawatVirtuesOpening = await database.rawQuery('''
      SELECT id FROM former_contents WHERE titleId = 151 AND "order" = 1
    ''');

    expect(removedSections.single, {'titles': 0, 'contents': 0});
    expect(editorialSuffixes, isEmpty);
    expect(
      await childIds('parentId IS NULL'),
      [
        99, 100, 332, 333, 334, 335, 108, 336, 96, 122, 162, 123, 124, //
        337, 133, 128, 338, 339, 340, 341, 163, 147, 192, 193, 194, 195, //
        196, 140, 158, 191,
      ],
      reason: 'root order follows the book index (pp446-464, #220)',
    );
    expect((await childIds('parentId = 96')).last, 121,
        reason: 'p127 prints «صلاة التوبة» last in «أذكار الصلاة» (p449)');
    expect(await childIds('parentId = 100'), [197, 198, 1, 2, 3, 106],
        reason: 'p50 prints «ثالثًا: ما يُقال في الليل» in the morning and '
            'evening chapter, before its etiquette (index p446)');
    expect(
      await childIds('parentId = 162'),
      [32, 33, 34, 35, 36, 37, 38, 39, 40],
    );
    expect(await childIds('parentId = 163'), [342, 343]);
    expect((await childIds('parentId = 343')).skip(30), [330, 68, 331],
        reason: "pp242-244 print the gathering's dhikr inside «الأذكار "
            'المتفرقة», before «القسم الثاني» (p245)');
    expect(await childIds('parentId = 142'), [151, 280, 281, 70]);
    expect(await childIds('parentId = 140'),
        [141, 143, 142, 144, 145, 173, 174, 175, 146, 180, 183, 186, 189],
        reason: 'p281 prints tahlil (النوع الثاني) before p287 prints the '
            'prayers on the Prophet (النوع الثالث), pp294-338 print '
            'istighfar, al-baqiyat, tasbih, tahmid and takbir as the fourth '
            'to eighth kinds before the hawqala of p339, and pp344-362 print '
            'النوع العاشر to الثالث عشر after it');
    expect(
      salawatIntroduction.map((row) => row['id']),
      [1487, 1089, 1488, 1489, 1490, 1491, 1492],
      reason: 'p288 prints three hadiths under «النوع الثالث» before the '
          '«فضل الصلاة والسلام» heading of p289',
    );
    expect(
        salawatIntroductionText.single,
        {
          'mahdi_report': 1,
          'sahl': 0,
          'izz': 0,
          'ibn_qayyim_long': 0,
          'ibn_qayyim': 1,
          'prose': 7,
        },
        reason: "pp287-288 print the heading, al-Asma'i, Abu al-Aliya and "
            'Ibn al-Qayyim, and no sayings of Sahl or al-Izz (#182)');
    expect(paraphrasedSummaries, isEmpty);
    expect(salawatVirtuesOpening.single, {'id': 1493},
        reason: 'section 151 opens with the p289 heading; the three hadiths '
            'before it are in 161');

    final footnotesAsVirtues = await database.rawQuery('''
      SELECT id FROM former_contents WHERE id > 1006 AND TRIM(fadl) <> ''
    ''');
    final editorialNotes = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE body || source || fadl LIKE '%نقل المؤلف%'
         OR body || source || fadl LIKE '%نقل الكتاب%'
         OR body || source || fadl LIKE '%ذكر الكتاب%'
    ''');
    final ubayyComment = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE titleId = 151
        AND "order" = (SELECT "order" + 1 FROM former_contents WHERE id = 1496)
    ''');

    expect(footnotesAsVirtues, isEmpty,
        reason: 'book footnotes belong in the source as «حاشية» (#81)');
    expect(editorialNotes, isEmpty);
    expect(ubayyComment.single, {'id': 1497});

    final virtueRecords = await database.rawQuery('''
      SELECT id FROM former_contents WHERE TRIM(fadl) <> '' ORDER BY id
    ''');
    expect(
      virtueRecords.map((row) => row['id']),
      [274, 277],
      reason: 'a virtue line shows only what the book prints in its main '
          'text under the zikr (p104, p105); the hadith that opens the '
          'Arafa dhikr (p198) is a passage above it, not a virtue; excerpts of the '
          'takhrij hadiths stay whole in the source',
    );

    final alternatives = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE id IN (21, 49) AND count = 100 AND body LIKE '%' || char(10) || 'أو: %'
    ''');
    final separateAlternatives = await database.rawQuery('''
      SELECT id FROM former_contents WHERE id IN (22, 50)
    ''');
    final tawbah129 = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE id IN (18, 46, 414) AND body LIKE '%﴿ حَسۡبِيَ%' AND body NOT LIKE '%QuranText%'
    ''');
    final appLabels = await database.rawQuery('''
      SELECT COUNT(*) AS count FROM former_contents WHERE hokm = 'قرآني'
    ''');
    final morningClosing = await database.rawQuery('''
      SELECT id, count FROM former_contents
      WHERE titleId = 1 AND "order" IN (32, 33, 34) ORDER BY "order"
    ''');
    final morningNote = await database.rawQuery('''
      SELECT body FROM former_contents WHERE id = 1194
    ''');
    expect(alternatives.length, 2,
        reason: '«أو:» is one choice in one card, counted a hundred times '
            '(p14, p19)');
    expect(separateAlternatives, isEmpty);
    expect(tawbah129.length, 3,
        reason: 'the book quotes at-Tawbah 129 from «حسبي الله» (p13, p19, '
            'p152), not the whole verse');
    expect(appLabels.single, {'count': 0},
        reason: '«قرآني» is not a grading the book gives');

    final quotedVerses = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE id IN (222, 227, 236, 253, 254, 273, 304, 305, 306, 327, 328, 337, 355, 356,
                   398, 399, 412, 413, 415, 416, 417, 419, 420, 421, 422, 423,
                   425, 426, 427, 428, 429, 430, 431, 432, 454, 468, 607, 608,
                   610, 626, 627, 629, 630, 647, 648, 649, 686, 687, 688,
                   689, 690, 708, 709, 710, 711, 725, 747, 748, 827, 828, 829,
                   830, 831, 833, 846, 847, 1023, 1227, 1249, 447, 479)
        AND body LIKE '%﴿ %﴾%' AND body NOT LIKE '%QuranText%'
    ''');
    final supplicationsInTheBooksWords = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE id IN (251, 260) AND body NOT LIKE '%QuranText%'
        AND body NOT LIKE '%﴿%'
    ''');
    final fatihaVerses = await database.rawQuery('''
      SELECT id FROM former_contents WHERE id = 1037
        AND body LIKE '١-' || char(10) || 'QuranText[(1:2:4)]%'
    ''');
    final ridingVerseOnce = await database.rawQuery('''
      SELECT id FROM former_contents WHERE id = 872 AND body LIKE '%QuranText%'
    ''');
    expect(quotedVerses.length, 71,
        reason: 'the book quotes these verses in part; the app shows the same '
            'words, not the whole verse (#116)');
    expect(supplicationsInTheBooksWords.length, 2,
        reason: 'pp97, 99 write these as supplications, not as verses; p142 '
            'prints «ربنا آتنا» as the verse (#177)');
    expect(fatihaVerses.single, {'id': 1037},
        reason: 'p74 «الحمد لله رب العالمين…» is al-Fatiha 2-4; 1:1 is the '
            'basmala');
    expect(ridingVerseOnce, isEmpty,
        reason: 'p133: the riding verse belongs to the first supplication');
    expect(
        morningClosing,
        [
          {'id': 1194, 'count': 0},
          {'id': 1234, 'count': 0},
          {'id': 28, 'count': 1},
        ],
        reason: 'the «تنبيه» and the line «فإذا قام عن مجلسه…» are read '
            'before the expiation of the gathering (p42-43)');
    expect(
      morningNote.single['body']! as String,
      allOf(startsWith('تنبيه:'), endsWith('والحولقة، وغيرها.')),
    );

    final distressFootnotes = await database.rawQuery('''
      SELECT (LENGTH(source) - LENGTH(REPLACE(source, 'حاشية:', ''))) / 6
        AS notes
      FROM former_contents WHERE id = 225
    ''');
    final recordsWithFootnotes = await database.rawQuery('''
      SELECT COUNT(*) AS count FROM former_contents WHERE source LIKE '%حاشية:%'
    ''');
    expect(distressFootnotes.single, {'notes': 4},
        reason: 'p. 90 footnotes on «جهد البلاء» (#87)');
    expect(recordsWithFootnotes.single, {'count': 284},
        reason:
            'pp5-26 (#170), pp29-68 (#171), pp69-75 (#172), pp76-90 (#173), pp91-115 (#174), pp116-129 (#175), '
            'pp130-139 (#176), pp140-149 (#177), pp150-174 (#178), pp175-207 (#179), '
            'pp177-226 (#180), pp227-244 (#181), pp247-293 (#182), pp294-338 (#184), '
            'pp339-371 (#185), pp372-380 (#183) and pp381-444 (#167) print their footnotes');
  });

  test(
    'illness, death and the funeral prayer follow pp150-174 of the book (#178)',
    () async {
      sqfliteFfiInit();
      final database = await databaseFactoryFfi.openDatabase(
        File('assets/db/Al-Azkar.db').absolute.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      addTearDown(database.close);
      await _createFormerContents(database);

      Future<Map<String, Object?>> row(int id) async =>
          (await database.rawQuery(
            'SELECT body, count, source, hokm, fadl FROM former_contents WHERE id = ?',
            [id],
          ))
              .single;

      final sections = await database.rawQuery('''
      SELECT titleId, COUNT(*) AS rows, SUM(count = 0) AS passages,
             SUM(hokm <> '') AS gradings,
             SUM(source NOT GLOB '*(ص1[5-7][0-9])*'
                 AND source NOT GLOB '*(ص1[5-7][0-9]–1[5-7][0-9])*') AS other_pages
      FROM former_contents WHERE titleId BETWEEN 41 AND 46
      GROUP BY titleId ORDER BY titleId
    ''');
      final removed = await database.rawQuery('''
      SELECT (SELECT COUNT(*) FROM titles WHERE id IN (47, 126, 127)) AS titles,
             (SELECT COUNT(*) FROM former_contents
              WHERE id IN (285, 1047, 1048) OR titleId IN (47, 126, 127)) AS rows
    ''');
      final fatihaPrinted = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE titleId BETWEEN 41 AND 46 AND body LIKE '%QuranText%'
    ''');

      expect(
        sections.map((r) => '${r['titleId']}:${r['rows']}:${r['passages']}'),
        ['41:10:5', '42:18:8', '43:8:1', '44:8:3', '45:31:18', '46:21:6'],
      );
      expect(
        sections.every((r) => r['gradings'] == 0 && r['other_pages'] == 0),
        isTrue,
        reason: 'pp150-174 print no grading, and every row cites its page',
      );
      expect(
        removed.single,
        {'titles': 0, 'rows': 0},
        reason: 'the OCD note and the condolence note are footnotes of the '
            'book (pp151-155, p167); «الجنازة والدفن والقبور» is no heading of '
            'the book, and the two burial formulas are one row',
      );
      expect(
        fatihaPrinted,
        isEmpty,
        reason: 'pp150, 162 name al-Fatiha and do not print it',
      );

      final waswasa = await row(1599);
      expect(
        waswasa['source'],
        startsWith('ما يقول من بُلِيَ بالوسوسة. (ص151–155)\n\nحاشية: يُرادُ'),
      );
      expect(waswasa['source'], contains('(Obsessive Compulsive Disorder).'));
      expect(waswasa['source'], endsWith('في الشهر الثالث غالبًا.'));
      expect(
        (await row(1631))['source'],
        contains('حاشية: واعلم أنَّ لفظ التعزية لا حَجْرَ فيه'),
      );
      expect(
        (await row(976))['body'],
        endsWith('رسولِكَ صَلَّى اللهُ عَلَيْهِ وَآلِهِ وَسَلَّمَ'),
        reason: 'p159 prints the salawat with «وآله»',
      );
      expect(
        (await row(272))['body'],
        '٢- ما أرى الأجَلَ إلا اقتربَ، فاتَّقوا اللهَ واصْبِرُوا',
        reason: 'p163 has no «قد»',
      );
      expect((await row(284))['body'], contains('سُنَّةِ -أو مِلَّةِ- رسولِ'));
      expect((await row(288))['body'], contains('وإيَّاكُم، وما تُوعَدُونَ'));
      for (final (id, number) in [(288, '٢'), (289, '٣'), (290, '٤')]) {
        expect((await row(id))['body'], startsWith('$number- أو: '));
      }
      expect((await row(980))['body'], contains('-ويُسَمِّي الميتَ-'));
      expect(
          (await row(265))['body'], '٥- اللهمَّ اشفِ «فلانًا» [ثلاث مرَّاتٍ]');
      expect((await row(983))['body'], contains('يا «فلان»'));
      expect((await row(263))['body'], endsWith('أو يَمْشِ لكَ إلى الصلاةِ'));
      expect(
        (await row(269))['source'],
        contains('حاشية: وفي تكرار مادة (الشفاء)'),
        reason: 'p162 marks the footnote on the third ruqya, not the fourth',
      );
      expect((await row(270))['source'], isNot(contains('حاشية')));
      expect(
        (await row(274))['source'],
        isNot(contains('حاشية')),
        reason: 'p164 prints no footnote on the tahlil',
      );
      expect((await row(277))['fadl'], contains('(لا إله إلَّا اللهُ) دَخَلَ'));
      expect((await row(1637))['source'], contains('«حيثما مررتَ بقبرِ كافرٍ'));
      expect(
        [
          for (final id in [255, 256, 265, 977, 254]) (await row(id))['count'],
        ],
        [3, 7, 3, 7, 3],
        reason: 'the bracketed counts of pp158, 160, 161; p157-158 says '
            '«ثلاثَ مرَّاتٍ» in the line itself',
      );
    },
  );

  test('travel to celestial matters follow pp177-226 of the book (#180)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final sections = await database.rawQuery('''
      SELECT titleId AS id, COUNT(*) AS rows,
             SUM(count = 0) AS passages,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(source LIKE '%(ص13%' OR source LIKE '%(ص14%'
                 OR source LIKE '%(ص15%') AS earlier_edition_pages
      FROM former_contents
      WHERE titleId IN (139, 49, 60, 61, 62, 63, 64, 65)
      GROUP BY titleId ORDER BY titleId
    ''');
    final regression = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM former_contents WHERE id = 880) AS ibn_masud_footnote_as_dhikr,
        (SELECT COUNT(*) FROM former_contents WHERE id = 397
           AND source LIKE '%حاشية: وعن ابن مسعود%') AS ibn_masud_in_footnote,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 65
           AND body LIKE 'QuranText%') AS unprinted_surahs,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 60
           AND body IN ('QuranText[(17:81:81)]', 'QuranText[(34:49:49)]')) AS munkar_verses,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 49
           AND source LIKE '%أبو داود%') AS unprinted_takhrij,
        (SELECT COUNT(*) FROM former_contents WHERE id = 309
           AND source LIKE '%حاشية: هذه الأذكار في هذا الموضع%') AS compiled_note_on_fifth,
        (SELECT COUNT(*) FROM former_contents WHERE id = 308
           AND source LIKE '%حاشية: هذه الأذكار في هذا الموضع%') AS compiled_note_on_fourth,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 49
           AND body LIKE 'اللهُ أكبرُ، اللهُ أكبرُ، لا إله إل% اللهُ وحدَه%') AS two_takbirs_on_return,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 61
           AND body LIKE '%ولا مُسْتَغْنًى عنه رَبُّنا' AND source LIKE '%[الضحى: ٣]%') AS khattabi_footnote,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 62
           AND body LIKE 'أو: %') AS sneeze_alternatives,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 63
           AND source LIKE 'ما يُقال عند إرادة الجماع%') AS intercourse_heading
    ''');

    expect(sections, [
      {
        'id': 49,
        'rows': 41,
        'passages': 18,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 60,
        'rows': 23,
        'passages': 5,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 61,
        'rows': 22,
        'passages': 9,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 62,
        'rows': 15,
        'passages': 6,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 63,
        'rows': 13,
        'passages': 2,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 64,
        'rows': 5,
        'passages': 0,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 65,
        'rows': 14,
        'passages': 6,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
      {
        'id': 139,
        'rows': 1,
        'passages': 1,
        'judgments_or_virtues': 0,
        'earlier_edition_pages': 0,
      },
    ]);
    expect(regression.single, {
      'ibn_masud_footnote_as_dhikr': 0,
      'ibn_masud_in_footnote': 1,
      'unprinted_surahs': 0,
      'munkar_verses': 2,
      'unprinted_takhrij': 0,
      'compiled_note_on_fifth': 1,
      'compiled_note_on_fourth': 0,
      'two_takbirs_on_return': 1,
      'khattabi_footnote': 1,
      'sneeze_alternatives': 4,
      'intercourse_heading': 1,
    });
  });

  test(
      'the scattered dhikr and the gathering follow pp227-244 of the book (#181)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final sections = await database.rawQuery('''
      SELECT titleId AS id, COUNT(*) AS rows,
             SUM(count = 0) AS passages,
             SUM(body LIKE 'أو: %') AS alternatives,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(source NOT LIKE '%(ص2__)%' AND source NOT LIKE '%(ص2__–2__)%')
               AS without_tenth_edition_page
      FROM former_contents
      WHERE titleId IN (66, 67, 68)
      GROUP BY titleId ORDER BY titleId
    ''');
    final regression = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM former_contents WHERE id = 413
           AND source LIKE 'ما يقول من دُعِيَ إلى حكم الله ورسوله. [النور: ٥١].%')
          AS called_to_judgement_heading,
        (SELECT COUNT(*) FROM former_contents WHERE id = 429
           AND source LIKE '%حاشية: حِفظًا أو حافظًا%') AS hifz_footnote,
        (SELECT COUNT(*) FROM former_contents WHERE id = 434
           AND search = 'وأنا والله يا فلان أحبك في الله') AS named_brother,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 67
           AND search IN ('أو أهلكتم -أو قطعتم- ظهر الرجل',
                          'أو عقرت الرجل عقرك الله', 'أو المدح ذبح'))
          AS praise_alternatives,
        (SELECT COUNT(*) FROM former_contents WHERE id = 447
           AND body = '﴿ سُبۡحَانَ رَبِّي ﴾') AS wonder_verse,
        (SELECT COUNT(*) FROM former_contents WHERE id = 457
           AND search = '٤- رضينا بالله ربا وبالإسلام دينا وبمحمد رسولا نعوذ بالله من سوء الفتن')
          AS ridina_as_printed,
        (SELECT COUNT(*) FROM former_contents WHERE id = 454
           AND search LIKE '%اهدني لما اختلف فيه من الحق بإذنك%') AS fitna_dua_whole,
        (SELECT COUNT(*) FROM former_contents WHERE id = 458
           AND source LIKE '%[موقوف عن ابن عمر رضي الله عنهما – ضعيف]%') AS mawquf_in_source,
        (SELECT COUNT(*) FROM former_contents WHERE id = 463
           AND search LIKE '%على كثير من خلقه تفضيلا') AS min_khalqihi,
        (SELECT COUNT(*) FROM former_contents WHERE titleId = 67
           AND body LIKE '٢- أعوذُ باللهِ السميعِ العليمِ من الشيطانِ الرجيمِ%QuranText[(113:1:5),(114:1:6)]')
          AS evil_eye_muawwidhatayn,
        (SELECT count FROM former_contents WHERE id = 474) AS shirk_dua_count,
        (SELECT COUNT(*) FROM former_contents WHERE id = 477 AND count = 100
           AND source LIKE '%حاشية: وفي رواية: «الرحيم» مكان «الغفور».')
          AS hundred_istighfar,
        (SELECT COUNT(*) FROM titles WHERE id = 103) AS unprinted_conclusion
    ''');
    final loveOrder = await database.rawQuery('''
      SELECT id FROM former_contents WHERE titleId = 67 AND "order" <= 4 ORDER BY "order"
    ''');
    final afterWish = await database.rawQuery('''
      SELECT MAX("order") - (SELECT "order" FROM former_contents WHERE id = 475) AS rows
      FROM former_contents WHERE titleId = 67
    ''');

    expect(sections, [
      {
        'id': 66,
        'rows': 23,
        'passages': 2,
        'alternatives': 0,
        'judgments_or_virtues': 0,
        'without_tenth_edition_page': 0,
      },
      {
        'id': 67,
        'rows': 89,
        'passages': 33,
        'alternatives': 12,
        'judgments_or_virtues': 0,
        'without_tenth_edition_page': 0,
      },
      {
        'id': 68,
        'rows': 8,
        'passages': 5,
        'alternatives': 0,
        'judgments_or_virtues': 0,
        'without_tenth_edition_page': 0,
      },
    ]);
    expect(regression.single, {
      'called_to_judgement_heading': 1,
      'hifz_footnote': 1,
      'named_brother': 1,
      'praise_alternatives': 3,
      'wonder_verse': 1,
      'ridina_as_printed': 1,
      'fitna_dua_whole': 1,
      'mawquf_in_source': 1,
      'min_khalqihi': 1,
      'evil_eye_muawwidhatayn': 1,
      'shirk_dua_count': 1,
      'hundred_istighfar': 1,
      'unprinted_conclusion': 0,
    });
    expect(loveOrder.map((row) => row['id']), [1582, 433, 1583, 434],
        reason: 'p233 prints the occasion before each reply');
    expect(afterWish.single, {'rows': 8},
        reason: 'p241 prints «ليتني أوتيت…» before the rooster, the donkeys, '
            'the empty house and the fear of riya on p242');
  });

  test('the closing dates of both introductions are small lines (#140, #170)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final styled = await database.rawQuery('''
      SELECT id, titleId, "order", count, body, source FROM former_contents
      WHERE style <> '' ORDER BY titleId DESC
    ''');
    final lastOrder = await database.rawQuery('''
      SELECT titleId, MAX("order") AS last FROM former_contents
      WHERE titleId IN (102, 171) GROUP BY titleId ORDER BY titleId DESC
    ''');

    expect(styled.map((row) => row['id']), [1659, 1204]);
    expect(styled.map((row) => row['count']), [0, 0]);
    expect(
      lastOrder.map((row) => row['last']),
      styled.map((row) => row['order']),
      reason: 'each date closes its introduction',
    );
    expect(
      styled[0]['body'],
      'محمد أحمد إسماعيل المقدم\n'
      'الإسكندرية\n'
      'في الأحد 21 من ذي الحجة 1444هـ\n'
      'الموافق 9 من يوليو 2023م',
    );
    expect(styled[0]['source'], 'مقدمة هذه الطبعة. (ص6)');
    expect(
      styled[1]['body'],
      'محمد أحمد إسماعيل المقدم\n'
      'الإسكندرية\n'
      'في الجمعة 6 من ذي القعدة 1407هـ\n'
      'الموافق 3 من يوليو 1987م',
    );
    expect(styled[1]['source'], 'مقدمة الطبعات السابقة. (ص11)');
  });

  test('about the book follows pages 5-26 of the book (#170)', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    Future<List<Map<String, Object?>>> rows(int titleId) => database.rawQuery(
          'SELECT id, body, count, source, hokm, fadl FROM former_contents '
          'WHERE titleId = ? ORDER BY "order"',
          [titleId],
        );
    int footnotes(List<Map<String, Object?>> section) => section
        .map((row) => 'حاشية:'.allMatches(row['source']! as String).length)
        .fold(0, (sum, n) => sum + n);
    String text(List<Map<String, Object?>> section) =>
        section.map((row) => row['body']! as String).join('\n');

    final children = await database.rawQuery('''
      SELECT id, "order", name FROM titles WHERE parentId = 99 ORDER BY "order"
    ''');
    final conclusion = await database.rawQuery('''
      SELECT id FROM former_contents WHERE body LIKE '%وهذا آخر ما تيسر جمعه%'
    ''');
    final thisEdition = await rows(171);
    final previous = await rows(102);
    final chapter = await rows(104);
    final all = [...thisEdition, ...previous, ...chapter];

    expect(
      children,
      [
        {'id': 171, 'order': 1, 'name': 'مقدمة هذه الطبعة'},
        {'id': 102, 'order': 2, 'name': 'مقدمة الطبعات السابقة'},
        {
          'id': 104,
          'order': 3,
          'name': 'الأمر بالإكثار من ذكر الله تعالى وفضيلته',
        },
      ],
      reason: '«تمهيد الكتاب» (101) and «خاتمة المؤلف» (103) are not printed',
    );
    expect(conclusion, isEmpty);
    expect([thisEdition.length, previous.length, chapter.length], [6, 14, 30]);
    expect(
      [footnotes(thisEdition), footnotes(previous), footnotes(chapter)],
      [3, 1, 3],
    );
    for (final row in all) {
      expect(row['count'], 0, reason: 'prose, row ${row['id']}');
      expect([row['hokm'], row['fadl']], ['', ''], reason: '${row['id']}');
      final page = RegExp(r'\(ص([0-9]+)(?:–([0-9]+))?\)')
          .firstMatch(row['source']! as String);
      expect(page, isNotNull, reason: 'row ${row['id']} names its page');
      final last = int.parse(page!.group(2) ?? page.group(1)!);
      expect(last, inInclusiveRange(5, 26), reason: 'row ${row['id']}');
    }

    expect(thisEdition.first['body'], 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ');
    expect(
      thisEdition[2]['body'],
      contains('﴿ وَلَذِكۡرُ ٱللَّهِ أَكۡبَرُۗ ﴾ [العنكبوت: ٤٥]'),
    );
    expect(
      thisEdition[2]['source'],
      contains('حاشية: من مقدمة الإمام الشوكاني'),
    );

    final previousText = text(previous);
    expect(previousText, contains('في الأوقات والأحوال المختلفة'));
    expect(previousText, isNot(contains('النبوية الثابتة')));
    expect(
      previousText,
      contains('على الحريصين على تيسير العمل بالأذكار الثابتة الواردة'),
    );
    expect(previousText, isNot(contains('الراغبين في مزيد من التيسير')));
    expect(previous.first['id'], 1008);
    expect(previous[7]['body'], 'تنبيه:');
    expect(previous[8]['body'], startsWith('اعلم -رحمني الله'));
    expect(previous[8]['body'], contains('يمكن الجمعُ بينها'));
    expect(
      previous[8]['source'],
      contains('حاشية: أمَّا في الألفاظ التي لا يمكن الجمع بينها'),
    );
    expect(
      previous[8]['source'],
      contains('في مثل هذا'),
      reason: 'the book prints «قي», a typo corrected and listed for the '
          'publisher (#224)',
    );
    expect(previous[12]['body'], contains('وظاهرًا وباطنًا'));
    expect(previous[12]['body'], contains('وخليلِه محمدٍ'));

    const headings = [
      'فضائل ذكر الله عز وجل',
      'لا بُدَّ من تَلَفُّظِ اللِّسانِ بالذِّكر:',
      'الأدعية الراتبة توقيفيَّة لا يُزاد فيها، ولا يُنقَص منها',
      'من نصوص العلماء في الحثِّ على المأثور وعدم الابتداع في الأذكار والأدعية',
    ];
    expect(
      headings.map((h) => chapter.indexWhere((row) => row['body'] == h)),
      [3, 11, 15, 25],
    );
    expect(chapter[15]['source'], contains('ومع ذلك فهناك ضوابطُ'));
    const sayings = [
      'قال الإمام أبو بكر محمد بن الوليد الطُّرْطوشي',
      'وقال القاضي عياض',
      'وقال شيخ الإسلام أحمد بن تيميَّةَ',
      'وقال ذَهَبِيُّ العصرِ',
    ];
    expect(
      sayings.map(
        (s) => chapter.indexWhere(
          (row) => (row['body']! as String).startsWith(s),
        ),
      ),
      [26, 27, 28, 29],
    );
    expect(chapter[27]['id'], 1012);
    expect(chapter[27]['body'], contains('(دعاء آدم، دعاء نوح'));
    expect(chapter[28]['id'], 1007);
    expect(chapter[29]['body'], contains('وما أخسرَ صفقةَ'));
    expect(chapter[2]['body'], contains('إنَّ الله لم يفرض على عباده'));
    expect(
      chapter[0]['body'],
      contains('﴿ وَٱذۡكُرُواْ ٱللَّهَ كَثِيرٗا لَّعَلَّكُمۡ تُفۡلِحُونَ ﴾'),
    );
    expect(text(chapter), isNot(contains('QuranText')));
  });

  test('morning and evening adhkar follow pages 29-68 of the book (#171)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    Future<Map<String, Object?>> row(int id) async => (await database.rawQuery(
          'SELECT body, count, source, hokm FROM former_contents WHERE id = ?',
          [id],
        ))
            .single;

    final removedTitles = await database.rawQuery('''
      SELECT id FROM titles WHERE id IN (105, 107)
    ''');
    final foreignToEvening = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE titleId = 2
        AND (search LIKE 'أمسينا على فطرة%' OR search LIKE 'رضيت بالله%'
             OR search LIKE 'بسم الله الذي%' OR search LIKE 'باسم الله الذي%')
    ''');
    final prayerOnTheProphet = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE titleId IN (1, 2) AND search LIKE '%صل على محمد وعلى آل محمد%'
    ''');
    final adab = await database.rawQuery('''
      SELECT id, count, hokm, substr(body, 1, 6) AS start FROM former_contents
      WHERE titleId = 106 ORDER BY "order"
    ''');
    final morningIntro = await database.rawQuery('''
      SELECT body FROM former_contents WHERE titleId = 1 AND "order" <= 3
      ORDER BY "order"
    ''');
    final night = await database.rawQuery('''
      SELECT id, count FROM former_contents WHERE titleId = 3 ORDER BY "order"
    ''');

    expect(removedTitles, isEmpty,
        reason: 'the 10th edition has no «كيف أصبحت؟» and prints the «تنبيه» '
            'inside the morning list (p42)');
    expect(foreignToEvening, isEmpty,
        reason: 'the evening list (pp44-49) is not the morning list');
    expect(prayerOnTheProphet, isEmpty,
        reason: 'the book prints no prayer on the Prophet among the '
            'regular adhkar (pp33-49)');

    expect(
      morningIntro.map((row) => row['body']),
      [
        'قَالَ اللهُ تعالى:\nQuranText[(33:41:42)]',
        'وقال عز وجل:\nQuranText[(7:205:205)]',
        'وقال سبحانه:\nQuranText[(30:17:17)]',
      ],
      reason: 'p29 quotes these verses whole',
    );

    final firstWhole = await row(14);
    expect(
      firstWhole['body'],
      contains('\nأو: سبحانَ اللهِ وبحمدِهِ عددَ خَلْقِه'),
      reason: 'p39 prints «أو:» under the third tasbih',
    );
    expect(firstWhole['hokm'], '');
    expect((await row(15))['source'], '',
        reason: 'p39: the first «اللهم عافني» has no footnote mark');
    expect((await row(16))['hokm'], 'حسن');
    for (final (id, body) in [
      (17, '١٦- سُوَر: (الإخلاص)، و(الفلق)، و(الناس) [ثلاثَ مرَّاتٍ]'),
      (45, '١٢- سُوَر: (الإخلاص)، و(الفلق)، و(الناس) [ثلاث مرات]'),
    ]) {
      final surahs = await row(id);
      expect(surahs['body'], body,
          reason: 'pp39, 47 name the three surahs and do not print them');
      expect(surahs['count'], 3);
    }
    expect((await row(2))['source']! as String,
        contains('حاشية: الزعيم: الضامن والكفيل.'));
    expect((await row(7))['source']! as String,
        contains('وتقول المرأة: «وأنا أَمَتُكَ» مكان: «وأنا عبدُكَ»'));
    expect((await row(23))['source']! as String, contains('تحفة الذاكرين'));
    expect((await row(1194))['body']! as String,
        contains('ثم التهليل، والصلاة على النبي'));
    expect((await row(1194))['body']! as String, contains('والحولقة'));

    expect(night.map((row) => row['count']), [3, 1, 1, 1, 1, 1, 1, 1, 1],
        reason: 'pp50-53: nine items, only the first is counted');
    expect((await row(56))['body'], contains('تَبَٰرَكَ ٱلَّذِي بِيَدِهِ'));

    expect(adab.length, 12);
    expect(adab.map((row) => row['start']), [
      'الأول:',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'واعلم ',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي',
    ]);
    expect(adab.every((row) => row['count'] == 0 && row['hokm'] == ''), isTrue);
  });

  test("absolute dhikr pages 339-371 are the book's rows (#185)", () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final sections = await database.rawQuery('''
      SELECT titleId, group_concat(count, '') AS counts,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(source LIKE '%(ص19_)%' OR source LIKE '%(ص19_–%') AS old_pages,
             SUM((length(source) - length(replace(source, 'حاشية:', ''))) / 6)
               AS footnotes,
             SUM(body LIKE '%حاشية%') AS footnotes_in_body
      FROM (SELECT * FROM former_contents ORDER BY titleId, "order")
      WHERE titleId IN (155, 156, 157, 178, 179, 181, 182, 184, 185,
                        187, 188, 190)
      GROUP BY titleId
      ORDER BY titleId
    ''');
    Future<Object?> value(String sql) async =>
        (await database.rawQuery(sql)).single.values.single;

    expect(
      sections.map((row) => '${row['titleId']}:${row['counts']}'
          ':${row['footnotes']}'),
      [
        '155:0000:3',
        '156:00000:1',
        '157:000:0',
        '178:00000000:0',
        '179:000000000000:3',
        '181:00000000000000000000:0',
        '182:01111111111111:2',
        '184:0000000000:2',
        '185:0111101111:0',
        '187:00000000000:1',
        '188:000111:1',
        '190:0000000000000000000000:0',
      ],
      reason: 'each heading and prose paragraph is a 0-count row, the 13 '
          'afiya forms, 8 hasbala forms and 3 parents forms count once, and '
          'every printed footnote is one «حاشية:» block in source',
    );
    expect(
      sections.every((row) =>
          row['judgments_or_virtues'] == 0 &&
          row['old_pages'] == 0 &&
          row['footnotes_in_body'] == 0),
      isTrue,
    );
    expect(
      await database.rawQuery(
          'SELECT id, name FROM titles WHERE id IN (146, 155, 156, 157, 77)'
          ' ORDER BY id'),
      [
        {'id': 146, 'name': 'النوع التاسع: وِرْدُ الحَوْلَقة'},
        {'id': 155, 'name': 'معنى الحولقة'},
        {'id': 156, 'name': 'فضائل الحولَقَة'},
      ],
      reason: 'pp339-343 spell «الحولقة», and print no separate hawqala '
          'dhikr for the old section 77; «تنبيهان» (157) is no line of the '
          'index (p462), so its rows end «فضائل الحولقة» (#220)',
    );
    expect(
      await value('''
        SELECT COUNT(*) FROM former_contents
        WHERE titleId IN (155, 156, 157)
          AND (search LIKE '%يا عبد الله بن قيس%'
            OR search LIKE '%أكثروا من غرس الجنة%'
            OR search LIKE '%من رزقهن عند موته%'
            OR search LIKE '%لا حول في دفع شر%')
      '''),
      0,
      reason: 'the hawqala rows the pages do not print stay deleted',
    );
    expect(
      await value('''
        SELECT source LIKE '%والتمتع به فيما يلائمه%'
               AND source NOT LIKE '%حاشية: وقال ابن حجر%'
        FROM former_contents WHERE id = 1149
      '''),
      1,
      reason: 'p341 prints al-Nawawi and Ibn Hajar as one footnote; its '
          'misprinted «فيها» reads «فيما» (#224)',
    );
    expect(
      await value(
          'SELECT search FROM former_contents WHERE titleId = 185 AND "order" = 2'),
      '١- ﴿ حسۡبنا ٱلله ونعۡم ٱلۡوكيل ﴾',
      reason: 'p357 quotes only the end of Al Imran 173',
    );
    expect(
      await value(
          'SELECT body FROM former_contents WHERE titleId = 188 AND "order" = 5'),
      '٢-\nQuranText[(14:41:41)]',
      reason: 'p361 quotes Ibrahim 41 whole',
    );
    expect(
      await value('''
        SELECT COUNT(*) FROM former_contents
        WHERE (titleId BETWEEN 155 AND 157 OR titleId BETWEEN 178 AND 190)
          AND body LIKE '%وَآلِهِ%'
      '''),
      2,
      reason: 'only pp362 and 364 print the glyph with «وآله»',
    );
  });

  test('the mosque and adhan chapters follow pp76-90 of the book (#173)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    Future<List<Object?>> column(String sql) async =>
        (await database.rawQuery(sql)).map((row) => row.values.single).toList();
    Future<Map<String, Object?>> row(int id) async => (await database.rawQuery(
          'SELECT titleId, body, count, source, hokm, fadl '
          'FROM former_contents WHERE id = ?',
          [id],
        ))
            .single;

    expect(
      await column('SELECT name FROM titles WHERE id = 108'),
      ['أذكار المسجد'],
    );
    expect(
      await column(
          'SELECT name FROM titles WHERE parentId = 108 ORDER BY "order"'),
      [
        'ما يقول إذا تَوَجَّهَ إلى المسجد',
        'ما يقولُ عندَ دخولِ المسجد',
        'ما يقول في المسجد',
        'ما يقول إذا سَمِعَ من يَنْشُدُ ضالَّةً في المسجد',
        'ما يقول إذا رأى من يبيع أو يبتاع في المسجد',
        'ما يقول عند الخروج من المسجد',
      ],
      reason: 'p77 prints «ما يقول في المسجد» between entering the mosque '
          'and the lost property, not after leaving it',
    );
    const chapterRows = '''
      titleId IN (SELECT id FROM titles WHERE parentId = 108)
      OR titleId IN (9, 114)
    ''';
    expect(
      await column('SELECT COUNT(*) FROM former_contents WHERE $chapterRows'),
      [54],
    );
    expect(
      await column('''
        SELECT COUNT(*) FROM former_contents
        WHERE ($chapterRows)
          AND (hokm != '' OR fadl != ''
               OR source NOT GLOB '*(ص[0-9]*)*'
               OR source GLOB '*(ص[1-6][0-9])*'
               OR source GLOB '*(ص7[0-5])*')
      '''),
      [0],
      reason: 'no grade or virtue is printed under these dhikr, and every '
          "page is the 10th edition's (pp76-90), not the 1443 pp39-48",
    );

    expect(await row(1528), {
      'titleId': 8,
      'body': 'يقول ما تقدَّم في: (ما يقول إذا خَرَجَ من بيته)، ويَزِيد:',
      'count': 0,
      'source': 'ما يقول إذا توجَّه إلى المسجد. (ص76)\n\nحاشية: تقدَّم (ص٧٤).',
      'hokm': '',
      'fadl': '',
    });
    expect((await row(77))['body'], startsWith('٢- باسمِ الله،'));
    expect((await row(894))['body'], startsWith('١- باسم الله،'));
    expect(
      await column(
          'SELECT body FROM former_contents WHERE id IN (79, 896, 897) ORDER BY id'),
      everyElement(startsWith('أو: ')),
    );
    expect((await row(81))['body'], startsWith('٢- أو: '),
        reason: 'p78 numbers the second «أو:» and not the first');
    expect(
      (await row(1010))['source'],
      endsWith('حاشية: انظر: «الأذكار المطلقة» (ص٢٤٧)، وما بعدها، '
          'و«الأدعية المطلقة» (ص٣٨١)، وما بعدها.'),
    );
    expect(
      await column(
          'SELECT "order" FROM former_contents WHERE id IN (1531, 892) '
          'ORDER BY id'),
      [7, 6],
    );
    expect(
      await column('SELECT count FROM former_contents WHERE titleId = 9 '
          'ORDER BY "order"'),
      [
        0,
        2,
        4,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        1,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        1,
        0,
        0,
        1,
        0,
        0
      ],
      reason: 'the adhan is printed in steps; [مرَّتين] and [أربعًا] are '
          'its counts, and the instructions between are passages',
    );
    expect(
      (await row(1534))['source'],
      startsWith('صفة الأذان. (ص79)\n\nحاشية: قال الإمام النووي'),
    );
    expect((await row(1534))['source'], endsWith('وكلتا الصفتين مشروعة.'));
    expect(
      (await row(1540))['source'],
      contains('\nولا تناقض في حالة إتيان المؤذن'),
      reason: 'p83 footnote 1 has two paragraphs in one note',
    );
    expect((await row(899))['body'].toString().split('\n'), hasLength(6));
    expect(
      (await row(906))['body'],
      'ويُكْثِرُ الدُّعاءَ بين الأذانِ والإقامةِ؛ لقول رسول الله ﷺ: '
      '«الدُّعاءُ بين الأذانِ والإقامةِ مُستجابٌ، فادْعُوا».',
    );
    expect((await row(1545))['body'], startsWith('وقال رجلٌ: يا رسولَ الله،'));
    expect(
      (await row(904))['source'],
      'ما يقول إذا سمع المؤذن. (ص88)\n\nحاشية: انظر: (ص١٠٩).',
    );

    expect((await row(1546))['body'], 'أو أيًّا من الوصايا التالية:');
    expect((await row(1018))['body'], contains('لِيَلِيَنِي منكم'));
  });

  test('the eleven wirds follow pp381-444 of the book (#167)', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    final heading = await database.rawQuery('''
      SELECT nodeType, parentId, "order",
             (SELECT group_concat(id) FROM
               (SELECT id FROM titles WHERE parentId = heading.id
                ORDER BY "order")) AS wirds
      FROM titles AS heading
      WHERE name = 'جامعُ أدعيةِ القرآنِ المجيدِ والسُّنَّةِ الصحيحة (الأدعية المُطلقة)'
    ''');
    final perWird = await database.rawQuery('''
      SELECT SUM(former_contents.count > 0) AS said,
             SUM(former_contents.count = 0) AS prose,
             SUM(former_contents.hokm <> '' OR former_contents.fadl <> '') AS judged,
             SUM(former_contents.source NOT LIKE (CASE titles.id
               WHEN 92 THEN 'الورد الأول' WHEN 82 THEN 'الورد الثاني'
               WHEN 83 THEN 'الورد الثالث' WHEN 84 THEN 'الورد الرابع'
               WHEN 93 THEN 'الورد الخامس' WHEN 86 THEN 'الورد السادس'
               WHEN 87 THEN 'الورد السابع' WHEN 88 THEN 'الورد الثامن'
               WHEN 89 THEN 'الورد التاسع' WHEN 90 THEN 'الورد العاشر'
               WHEN 91 THEN 'الورد الحادي عشر' END) || '. %') AS other_heading,
             SUM(former_contents.source NOT LIKE '%(ص38%'
                 AND former_contents.source NOT LIKE '%(ص39%'
                 AND former_contents.source NOT LIKE '%(ص4%') AS other_pages
      FROM titles JOIN former_contents ON former_contents.titleId = titles.id
      WHERE titles.id IN (92, 82, 83, 84, 93, 86, 87, 88, 89, 90, 91)
      GROUP BY titles.id
      ORDER BY titles."order"
    ''');
    final cases = await database.rawQuery('''
      SELECT
        (SELECT search LIKE '١- ﴿ رب أعوذ بك من% همزت ٱلشيطين ٩٧ وأعوذ بك رب أن %'
         FROM former_contents WHERE titleId = 92 AND "order" = 1) AS first_dua,
        (SELECT source LIKE '%حاشية: بدأنا بالاستعاذة%'
         FROM former_contents WHERE titleId = 92 AND "order" = 2) AS isti_adha_footnote,
        (SELECT body FROM former_contents
         WHERE titleId = 92 AND "order" = 3) AS fatiha,
        (SELECT source FROM former_contents
         WHERE titleId = 92 AND "order" = 19) AS mawquf_source,
        (SELECT COUNT(*) FROM former_contents
         WHERE (titleId = 83 AND "order" = 6 OR titleId = 91 AND "order" = 14)
           AND (search LIKE '٤٩- اللهم إني أسألك بأني أشهد%'
             OR search LIKE '٢٢٣- اللهم إني أسألك بأني أشهد%')) AS nos_49_and_223,
        (SELECT body LIKE '%واجعلني من عبادِكَ المخلَصين.'
         FROM former_contents WHERE titleId = 93 AND "order" = 16) AS typo_corrected,
        (SELECT group_concat(count) FROM former_contents
         WHERE titleId = 91 AND "order" IN (28, 29)) AS no_237,
        (SELECT body LIKE 'تمَّ الكِتابُ%' AND count = 0
         FROM former_contents WHERE titleId = 91 AND "order" = 33) AS closing,
        (SELECT COUNT(*) FROM former_contents
         WHERE titleId IN (92, 82, 83, 84, 93, 86, 87, 88, 89, 90, 91)
           AND (search LIKE '%أفرغ علينا صبرا%'
             OR search LIKE '%ألهمني رشدي%'
             OR search LIKE '%أحسنت خلقي%')) AS earlier_edition_only
    ''');

    expect(heading.single, {
      // #220: a chapter of its own at the end, as p464 prints it.
      'nodeType': 'category',
      'parentId': null,
      'order': 30,
      'wirds': '92,82,83,84,93,86,87,88,89,90,91',
    });
    expect(
      perWird.map((row) => row['said']),
      [22, 21, 20, 15, 25, 22, 17, 22, 20, 25, 32],
      reason: 'the book numbers 1-22, 23-43, 44-63, 64-78, 79-103, 104-125, '
          '126-142, 143-164, 165-184, 185-209 and 210-240; no. 237 is two '
          'lines, each «[ثلاثًا]»',
    );
    expect(
        perWird.map((row) => row['prose']), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        reason: 'p444 closes the book with «تمَّ الكتاب…»');
    expect(perWird.every((row) => row['judged'] == 0), isTrue,
        reason: 'pp381-444 print no grading and no virtue under a dua');
    expect(perWird.every((row) => row['other_heading'] == 0), isTrue);
    expect(perWird.every((row) => row['other_pages'] == 0), isTrue,
        reason: 'pages are those of the 10th edition, 381-444');
    expect(cases.single, {
      'first_dua': 1,
      'isti_adha_footnote': 1,
      'fatiha': '٣-\nQuranText[(1:1:7)]',
      'mawquf_source':
          'الورد الأول. [موقوفٌ عن ابن عمر رضي الله عنهما]. (ص386)',
      'nos_49_and_223': 2,
      'typo_corrected': 1,
      'no_237': '3,3',
      'closing': 1,
      'earlier_edition_only': 0,
    });
  });

  test('printing errors read correctly and are listed for the publisher (#224)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);
    final errata = File('../docs/book-errata.md').readAsStringSync();
    String arabicDigits(int n) => n
        .toString()
        .split('')
        .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
        .join();

    const corrections = [
      (id: 1656, page: 5, misprint: 'والفوئد', correct: 'والفوائد'),
      (id: 1667, page: 9, misprint: 'قي مثل', correct: 'في مثل'),
      (id: 1672, page: 13, misprint: '﴾. [', correct: '﴾ [الأنفال: ٤٥]'),
      (id: 1698, page: 23, misprint: 'الطُّرْشوشي', correct: 'الطُّرْطوشي'),
      (id: 64, page: 72, misprint: 'أونعلًا', correct: 'أو نعلًا'),
      (id: 899, page: 85, misprint: 'عى ', correct: 'محمولٌ على'),
      (id: 1599, page: 152, misprint: 'أشرنا إليه ', correct: 'أشرنا إليها'),
      (id: 1599, page: 154, misprint: 'المرضي', correct: 'المرضى يتحسنون'),
      (id: 1496, page: 289, misprint: 'ثلثا اليل', correct: 'ثلثا الليل'),
      (id: 1116, page: 298, misprint: 'عنه قال', correct: 'عنها قال'),
      (id: 1751, page: 309, misprint: '[الكهف: ٤٩]', correct: '[الكهف: ٤٦]'),
      (id: 1123, page: 312, misprint: 'عمر رضي', correct: 'عمرو رضي'),
      (id: 1759, page: 313, misprint: 'أقريءْ', correct: 'أقرئْ'),
      (id: 1826, page: 329, misprint: '[الفاتحة: ١]', correct: '[الفاتحة: ٢]'),
      (
        id: 1835,
        page: 330,
        misprint: 'العالمين»، ثم',
        correct: 'العالمين»»، ثم'
      ),
      (id: 1855, page: 336, misprint: '\nالأول:', correct: '\nالأولى:'),
      (id: 1858, page: 337, misprint: 'إداراكِهِ', correct: 'إدراكِهِ'),
      (id: 1149, page: 341, misprint: 'فيها يلائمه', correct: 'فيما يلائمه'),
      (id: 1951, page: 364, misprint: '»، .', correct: 'لأُعِيذَنَّه».'),
      (id: 1977, page: 370, misprint: 'قال: ﴿', correct: 'قال: «﴿'),
      (id: 1176, page: 375, misprint: '﴾. [غافر', correct: '﴾ [غافر: ٦٠]'),
      (id: 830, page: 383, misprint: '[البقرة: ٢٨٦]', correct: '[البقرة: ٢٨٥]'),
      (id: 770, page: 406, misprint: 'شرفتنة', correct: 'شر فتنة الفقر'),
      (
        id: 2021,
        page: 409,
        misprint: 'عني المخلَصين',
        correct: 'عبادِكَ المخلَصين'
      ),
      (id: 2022, page: 410, misprint: 'وفي أنَّه', correct: 'وفيه أنَّه'),
      (id: 630, page: 432, misprint: 'الرسول الله', correct: 'لرسول الله ﷺ'),
      (id: 804, page: 437, misprint: 'باسمعي', correct: 'بسمعي'),
      (id: 2090, page: 438, misprint: 'و بسطتَ', correct: 'وبسطتَ'),
      (id: 912, page: 94, misprint: 'أسرْتُ', correct: 'أسررْتُ'),
      (id: 1254, page: 125, misprint: 'يَخُطبُ', correct: 'يَخْطُبُ'),
      (id: 1267, page: 221, misprint: 'يَدُه', correct: 'يَدَه'),
      (id: 860, page: 431, misprint: 'بارِكَ على', correct: 'بارِكْ على'),
      (id: 804, page: 437, misprint: 'وانْصُرُنِي', correct: 'وانْصُرْنِي'),
    ];
    expect(
      (await database
              .rawQuery('SELECT body FROM former_contents WHERE id = 1645'))
          .single['body'],
      'وإذا رأى ما يكره',
      reason: 'p135 prints no colon after this line',
    );
    for (final c in corrections) {
      final text = (await database.rawQuery(
        "SELECT body || '\n' || source AS text FROM former_contents WHERE id = ?",
        [c.id],
      ))
          .single['text']! as String;
      expect(text, contains(c.correct), reason: 'p${c.page}, row ${c.id}');
      expect(text, isNot(contains(c.misprint)),
          reason: 'p${c.page}, row ${c.id}');
      expect(errata, contains('| ${arabicDigits(c.page)} |'),
          reason: 'p${c.page} is listed for the publisher');
    }
  });

  test('missing bundled database asset fails instead of continuing', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'zaad-db-copy-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final helper = DBHelper(dbName: 'missing.db', dbVersion: 1);

    await expectLater(
      helper.copyFromAssets(
        '${temporaryDirectory.path}/missing.db',
        'assets/db/does-not-exist.db',
      ),
      throwsA(isA<FlutterError>()),
    );
  });

  test('waking, toilet, ablution, clothing and house follow pp69-75 (#172)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    Future<Map<String, Object?>> row(int id) async => (await database.rawQuery(
          'SELECT titleId, "order", body, count, source FROM former_contents '
          'WHERE id = ?',
          [id],
        ))
            .single;

    final sections = await database.rawQuery('''
      SELECT titleId AS id, COUNT(*) AS rows, SUM(count = 0) AS passages,
             SUM(hokm <> '' OR fadl <> '') AS judgments_or_virtues,
             SUM(source NOT LIKE '%. (ص6_)%' AND source NOT LIKE '%. (ص7_)%'
                 AND source NOT LIKE '%. (ص69–70)%') AS unpaged
      FROM former_contents
      WHERE titleId IN (4, 94, 95, 5, 6, 7)
      GROUP BY titleId ORDER BY titleId
    ''');
    final unprinted = await database.rawQuery('''
      SELECT id FROM former_contents
      WHERE titleId IN (4, 94, 95, 5, 6, 7)
        AND (source LIKE '%رضي الله عنه%' OR source LIKE '%البخاري%'
             OR source LIKE '%الترمذي%' OR source LIKE '%النور%'
             OR source LIKE '%(صحيح)%' OR source LIKE '%(حسن)%'
             OR source LIKE '%ص 34%' OR body LIKE 'بسم الله%')
    ''');
    final houseTitle = await database.rawQuery(
      'SELECT name FROM titles '
      'WHERE id = (SELECT parentId FROM titles WHERE id = 7)',
    );

    expect(sections, [
      {
        'id': 4,
        'rows': 3,
        'passages': 0,
        'judgments_or_virtues': 0,
        'unpaged': 0,
      },
      {
        'id': 5,
        'rows': 3,
        'passages': 0,
        'judgments_or_virtues': 0,
        'unpaged': 0,
      },
      {
        'id': 6,
        'rows': 8,
        'passages': 1,
        'judgments_or_virtues': 0,
        'unpaged': 0,
      },
      {
        'id': 7,
        'rows': 6,
        'passages': 2,
        'judgments_or_virtues': 0,
        'unpaged': 0,
      },
      {
        'id': 94,
        'rows': 2,
        'passages': 0,
        'judgments_or_virtues': 0,
        'unpaged': 0,
      },
      {
        'id': 95,
        'rows': 1,
        'passages': 0,
        'judgments_or_virtues': 0,
        'unpaged': 0,
      },
    ]);
    expect(unprinted, isEmpty,
        reason: 'pp69-75 print no narration, grading or an-Nur verse here, '
            'and write «باسم الله» with its alif');
    expect(houseTitle.single['name'], 'أذكار دخول البيت، والخروج منه');

    expect((await row(59))['source'],
        'ما يقول إذا استيقظ من نومه. [«المسند» (١٧٢٩٦)]. (ص69–70)');
    expect(
      (await row(59))['body'],
      '٣- أعوذُ بالله من الشيطانِ الرجيم\nQuranText[(113:1:5),(114:1:6)]',
      reason: 'pp69-70 print al-Falaq and an-Nas whole',
    );

    final naming = await row(1639);
    expect(naming['titleId'], 6);
    expect(naming['order'], 2);
    expect(naming['count'], 0);
    expect(naming['body'], 'يُسَمِّيه باسمه، ثُمَّ يقول:');
    expect(
        naming['source']! as String, contains('\n\nحاشية: «يسميه باسمه: يعني:'),
        reason: 'p72 sets the footnote on «يسميه باسمه», not on the '
            'supplication');
    expect((await row(64))['source'],
        'ما يقول إذا لَبِسَ ثوبًا جديدًا أو نعلًا أو شبهه. (ص72)');
    expect((await row(68))['source']! as String,
        contains('للمخاطَب بذلك، أي أنه تطول حياته حتى يبلى الثوب ويخلق.'));

    final greeting = await row(73);
    expect(greeting['count'], 0,
        reason: 'p74: «ثم ليسلم على أهله» is an instruction');
    expect(greeting['source'], 'ما يقول إذا دخل بيته. (ص74)');
    final siwak = await row(1640);
    expect(siwak['titleId'], 7);
    expect(siwak['order'], 5);
    expect(siwak['count'], 0);
    expect(siwak['body'], 'وكان ﷺ إذا دَخَلَ بيته بدأ بالسِّواك.');
    expect(
      (await row(74))['source'],
      'ما يدعو به في بيته. [مُسلم: ٢٧٠٥]. (ص75)\n\nحاشية: وفي رواية: كبيرًا.',
    );
  });

  test('items show the list number and count bracket the book prints (#227)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);
    await _createFormerContents(database);

    Future<Map<String, Object?>> row(int id) async => (await database.rawQuery(
          'SELECT body, count, source FROM former_contents WHERE id = ?',
          [id],
        ))
            .single;

    // One row for each case in the ticket's table: body as printed, counter.
    final cases = {
      971: ('٢- وَيَنفُثُ عن يَسارِه. [ثلاثًا]', 3),
      220: ('٣- لا إلهَ إلَّا أنتَ، سُبْحانَكَ، إنِّي كُنتُ من الظالمين', 1),
      970: ('١- فَلْيَسْتَعِذْ باللهِ من شَرِّه.', 0),
      255: ('باسمِ اللهِ [ثلاثًا]', 3),
      1738: ('١- أستغفِرُ الله، وأتوبُ إليه. [كثيرًا]', 1),
      914: ('٣- اللهُ أكبرُ [عشرًا]', 10),
      1205: ('الحمدُ للهِ [عشرًا]', 10),
      212: (
        '١- أعوذُ بكلماتِ اللهِ التَّامَّةِ، مِن غَضَبِهِ وعِقابِهِ، ومِنْ شَرِّ عِبادِهِ، '
            'ومِن هَمَزاتِ الشَّياطين، وأن يَحْضُرُونِ',
        1
      ),
    };
    for (final MapEntry(key: id, value: (body, count)) in cases.entries) {
      final printed = await row(id);
      expect(printed['body'], body, reason: 'row $id');
      expect(printed['count'], count, reason: 'row $id keeps its counter');
    }
    expect(
      (await row(1738))['source'],
      'من صيغ الاستغفار في السنة الشريفة. (ص306)',
      reason: 'p306: «[كثيرًا]» moved from the source to the end of the body',
    );
    expect(
      (await row(212))['source'],
      'من آداب الرؤيا. [«الصحيحة» (٢٦٤)]. (ص136)',
      reason: 'p136: a bracket that is not a count stays in the source',
    );
    expect(
      await database.rawQuery('''
        SELECT id FROM former_contents
        WHERE titleId = 10 AND count = 10 AND id <> 914
          AND (body NOT LIKE '% [عشرًا]' OR body GLOB '[٠-٩]*')
      '''),
      isEmpty,
      reason: 'p95: each card of item ٣ ends with its «[عشرًا]», and only '
          'the first card carries the number',
    );
    expect((await row(54))['body'], '٢-\nQuranText[(112:1:4)]',
        reason: 'p50: a number gets its own line before a QuranText line, '
            'which the reader replaces with the verses');
    for (final count in [
      'ثلاث',
      'عشر',
      'سبع',
      'أربع',
      'مئة مرة',
      'مرَّتين',
      'مرتين',
      'كثير'
    ]) {
      expect(
        await database.rawQuery(
          'SELECT id FROM former_contents '
          "WHERE substr(source, 1, instr(source || char(10), char(10))) "
          'GLOB ?',
          ['*[[]$count*'],
        ),
        isEmpty,
        reason: 'no count bracket «[$count…]» is left in a source line',
      );
    }
  });

  test('diacritics follow the marks the book prints (#229)', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('zaad-harakat-');
    addTearDown(() => directory.delete(recursive: true));
    final copy =
        await File('assets/db/Al-Azkar.db').copy('${directory.path}/db');
    final database = await databaseFactoryFfi.openDatabase(copy.path);
    addTearDown(database.close);

    Future<String> body(int id) async => (await database.rawQuery(
          'SELECT body FROM contents WHERE id = ?',
          [id],
        ))
            .single['body']! as String;

    // One row for each rule of the audit.
    final cases = {
      2080: (
        'لا مانِعَ لما أعطيتَ',
        'p435: the book marks a letter the app left bare'
      ),
      245: ('أْجُرْنِي', "p149: the book's mark replaces the app's other mark"),
      1525: (
        'فَتُخَيِّبَني',
        "p375: a letter the book leaves bare keeps the app's mark"
      ),
      804: (
        'وانْصُرْنِي على',
        'p437: the misprinted damma on the ra is not followed'
      ),
      1895: ('٥- اللهم إني أسألك المعافاة.', 'p351 prints item ٥ bare'),
    };
    for (final MapEntry(key: id, value: (text, reason)) in cases.entries) {
      expect(await body(id), contains(text), reason: reason);
    }

    final before = await database.rawQuery('SELECT * FROM contents');
    await database.execute(
      File('../data_pipeline/migrations/166_harakat_from_book.sql')
          .readAsStringSync(),
    );
    expect(
      await database.rawQuery('SELECT * FROM contents'),
      before,
      reason: 'migration 166 is applied to the bundled database: running '
          'it again changes no row',
    );
  });
}
