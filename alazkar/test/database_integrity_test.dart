import 'dart:io';

import 'package:alazkar/src/core/helpers/db_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled azkar database satisfies content invariants', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);

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
           SELECT 1 FROM contents WHERE contents.titleId = titles.id
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
      SELECT COUNT(contents.id) AS count
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.name LIKE 'الورد %'
      GROUP BY titles.id
      ORDER BY titles."order"
    ''');
    final eveningSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
      WHERE titleId = 2
    ''');
    final morningSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
      WHERE titleId = 1
    ''');
    final nightSection = await database.rawQuery('''
      SELECT
        titles.name,
        COUNT(contents.id) AS count,
        MIN(contents."order") AS first,
        MAX(contents."order") AS last
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id = 3
      GROUP BY titles.id
    ''');
    final unprintedSections = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles WHERE id = 120) AS titles,
        (SELECT COUNT(*) FROM titles
         WHERE name IN ('ما يُقرأ في الليل', 'صلاة التسبيح')) AS named,
        (SELECT COUNT(*) FROM contents WHERE titleId = 120) AS contents
    ''');
    final khalaSections = await database.rawQuery('''
      SELECT titles."order", titles.name, COUNT(contents.id) AS count
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id IN (94, 95)
      GROUP BY titles.id
      ORDER BY titles."order"
    ''');
    final mosqueSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
      WHERE titleId = 8
    ''');
    final adhanListenerSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
      WHERE titleId = 9
    ''');
    final duaAlistiftahSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
      WHERE titleId = 10
    ''');
    final rukuAndRisingSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
      WHERE titleId = 11
    ''');
    final sujudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM(search LIKE '%واجعل من فوقي نورا%واجعل خلفي نورا%') AS complete_light_dua
      FROM contents
      WHERE titleId = 12
    ''');
    final betweenProstrationsSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM(search = 'اللهم اغفر لي وارحمني واجبرني وارفعني واهدني وعافني وارزقني') AS correct_between_dua,
        SUM(search LIKE '%فتبارك%') AS unprinted_tilawa_ending,
        SUM(search LIKE 'اللهم اكتب لي بها عندك أجرا وضع عني بها وزرا%') AS ordered_tilawa_dua
      FROM contents
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
      FROM contents
      WHERE titleId = 17
    ''');
    final tashahhudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 7 AND search LIKE 'التحيات لله الزاكيات لله%') AS fifth_tashahhud,
        SUM("order" = 9 AND search LIKE 'اللهم صل على محمد وعلى آل محمد%') AS first_salawat,
        SUM("order" = 15 AND search LIKE 'اللهم صل على محمد وعلى آل محمد وبارك%') AS seventh_salawat,
        SUM("order" = 4 AND count = 0 AND body = 'وفي روايةٍ: «عبدُه ورسولُه».') AS second_tashahhud_variant,
        SUM(count = 0) AS passages
      FROM contents
      WHERE titleId = 14
    ''');
    final postTashahhudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 13 AND search LIKE 'أحسن الكلام كلام الله وأحسن الهدي هدي محمد%') AS prophetic_guidance,
        SUM("order" = 15 AND search LIKE 'اللهم اغفر لي ما قدمت%') AS closing_dua,
        SUM(count = 0) AS passages
      FROM contents
      WHERE titleId = 15
    ''');
    final afterPrayerSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND search = 'يكبر الله عز وجل' AND count = 1) AS opening_takbir,
        SUM("order" = 15 AND search = 'سبحان الله والحمد لله والله أكبر' AND count = 33) AS combined_tasbih,
        SUM("order" BETWEEN 16 AND 20 AND body LIKE 'أو: %') AS tasbih_alternatives,
        SUM("order" = 18 AND count = 100 AND body LIKE '%(٢٥)%') AS fourth_formula,
        SUM("order" = 21 AND count = 0) AS fingers_note,
        SUM("order" = 24 AND count = 10 AND source LIKE '%صلاة الصبح%') AS morning_dhikr,
        SUM("order" = 27 AND count = 10 AND source LIKE '%صلاة المغرب%') AS sunset_dhikr,
        SUM("order" = 31 AND search LIKE 'سبحان الملك القدوس سبحان الملك القدوس سبحان الملك القدوس%') AS witr_dhikr,
        SUM(count = 0) AS passages,
        SUM("order" = 4 AND search LIKE 'أستغفر الله أستغفر الله اللهم%') AS two_istighfar,
        SUM("order" = 11 AND count = 1 AND hokm = ''
            AND search = 'اللهم لا تخزني يوم القيامة'
            AND source LIKE '%المسند (١٨٠٥٦)%') AS printed_dua,
        SUM("order" = 9 AND body LIKE '%-أو: %-%') AS dashed_alternative,
        SUM("order" = 6 AND body LIKE 'ويقرأ آية الكُرْسِيّ:%QuranText[(2:255:255)]') AS ayat_alkursi,
        SUM("order" = 7 AND body LIKE 'ويقرأ السُّوَرَ المعوِّذاتِ:%') AS mu_awwidhat,
        SUM("order" IN (25, 28) AND body LIKE 'ويقول ما تقدَّمَ في: (%'
            AND source LIKE '%حاشية: انظر (ص116).') AS earlier_pointer,
        SUM(hokm != '') AS graded,
        SUM(source LIKE '%(ص6_)%' OR source LIKE '%(ص7_)%') AS old_edition_pages
      FROM contents
      WHERE titleId = 16
    ''');
    final sleepSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 11 AND search LIKE '%والقرآن%' AND search NOT LIKE '%والفرقان%') AS corrected_revelation,
        SUM("order" = 13 AND search LIKE '%وثقل ميزاني%') AS unsupported_addition,
        SUM("order" BETWEEN 15 AND 23) AS tasbih_rows,
        SUM("order" = 15 AND count = 34) AS first_takbir,
        SUM("order" = 22 AND count = 34) AS third_tasbih,
        SUM("order" = 24 AND hokm = 'أثر' AND source LIKE 'موقوف على عائشة%') AS stopped_report
      FROM contents
      WHERE titleId = 18
    ''');
    final visionSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND search = 'الحمد لله') AS liked_vision,
        SUM("order" = 3 AND count = 3) AS left_breathing,
        SUM("order" = 4 AND count = 3) AS satan_refuge
      FROM contents
      WHERE titleId = 30
    ''');
    final nightAwakeningSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 3 AND search LIKE 'باسمك اللهم وضعت جنبي%') AS return_to_bed,
        SUM("order" = 4 AND search = '3190200') AS al_imran_ending
      FROM contents
      WHERE titleId = 31
    ''');
    final istikharaSection = await database.rawQuery('''
      SELECT COUNT(*) AS count, MIN("order") AS first, MAX("order") AS last
      FROM contents
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
      FROM contents
      WHERE titleId = 33
    ''');
    final fearSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND search = 'رب نجني من القوم الظلمين') AS qasas_dua
      FROM contents
      WHERE titleId = 34
    ''');
    final satanSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 4 AND count = 3) AS repeated_refuge,
        SUM("order" = 5 AND count = 3) AS repeated_curse
      FROM contents
      WHERE titleId = 35
    ''');
    final situationalSections = await database.rawQuery('''
      SELECT titles.id, titles.name, COUNT(contents.id) AS count
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id BETWEEN 36 AND 40
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final illnessAndDeathSections = await database.rawQuery('''
      SELECT titles.id, titles.name, COUNT(contents.id) AS count,
             MIN(contents."order") AS first, MAX(contents."order") AS last
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id BETWEEN 41 AND 47
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final illnessAndDeathRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 42 AND search LIKE 'اللهم أحيني ما كانت الحياة خيرا لي%') AS no_death_wish,
        SUM(titleId = 42 AND search LIKE 'اللهم ارزقني شهادة في سبيلك%') AS medina_death_dua,
        SUM(titleId = 43 AND search = 'اللهم اشف فلانا' AND count = 3) AS named_patient_dua,
        SUM(titleId = 44 AND body = 'QuranText[(1:1:7)]') AS fatiha_ruqya,
        SUM(titleId = 46 AND search = 'اللهم اجعله لنا سلفا وفرطا وأجرا') AS child_funeral_dua,
        SUM(titleId = 47 AND search = 'اللهم اجعله لنا سلفا وفرطا وأجرا') AS misplaced_child_dua,
        SUM(titleId = 47 AND source LIKE 'الصيغة % مما يقول زائر القبور.%') AS grave_visit_forms
      FROM contents
      WHERE titleId BETWEEN 41 AND 47
    ''');
    final fastingTravelAndPilgrimageSections = await database.rawQuery('''
      SELECT titles.id, COUNT(contents.id) AS count,
             MIN(contents."order") AS first, MAX(contents."order") AS last
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id BETWEEN 48 AND 60
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final fastingTravelAndPilgrimageRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 48 AND search = 'اللهم لك صمت وعلى رزقك أفطرت') AS second_iftar_dua,
        SUM(titleId = 50 AND search LIKE 'لبيك اللهم بحجة وعمرة%') AS qiran_intention,
        SUM(titleId = 50 AND search = 'لبيك ذا الفواضل') AS talbiya_variant,
        SUM(titleId = 52 AND search LIKE 'الله أكبر الله أكبر الله أكبر لا إله إلا الله وحده%هزم الأحزاب وحده') AS complete_safa_dhikr,
        SUM(titleId = 57 AND search LIKE 'اللهم صل على محمد%') AS unsupported_grave_dua,
        SUM(titleId = 60 AND body IN ('QuranText[(17:81:81)]', 'QuranText[(34:49:49)]')) AS misplaced_munkar_verses
      FROM contents
      WHERE titleId BETWEEN 48 AND 60
    ''');
    final foodMarriageAndMajlisSections = await database.rawQuery('''
      SELECT titles.id, COUNT(contents.id) AS count,
             MIN(contents."order") AS first, MAX(contents."order") AS last
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id IN (61, 62, 63, 64, 65, 68)
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final foodMarriageAndMajlisRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 61 AND search = 'اللهم إني أسألك من فضلك ورحمتك فإنه لا يملكها إلا أنت') AS guest_dua,
        SUM(titleId = 62 AND search = 'يرحمنا الله وإياكم ويغفر لنا ولكم') AS ibn_umar_reply,
        SUM(titleId = 63 AND search LIKE 'اللهم إني أسألك من خيرها%') AS wife_dua,
        SUM(titleId = 64 AND body = 'QuranText[(2:128:128)]') AS offspring_dua,
        SUM(titleId = 65 AND body = 'QuranText[(113:1:5),(114:1:6)]') AS severe_weather_surahs,
        SUM(titleId = 68 AND body = 'QuranText[(103:1:3)]') AS meeting_departure_surah
      FROM contents
      WHERE titleId IN (61, 62, 63, 64, 65, 68)
    ''');
    final foodMarriageAndMajlisJudgments = await database.rawQuery('''
      SELECT id, hokm
      FROM contents
      WHERE titleId IN (61, 62, 63, 64, 65, 68)
        AND hokm NOT IN ('', 'صحيح', 'حسن', 'ضعيف', 'موضوع', 'أثر')
    ''');
    final absoluteDhikrAndWirdSections = await database.rawQuery('''
      SELECT titles.id, COUNT(contents.id) AS count,
             MIN(contents."order") AS first, MAX(contents."order") AS last
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.id IN (66, 67, 69, 70, 77, 82,
                           83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
      GROUP BY titles.id
      ORDER BY titles.id
    ''');
    final absoluteDhikrAndWirdRegression = await database.rawQuery('''
      SELECT
        SUM(titleId = 70) AS salawat_forms,
        SUM(titleId = 70 AND search LIKE '%وعلى أهل بيته%') AS household_salawat,
        SUM(titleId = 92 AND "order" = 1) AS first_wird_starts_at_one,
        SUM(titleId = 91 AND "order" = 15) AS eleventh_wird_ends_at_fifteen
      FROM contents
      WHERE titleId IN (66, 67, 69, 70, 77, 82,
                         83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
    ''');
    final absoluteDhikrAndWirdJudgments = await database.rawQuery('''
      SELECT contents.id, contents.hokm
      FROM contents
      WHERE contents.titleId IN
            (66, 67, 69, 70, 77, 82,
              83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
        AND contents.hokm NOT IN
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
      FROM contents
      WHERE titleId BETWEEN 149 AND 157
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
        SUM(titleId = 149 AND body LIKE '%ولا يستطيعها البطلة%') AS quran,
        SUM(titleId = 150 AND body LIKE '%خواتيم سورة البقرة%') AS surahs,
        SUM(titleId = 151 AND body LIKE '%تكفى همك%') AS salawat,
        SUM(titleId = 152 AND body LIKE '%عدل أربع رقاب%') AS tahlil,
        SUM(titleId = 153 AND body LIKE '%سيد الاستغفار%') AS istighfar,
        SUM(titleId = 154 AND body LIKE '%الباقيات الصالحات%') AS baqiyat,
        SUM(titleId = 155 AND body LIKE '%لا حول في دفع شر%') AS meaning,
        SUM(titleId = 156 AND body LIKE '%كنز من كنوز الجنة%') AS hawqala,
        SUM(titleId = 157 AND body LIKE '%كلمة استعانة%') AS notice
      FROM contents
      WHERE titleId BETWEEN 149 AND 157
    ''');
    final unsupportedJudgments = await database.rawQuery('''
      SELECT id, hokm
      FROM contents
      WHERE titleId BETWEEN 33 AND 60
        AND hokm NOT IN ('', 'صحيح', 'حسن', 'ضعيف', 'موضوع', 'أثر')
    ''');
    final prayerPilot = await database.rawQuery('''
      SELECT
        (SELECT parentId FROM titles WHERE id = 10) AS opening_parent,
        (SELECT parentId FROM titles WHERE id = 16) AS after_prayer_parent,
        (SELECT nodeType FROM titles WHERE id = 96) AS prayer_type,
        (SELECT nodeType FROM titles WHERE id = 97) AS inside_prayer_type,
        (SELECT COUNT(*) FROM titles WHERE id = 98) AS introduction_titles,
        (SELECT COUNT(*) FROM contents WHERE id = 1006) AS introduction_rows,
        (SELECT source LIKE '%حاشية: هذا ما ورد من الأذكار في دعاء التوجُّه، فيستحب الجمع بينها كلُّها%'
         FROM contents WHERE id = 907) AS introduction_as_footnote
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
        SUM(titleId = 10 AND search = 'الله أكبر الله أكبر ذو الملكوت والجبروت والكبرياء والعظمة') AS two_takbirs_row,
        SUM(titleId = 10 AND count = 10) AS ten_times_cards,
        SUM(titleId = 10 AND count = 3) AS three_times_cards,
        SUM(titleId = 10 AND count = 0) AS opening_passages,
        SUM(titleId = 11 AND count = 0) AS ruku_passages,
        SUM(titleId = 12 AND count = 0) AS sujud_passages,
        SUM(titleId = 13 AND count = 0) AS tilawa_passages,
        SUM(titleId = 17 AND count = 0) AS qunut_passages,
        SUM(titleId = 14 AND count = 0) AS tashahhud_passages,
        SUM(titleId = 15 AND count = 0) AS after_tashahhud_passages
      FROM contents
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
        SUM(titleId = 33 AND count = 0 AND search = 'وليكن أكثر دعائه أن يقول') AS most_of_his_dua,
        SUM(titleId = 33 AND "order" = 6 AND body LIKE '﴿%ءَاتِنَا%﴾') AS verse_201,
        SUM(titleId = 33 AND source LIKE '%جَهْد البلاء: بفتح الجيم؛ كُلُّ ما%') AS jahd_footnote_in_book_order,
        SUM(titleId = 35 AND count = 0 AND search = 'ويقول') AS satan_says,
        SUM(titleId = 35 AND search LIKE '%إلا طارقا يطرق بخير يا رحمن')
          AS knocker_without_comma,
        SUM(titleId = 35 AND body LIKE '%طارقٍ يطرقُ، إلا طارقًا يطرقُ بخيرٍ يا رحمن'
            AND source LIKE '%تنوير الحوالك%') AS knocker_footnote,
        SUM(titleId = 36 AND body LIKE '%(أو: قَدَرُ اللهِ)%') AS or_alternative,
        SUM(titleId = 37 AND source LIKE '%غليظ الأرض%') AS hazn_footnote,
        SUM(titleId = 38 AND count = 0 AND search LIKE 'يمضي فيها متوكلا%') AS tira_instruction,
        SUM(titleId = 38 AND count = 1 AND source LIKE '%أنت سبحانك%') AS tira_footnote
      FROM contents
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
        (SELECT MAX(depth) FROM ancestry WHERE id BETWEEN 50 AND 59 OR id BETWEEN 128 AND 139) AS depth,
        (SELECT COUNT(*) FROM titles
         WHERE id BETWEEN 128 AND 133 AND nodeType = 'category') AS categories,
        (SELECT COUNT(*) FROM contents
         WHERE titleId BETWEEN 134 AND 139 AND count = 0) AS prose_rows,
        (SELECT parentId FROM titles WHERE id = 49) AS traveler_parent,
        (SELECT parentId FROM titles WHERE id = 50) AS ihram_parent,
        (SELECT parentId FROM titles WHERE id = 52) AS tawaf_parent,
        (SELECT parentId FROM titles WHERE id = 54) AS arafah_parent,
        (SELECT parentId FROM titles WHERE id = 57) AS prophet_grave_parent,
        (SELECT search LIKE '%للطواف ذكر خاص%'
         FROM contents WHERE id = 1050) AS tawaf_guidance
    ''');

    final guidanceNotes = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles
         WHERE id BETWEEN 122 AND 124 AND nodeType = 'category') AS categories,
        (SELECT COUNT(*) FROM contents
         WHERE titleId BETWEEN 125 AND 127 AND count = 0) AS prose_rows,
        (SELECT parentId FROM titles WHERE id = 18) AS sleep_parent,
        (SELECT parentId FROM titles WHERE id = 41) AS illness_parent,
        (SELECT parentId FROM titles WHERE id = 45) AS death_parent,
        (SELECT search LIKE '%يراجع الطبيب النفسي المختص%لا يتعارضان بل يتعاضدان%'
         FROM contents WHERE id = 1047) AS complete_health_guidance,
        (SELECT source FROM contents WHERE id = 1048) AS condolence_source
    ''');

    final prayerSupplementCategories = await database.rawQuery('''
      SELECT id, name, parentId, "order", nodeType
      FROM titles
      WHERE id BETWEEN 110 AND 113
      ORDER BY id
    ''');
    final prayerSupplementSections = await database.rawQuery('''
      SELECT titles.id, titles.name, titles.parentId,
             COUNT(contents.id) AS count,
             MIN(contents."order") AS first,
             MAX(contents."order") AS last
      FROM titles
      JOIN contents ON contents.titleId = titles.id
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
            AND body LIKE 'ثم يخطب الإمام الناس%') AS eclipse_sermon,
        SUM(titleId = 119 AND "order" <= 2 AND count != 0) AS counted_rain_guidance,
        SUM(titleId = 119 AND "order" = 1
            AND body LIKE 'يبدأ الإمام خطبته بالحمد%:' || char(10) || 'QuranText[(71:10:12)]')
          AS rain_opening,
        SUM(titleId = 119 AND "order" = 2
            AND body LIKE '%ويبالغ في رفع يديه%بالأدعية التالية:'
            AND source LIKE '%حاشية: انظر: دعاء الكرب%(ص١٤٢)%حاشية: ويجعل بطون كفيه%')
          AS rain_guidance_footnotes,
        SUM(titleId = 119 AND "order" = 3
            AND body LIKE 'QuranText[(1:2:4)]' || char(10) || 'لَا إِلَهَ إِلَّا اللهُ، يَفْعَلُ مَا يُرِيدُ، اللَّهُمَّ أَنْتَ اللهُ%')
          AS rain_first_supplication,
        SUM(titleId = 119 AND "order" = 4 AND count = 1
            AND search = 'اللهم اسقنا اللهم اسقنا اللهم اسقنا') AS rain_second_supplication,
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
      FROM contents
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
        (SELECT COUNT(*) FROM contents
         WHERE id BETWEEN 1007 AND 1013 AND count = 0) AS zero_count_prose,
        (SELECT COUNT(*) FROM contents
         WHERE id BETWEEN 1007 AND 1013) AS prose_count,
        (SELECT search LIKE '%فهذا مختصر%الأذكار والأدعية الصحيحة%'
         FROM contents WHERE id = 1008) AS introduction_searchable,
        (SELECT search LIKE '%كل يوم يعيشه المؤمن غنيمة%'
         FROM contents WHERE id = 1013) AS etiquette_searchable,
        (SELECT COUNT(*) FROM titles WHERE id IN (105, 107)) AS removed_sections
    ''');
    final absoluteDuaContext = await database.rawQuery('''
      SELECT
        (SELECT nodeType FROM titles WHERE id = 158) AS root_type,
        (SELECT COUNT(*) FROM titles WHERE parentId = 158) AS child_count,
        (SELECT COUNT(*) FROM contents
         WHERE titleId IN (159, 160) AND count = 0) AS zero_count,
        (SELECT COUNT(*) FROM contents WHERE titleId = 159) AS introduction_count,
        (SELECT COUNT(*) FROM contents WHERE titleId = 160) AS virtues_count,
        (SELECT search LIKE '%آخر ساعة بعد العصر%'
         FROM contents WHERE id = 1160) AS friday_time,
        (SELECT search LIKE '%أحد عشر وردا%'
         FROM contents WHERE id = 1175) AS eleven_wirds,
        (SELECT search LIKE '%الدعاء هو العبادة%'
         FROM contents WHERE id = 1178) AS worship_hadith,
        (SELECT search LIKE '%السادس القدرة%'
         FROM contents WHERE id = 1186) AS six_meanings
    ''');
    final absoluteDuaWirds = await database.rawQuery('''
      SELECT id, parentId, "order"
      FROM titles
      WHERE id IN (92, 82, 83, 84, 93, 86, 87, 88, 89, 90, 91)
      ORDER BY "order"
    ''');

    expect(await database.getVersion(), 149);
    expect(titleCount.single, {'count': 137});
    expect(foreignKeyViolations, isEmpty);
    expect(
        hierarchyColumns.map((row) => row['name']), ['nodeType', 'parentId']);
    expect(invalidHierarchyNodes, isEmpty);
    expect(duplicateSiblingOrder, isEmpty);
    expect(duplicateRootOrder, isEmpty);
    expect(prayerPilot.single, {
      'opening_parent': 97,
      'after_prayer_parent': 96,
      'prayer_type': 'category',
      'inside_prayer_type': 'category',
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
      'depth': 3,
      'categories': 6,
      'prose_rows': 8,
      'traveler_parent': 133,
      'ihram_parent': 129,
      'tawaf_parent': 130,
      'arafah_parent': 131,
      'prophet_grave_parent': 132,
      'tawaf_guidance': 1,
    });
    expect(guidanceNotes.single, {
      'categories': 3,
      'prose_rows': 3,
      'sleep_parent': 122,
      'illness_parent': 123,
      'death_parent': 124,
      'complete_health_guidance': 1,
      'condolence_source': 'تنبيه في ألفاظ التعزية. (ص107)',
    });
    expect(prayerSupplementCategories, [
      {
        'id': 110,
        'name': 'صلاة العيد',
        'parentId': 96,
        'order': 4,
        'nodeType': 'category',
      },
      {
        'id': 111,
        'name': 'صلاة الكسوف',
        'parentId': 96,
        'order': 5,
        'nodeType': 'category',
      },
      {
        'id': 112,
        'name': 'صلاة الاستسقاء',
        'parentId': 96,
        'order': 6,
        'nodeType': 'category',
      },
      {
        'id': 113,
        'name': 'صلوات متفرقة',
        'parentId': 96,
        'order': 7,
        'nodeType': 'category',
      },
    ]);
    expect(
      prayerSupplementSections.map((row) => row['count']),
      [8, 9, 2, 2, 3, 7, 5],
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
      'about_book_children': 4,
      'morning_evening_children': 4,
      'mosque_children': 2,
      'zero_count_prose': 6,
      'prose_count': 6,
      'introduction_searchable': 1,
      'etiquette_searchable': 1,
      'removed_sections': 0,
    });
    expect(absoluteDuaContext.single, {
      'root_type': 'category',
      'child_count': 13,
      'zero_count': 28,
      'introduction_count': 17,
      'virtues_count': 11,
      'friday_time': 1,
      'eleven_wirds': 1,
      'worship_hadith': 1,
      'six_meanings': 1,
    });
    expect(absoluteDuaWirds, [
      {'id': 92, 'parentId': 158, 'order': 3},
      {'id': 82, 'parentId': 158, 'order': 4},
      {'id': 83, 'parentId': 158, 'order': 5},
      {'id': 84, 'parentId': 158, 'order': 6},
      {'id': 93, 'parentId': 158, 'order': 7},
      {'id': 86, 'parentId': 158, 'order': 8},
      {'id': 87, 'parentId': 158, 'order': 9},
      {'id': 88, 'parentId': 158, 'order': 10},
      {'id': 89, 'parentId': 158, 'order': 11},
      {'id': 90, 'parentId': 158, 'order': 12},
      {'id': 91, 'parentId': 158, 'order': 13},
    ]);
    expect(
      wirdCounts.map((row) => row['count']),
      [13, 9, 11, 13, 15, 14, 10, 12, 6, 10, 15],
    );
    expect(morningSection.single, {'count': 34, 'first': 1, 'last': 34});
    expect(eveningSection.single, {'count': 23, 'first': 1, 'last': 23});
    expect(nightSection.single, {
      'name': 'ما يُقال في الليل (وأوله بعد المغرب)',
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
        'order': 4,
        'name': 'ما يقول إذا أراد دخول الخلاء',
        'count': 2,
      },
      {'order': 5, 'name': 'ما يقول إذا خرج من الخلاء', 'count': 1},
    ]);
    expect(mosqueSection.single, {'count': 13, 'first': 1, 'last': 13});
    expect(adhanListenerSection.single, {'count': 13, 'first': 1, 'last': 13});
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
      "SELECT 1 FROM contents WHERE titleId=11 AND body LIKE '%وعليك توكلت%دمي ولحمي%'",
    );
    expect(ruku8thFormula, isNotEmpty,
        reason: 'Missing 8th independent ruku formula');

    final hamdAlternatives = await database.rawQuery(
      "SELECT search FROM contents WHERE titleId=11 AND search IN "
      "('ربنا لك الحمد أو ربنا ولك الحمد', 'أو اللهم ربنا ولك الحمد')",
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
      {'id': 13, 'order': 4, 'name': 'ما يقول بين السجدتين وسجدة التلاوة'},
      {'id': 17, 'order': 5, 'name': 'قنوت الوتر في رمضان وغيره'},
      {'id': 14, 'order': 6, 'name': 'التشهد والصلاة على النبي بعد التشهد'},
      {'id': 15, 'order': 7, 'name': 'الدعاء بعد التشهد الأخير'},
      {'id': 16, 'order': 3, 'name': 'ما يقول بعد الصلاة'},
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
    expect(sleepSection.single, {
      'count': 26,
      'first': 1,
      'last': 26,
      'corrected_revelation': 1,
      'unsupported_addition': 0,
      'tasbih_rows': 9,
      'first_takbir': 1,
      'third_tasbih': 1,
      'stopped_report': 1,
    });
    expect(visionSection.single, {
      'count': 7,
      'first': 1,
      'last': 7,
      'liked_vision': 1,
      'left_breathing': 1,
      'satan_refuge': 1,
    });
    expect(nightAwakeningSection.single, {
      'count': 4,
      'first': 1,
      'last': 4,
      'return_to_bed': 1,
      'al_imran_ending': 1,
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
      {'id': 36, 'name': 'ما يقول إذا غلبه أمر', 'count': 1},
      {'id': 37, 'name': 'ما يقول إذا استصعب عليه أمر', 'count': 1},
      {
        'id': 38,
        'name': 'ما يقول مَن رَدَّته الطِّيَرَةُ عن حاجته',
        'count': 2
      },
      {
        'id': 39,
        'name': 'ما يقول إذا أصابته نكبة قليلة أو كثيرة',
        'count': 1,
      },
      {'id': 40, 'name': 'ما يقول إذا كان عليه دَين عجز عنه', 'count': 1},
    ]);
    expect(illnessAndDeathSections, [
      {'id': 41, 'name': 'أذكار المرض', 'count': 6, 'first': 1, 'last': 6},
      {
        'id': 42,
        'name': 'ما يقوله المريض',
        'count': 10,
        'first': 1,
        'last': 10
      },
      {
        'id': 43,
        'name': 'ما يقال عند المريض، ويُقرأ عليه',
        'count': 7,
        'first': 1,
        'last': 7,
      },
      {'id': 44, 'name': 'رقية المريض', 'count': 5, 'first': 1, 'last': 5},
      {'id': 45, 'name': 'أذكار الموت', 'count': 13, 'first': 1, 'last': 13},
      {
        'id': 46,
        'name': 'أذكار الصلاة على الميت',
        'count': 8,
        'first': 1,
        'last': 8,
      },
      {
        'id': 47,
        'name': 'ما يقول في الجنازة والدفن والقبور',
        'count': 8,
        'first': 1,
        'last': 8,
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
      [6, 24, 11, 3, 11, 4, 2, 3, 4, 3, 4, 4, 15],
    );
    expect(
      fastingTravelAndPilgrimageSections
          .every((row) => row['first'] == 1 && row['last'] == row['count']),
      isTrue,
    );
    expect(fastingTravelAndPilgrimageRegression.single, {
      'second_iftar_dua': 1,
      'qiran_intention': 1,
      'talbiya_variant': 1,
      'complete_safa_dhikr': 1,
      'unsupported_grave_dua': 0,
      'misplaced_munkar_verses': 0,
    });
    expect(
      foodMarriageAndMajlisSections.map((row) => row['count']),
      [14, 9, 12, 5, 9, 4],
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
      'meeting_departure_surah': 1,
    });
    expect(foodMarriageAndMajlisJudgments, isEmpty);
    expect(
      absoluteDhikrAndWirdSections.map((row) => row['count']),
      [
        21,
        43,
        5,
        7,
        1,
        9,
        11,
        13,
        14,
        10,
        12,
        6,
        10,
        15,
        13,
        15,
      ],
    );
    expect(
      absoluteDhikrAndWirdSections.every(
        (row) => row['first'] == 1 && row['last'] == row['count'],
      ),
      isTrue,
    );
    expect(absoluteDhikrAndWirdRegression.single, {
      'salawat_forms': 7,
      'household_salawat': 1,
      'first_wird_starts_at_one': 1,
      'eleventh_wird_ends_at_fifteen': 1,
    });
    expect(absoluteDhikrAndWirdJudgments, isEmpty);
    expect(absoluteDhikrHierarchy.single, {'nodes': 22, 'max_depth': 2});
    expect(
      absoluteDhikrContent,
      [
        {'titleId': 149, 'count': 12, 'zero_count': 12, 'first': 1, 'last': 12},
        {'titleId': 150, 'count': 18, 'zero_count': 18, 'first': 1, 'last': 18},
        {'titleId': 151, 'count': 21, 'zero_count': 21, 'first': 1, 'last': 21},
        {'titleId': 152, 'count': 9, 'zero_count': 9, 'first': 1, 'last': 9},
        {'titleId': 153, 'count': 7, 'zero_count': 7, 'first': 1, 'last': 7},
        {'titleId': 154, 'count': 17, 'zero_count': 17, 'first': 1, 'last': 17},
        {'titleId': 155, 'count': 8, 'zero_count': 8, 'first': 1, 'last': 8},
        {'titleId': 156, 'count': 7, 'zero_count': 7, 'first': 1, 'last': 7},
        {'titleId': 157, 'count': 2, 'zero_count': 2, 'first': 1, 'last': 2},
      ],
    );
    expect(absoluteDhikrParents, [
      {'id': 69, 'parentId': 143, 'order': 2},
      {'id': 70, 'parentId': 142, 'order': 3},
      {'id': 77, 'parentId': 146, 'order': 4},
    ]);
    expect(absoluteDhikrSamples.single, {
      'quran': 1,
      'surahs': 1,
      'salawat': 1,
      'tahlil': 1,
      'istighfar': 1,
      'baqiyat': 4,
      'meaning': 1,
      'hawqala': 2,
      'notice': 1,
    });
    expect(unsupportedJudgments, isEmpty);
  });

  test('bundled azkar database follows the book (quality gate #52)', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);

    Future<List<Object?>> childIds(String parentFilter) async {
      final rows = await database.rawQuery('''
        SELECT id FROM titles WHERE $parentFilter ORDER BY "order"
      ''');
      return rows.map((row) => row['id']).toList();
    }

    final removedSections = await database.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM titles WHERE id IN (71, 72, 73, 74, 75, 76, 78, 79, 80)) AS titles,
        (SELECT COUNT(*) FROM contents WHERE titleId IN (71, 72, 73, 74, 75, 76, 78, 79, 80))
          AS contents
    ''');
    final editorialSuffixes = await database.rawQuery('''
      SELECT id FROM titles WHERE name LIKE '%تنظيمي%'
    ''');
    final salawatIntroduction = await database.rawQuery('''
      SELECT id FROM contents WHERE titleId = 161 ORDER BY "order"
    ''');
    final salawatIntroductionText = await database.rawQuery('''
      SELECT
        SUM(body LIKE 'ذكر الواحدي عن الأصمعي%') AS mahdi_report,
        SUM(body LIKE 'وقال سهل بن عبد الله%') AS sahl,
        SUM(body LIKE 'وقال العز بن عبد السلام%') AS izz,
        SUM(body LIKE 'وقال ابن قيم الجوزية%') AS ibn_qayyim,
        SUM(body LIKE 'ثم قال رحمه الله%') AS ibn_qayyim_follow_up,
        SUM(count = 0 AND hokm = '') AS prose
      FROM contents
      WHERE titleId = 161
    ''');
    final paraphrasedSummaries = await database.rawQuery('''
      SELECT id FROM contents WHERE body LIKE '%وقد ذكر الكتاب%'
    ''');
    final salawatVirtuesOpening = await database.rawQuery('''
      SELECT id FROM contents WHERE titleId = 151 AND "order" = 1
    ''');

    expect(removedSections.single, {'titles': 0, 'contents': 0});
    expect(editorialSuffixes, isEmpty);
    expect(
      await childIds('parentId IS NULL'),
      [
        99, 100, 4, 94, 95, 5, 6, 7, 108, 9, 114, 96, 122, 162, 123, 124, //
        48, 128, 133, 60, 61, 62, 63, 64, 65, 163, 68, 140, 158,
      ],
      reason: 'root order follows the book index (pp. 228-239)',
    );
    expect(await childIds('parentId = 113'), [121]);
    expect(await childIds('parentId = 100'), [1, 2, 3, 106],
        reason: 'p50 prints «ثالثًا: ما يُقال في الليل» in the morning and '
            'evening chapter, before its etiquette (index p446)');
    expect(
      await childIds('parentId = 162'),
      [32, 33, 34, 35, 36, 37, 38, 39, 40],
    );
    expect(await childIds('parentId = 163'), [66, 67]);
    expect(await childIds('parentId = 142'), [161, 151, 70]);
    expect(
      salawatIntroduction.map((row) => row['id']),
      [1089, 1187, 1188, 1189, 1190, 1191],
    );
    expect(salawatIntroductionText.single, {
      'mahdi_report': 1,
      'sahl': 1,
      'izz': 1,
      'ibn_qayyim': 1,
      'ibn_qayyim_follow_up': 1,
      'prose': 6,
    });
    expect(paraphrasedSummaries, isEmpty);
    expect(salawatVirtuesOpening.single, {'id': 1192});

    final footnotesAsVirtues = await database.rawQuery('''
      SELECT id FROM contents WHERE id > 1006 AND TRIM(fadl) <> ''
    ''');
    final editorialNotes = await database.rawQuery('''
      SELECT id FROM contents
      WHERE body || source || fadl LIKE '%نقل المؤلف%'
         OR body || source || fadl LIKE '%نقل الكتاب%'
         OR body || source || fadl LIKE '%ذكر الكتاب%'
    ''');
    final ubayyComment = await database.rawQuery('''
      SELECT id FROM contents
      WHERE titleId = 151
        AND "order" = (SELECT "order" + 1 FROM contents WHERE id = 1094)
    ''');

    expect(footnotesAsVirtues, isEmpty,
        reason: 'book footnotes belong in the source as «حاشية» (#81)');
    expect(editorialNotes, isEmpty);
    expect(ubayyComment.single, {'id': 1193});

    final virtueRecords = await database.rawQuery('''
      SELECT id FROM contents WHERE TRIM(fadl) <> '' ORDER BY id
    ''');
    expect(
      virtueRecords.map((row) => row['id']),
      [274, 277, 334, 906],
      reason: 'a virtue line shows only what the book prints in its main '
          'text under the zikr (p104, p105, p123, p47); excerpts of the '
          'takhrij hadiths stay whole in the source',
    );

    final alternatives = await database.rawQuery('''
      SELECT id FROM contents
      WHERE id IN (21, 49) AND count = 100 AND body LIKE '%' || char(10) || 'أو: %'
    ''');
    final separateAlternatives = await database.rawQuery('''
      SELECT id FROM contents WHERE id IN (22, 50)
    ''');
    final tawbah129 = await database.rawQuery('''
      SELECT id FROM contents
      WHERE id IN (18, 46, 414) AND body LIKE '﴿ حَسۡبِيَ%' AND body NOT LIKE '%QuranText%'
    ''');
    final appLabels = await database.rawQuery('''
      SELECT COUNT(*) AS count FROM contents WHERE hokm = 'قرآني'
    ''');
    final morningClosing = await database.rawQuery('''
      SELECT id, count FROM contents
      WHERE titleId = 1 AND "order" IN (32, 33, 34) ORDER BY "order"
    ''');
    final morningNote = await database.rawQuery('''
      SELECT body FROM contents WHERE id = 1194
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
      SELECT id FROM contents
      WHERE id IN (222, 227, 236, 253, 273, 304, 305, 306, 327, 328, 337, 355, 356,
                   398, 399, 412, 413, 415, 416, 417, 419, 420, 421, 422, 423,
                   425, 426, 427, 428, 429, 430, 431, 432, 454, 468, 607, 608,
                   609, 610, 626, 627, 629, 630, 647, 648, 649, 686, 687, 688,
                   689, 690, 708, 709, 710, 711, 725, 747, 748, 827, 828, 829,
                   830, 831, 833, 846, 847, 1023, 1227, 1249)
        AND body LIKE '%﴿ %﴾%' AND body NOT LIKE '%QuranText%'
    ''');
    final supplicationsInTheBooksWords = await database.rawQuery('''
      SELECT id FROM contents
      WHERE id IN (251, 260) AND body NOT LIKE '%QuranText%'
        AND body NOT LIKE '%﴿%'
    ''');
    final secondRabbana = await database.rawQuery('''
      SELECT id FROM contents WHERE id = 609 AND search = 'ربنا أفرغ علينا صبرا وتوفنا مسلمين'
    ''');
    final fatihaVerses = await database.rawQuery('''
      SELECT id FROM contents WHERE id = 1037 AND body LIKE 'QuranText[(1:2:4)]%'
    ''');
    final ridingVerseOnce = await database.rawQuery('''
      SELECT id FROM contents WHERE id = 872 AND body LIKE '%QuranText%'
    ''');
    expect(quotedVerses.length, 69,
        reason: 'the book quotes these verses in part; the app shows the same '
            'words, not the whole verse (#116)');
    expect(supplicationsInTheBooksWords.length, 2,
        reason: 'pp97, 99 write these as supplications, not as verses; p142 '
            'prints «ربنا آتنا» as the verse (#177)');
    expect(secondRabbana.single, {'id': 609},
        reason: 'p207 quotes al-Aʿraf 126 from the second «ربنا»');
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
      FROM contents WHERE id = 225
    ''');
    final recordsWithFootnotes = await database.rawQuery('''
      SELECT COUNT(*) AS count FROM contents WHERE source LIKE '%حاشية:%'
    ''');
    expect(distressFootnotes.single, {'notes': 4},
        reason: 'p. 90 footnotes on «جهد البلاء» (#87)');
    expect(recordsWithFootnotes.single, {'count': 132},
        reason: 'pp29-68 (#171), pp91-115 (#174), pp116-129 (#175) and '
            'pp140-149 (#177) print their footnotes');
  });

  test('the closing date of the introduction is a small line of its own (#140)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);

    final introduction = await database.rawQuery('''
      SELECT id, "order", count, style, body, source FROM contents
      WHERE titleId = 102 ORDER BY "order"
    ''');
    final styled = await database.rawQuery('''
      SELECT id FROM contents WHERE style <> ''
    ''');

    expect(introduction.map((row) => row['id']), [1008, 1204]);
    final text = introduction[0];
    final date = introduction[1];
    expect(text['style'], '');
    expect(text['body']! as String, isNot(contains('الإسكندرية')));
    expect(text['body']! as String, endsWith('وعلى آله وصحبه أجمعين.'));
    expect(date['order'], 2);
    expect(date['count'], 0);
    expect(date['style'], 'small');
    expect(
      date['body'],
      'الإسكندرية في الجمعة\n'
      '6 من ذي القعدة 1407هـ\n'
      'الموافق 3 من يوليو 1987م',
    );
    expect(date['source'], 'المقدمة. (ص9)');
    expect(styled.map((row) => row['id']), [1204]);
  });

  test('morning and evening adhkar follow pages 29-68 of the book (#171)',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(database.close);

    Future<Map<String, Object?>> row(int id) async => (await database.rawQuery(
          'SELECT body, count, source, hokm FROM contents WHERE id = ?',
          [id],
        ))
            .single;

    final removedTitles = await database.rawQuery('''
      SELECT id FROM titles WHERE id IN (105, 107)
    ''');
    final foreignToEvening = await database.rawQuery('''
      SELECT id FROM contents
      WHERE titleId = 2
        AND (search LIKE 'أمسينا على فطرة%' OR search LIKE 'رضيت بالله%'
             OR search LIKE 'بسم الله الذي%' OR search LIKE 'باسم الله الذي%')
    ''');
    final prayerOnTheProphet = await database.rawQuery('''
      SELECT id FROM contents
      WHERE titleId IN (1, 2) AND search LIKE '%صل على محمد وعلى آل محمد%'
    ''');
    final adab = await database.rawQuery('''
      SELECT id, count, hokm, substr(body, 1, 6) AS start FROM contents
      WHERE titleId = 106 ORDER BY "order"
    ''');
    final morningIntro = await database.rawQuery('''
      SELECT body FROM contents WHERE titleId = 1 AND "order" <= 3
      ORDER BY "order"
    ''');
    final night = await database.rawQuery('''
      SELECT id, count FROM contents WHERE titleId = 3 ORDER BY "order"
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
        'قال الله تعالى:\nQuranText[(33:41:42)]',
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
    for (final id in [17, 45]) {
      final surahs = await row(id);
      expect(surahs['body'], 'سُوَر: (الإخلاص)، و(الفلق)، و(الناس)',
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
}
