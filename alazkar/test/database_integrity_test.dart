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
        SUM(search = 'اللهم اغفر لي وارحمني وعافني واهدني وارزقني') AS correct_between_dua,
        SUM(search LIKE '%فتبارك الله أحسن الخالقين') AS complete_tilawa_dua,
        SUM(search LIKE 'اللهم احطط عني بها وزرا واكتب لي بها أجرا%') AS ordered_tilawa_dua
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
        SUM(search LIKE 'اللهم قاتل الكفرة%') AS combat_dua,
        SUM(search LIKE 'اللهم إياك نعبد%لمن عاديت ملحق') AS closing_dua,
        SUM(search LIKE 'يشرع القنوت في الصلوات الخمس للنازلة%') AS calamity_guidance
      FROM contents
      WHERE titleId = 17
    ''');
    final tashahhudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 5 AND search LIKE 'التحيات لله الزاكيات لله%') AS fifth_tashahhud,
        SUM("order" = 6 AND search LIKE 'اللهم صل على محمد وعلى آل محمد%') AS first_salawat,
        SUM("order" = 12 AND search LIKE 'اللهم صل على محمد وعلى آل محمد وبارك%') AS seventh_salawat
      FROM contents
      WHERE titleId = 14
    ''');
    final postTashahhudSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 11 AND search LIKE 'أحسن الكلام كلام الله وأحسن الهدي هدي محمد%') AS prophetic_guidance,
        SUM("order" = 12 AND search LIKE 'اللهم اغفر لي ما قدمت%') AS closing_dua
      FROM contents
      WHERE titleId = 15
    ''');
    final afterPrayerSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 1 AND search = 'الله أكبر' AND count = 1) AS opening_takbir,
        SUM("order" = 12 AND search = 'سبحان الله والحمد لله والله أكبر' AND count = 33) AS combined_tasbih,
        SUM("order" = 22 AND search = 'لا إله إلا الله' AND count = 25) AS fourth_formula_tahlil,
        SUM("order" = 31 AND count = 10 AND source LIKE '%صلاة الصبح%') AS morning_dhikr,
        SUM("order" = 32 AND count = 10 AND source LIKE '%صلاة المغرب%') AS sunset_dhikr,
        SUM("order" = 33 AND search = 'سبحان الملك القدوس' AND count = 3) AS witr_dhikr,
        SUM(search = 'اللهم لا تخزني يوم القيامة') AS unsupported_dua
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
        AND source LIKE '%ص88–89%'
    ''');
    final distressSection = await database.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN("order") AS first,
        MAX("order") AS last,
        SUM("order" = 9 AND search LIKE '%ابن أمتك في قبضتك ناصيتي بيدك%') AS complete_distress_dua
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
        SUM("order" = 3 AND count = 3) AS repeated_refuge,
        SUM("order" = 4 AND count = 3) AS repeated_curse
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
      WHERE titles.id IN (66, 67, 69, 70, 73, 77, 82,
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
      WHERE titleId IN (66, 67, 69, 70, 73, 77, 82,
                         83, 84, 86, 87, 88, 89, 90, 91, 92, 93)
    ''');
    final absoluteDhikrAndWirdJudgments = await database.rawQuery('''
      SELECT contents.id, contents.hokm
      FROM contents
      WHERE contents.titleId IN
            (66, 67, 69, 70, 73, 77, 82,
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
        (SELECT count FROM contents WHERE id = 1006) AS introduction_count,
        (SELECT hokm FROM contents WHERE id = 1006) AS introduction_judgment,
        (SELECT source FROM contents WHERE id = 1006) AS introduction_source,
        (SELECT body FROM contents WHERE id = 1006) AS introduction_body,
        (SELECT search LIKE '%فيستحب الجمع بينها كلها%'
         FROM contents WHERE id = 1006) AS introduction_searchable
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
        SUM(titleId = 115 AND "order" <= 2 AND count != 0) AS counted_eid_guidance,
        SUM(titleId = 115 AND "order" BETWEEN 3 AND 7 AND hokm = 'أثر') AS eid_reports,
        SUM(titleId = 119 AND "order" <= 2 AND count != 0) AS counted_rain_guidance,
        SUM(titleId = 120 AND "order" = 2 AND source LIKE 'حاشية صلاة التسبيح%') AS tasbih_note,
        SUM(titleId = 121 AND "order" = 2 AND count = 0) AS repentance_note
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
         WHERE id BETWEEN 1007 AND 1014 AND count = 0) AS zero_count_prose,
        (SELECT COUNT(*) FROM contents
         WHERE id BETWEEN 1007 AND 1014) AS prose_count,
        (SELECT search LIKE '%فهذا مختصر%الأذكار والأدعية الصحيحة%'
         FROM contents WHERE id = 1008) AS introduction_searchable,
        (SELECT search LIKE '%كل يوم يعيشه المؤمن غنيمة%'
         FROM contents WHERE id = 1013) AS etiquette_searchable,
        (SELECT hokm FROM contents WHERE id = 1014) AS salaf_judgment
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

    expect(await database.getVersion(), 141);
    expect(titleCount.single, {'count': 142});
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
      'introduction_count': 0,
      'introduction_judgment': '',
      'introduction_source': 'تمهيد أذكار الصلاة. (ص49)',
      'introduction_body':
          'هذا ما ورد من الأذكار في دعاء التوجه، فيستحب الجمع بينها كلها لمن صلى منفردًا، وللإمام إذا أذن له المأمومون، فأما إذا لم يأذنوا له فلا يطول عليهم، بل يقتصر على بعض ذلك.',
      'introduction_searchable': 1,
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
      [8, 7, 2, 1, 2, 7, 2, 2],
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
      'counted_rain_guidance': 0,
      'tasbih_note': 1,
      'repentance_note': 1,
    });
    expect(bookContext.single, {
      'about_book_type': 'category',
      'morning_evening_type': 'category',
      'mosque_type': 'category',
      'morning_parent': 100,
      'evening_parent': 100,
      'mosque_parent': 108,
      'about_book_children': 4,
      'morning_evening_children': 5,
      'mosque_children': 2,
      'zero_count_prose': 8,
      'prose_count': 8,
      'introduction_searchable': 1,
      'etiquette_searchable': 1,
      'salaf_judgment': '',
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
    expect(morningSection.single, {'count': 28, 'first': 1, 'last': 28});
    expect(eveningSection.single, {'count': 25, 'first': 1, 'last': 25});
    expect(nightSection.single, {
      'name': 'ما يُقرأ في الليل',
      'count': 6,
      'first': 1,
      'last': 6,
    });
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
      {'count': 13, 'first': 1, 'last': 13},
      reason: 'dua_alistiftah (titleId=10) must have 13 records in order 1..13 '
          'after rebuild from PDF pp. 49-53 (issue #17): '
          '5 regular + 5 tahajjud + 3 taawwudh',
    );
    expect(
      rukuAndRisingSection.single,
      {'count': 16, 'first': 1, 'last': 16},
      reason: 'azkar_alkuru (titleId=11) must have 16 records in order 1..16 '
          'after rebuild from PDF pp. 54-56 (issue #19)',
    );

    // Verify presence of specific formulas as requested in #19
    final ruku8thFormula = await database.rawQuery(
      "SELECT 1 FROM contents WHERE titleId=11 AND body LIKE '%وعليك توكلت%دمي ولحمي%'",
    );
    expect(ruku8thFormula, isNotEmpty,
        reason: 'Missing 8th independent ruku formula');

    final hamdAlternatives = await database.rawQuery(
      "SELECT body FROM contents WHERE titleId=11 AND body IN ('رَبَّنا لك الحمدُ.', 'ربنا ولك الحمدُ.')",
    );
    expect(hamdAlternatives.length, 2,
        reason: 'Missing explicit Hamd alternatives');
    expect(sujudSection.single, {
      'count': 13,
      'first': 1,
      'last': 13,
      'complete_light_dua': 1,
    });
    expect(betweenProstrationsSection.single, {
      'count': 4,
      'first': 1,
      'last': 4,
      'correct_between_dua': 1,
      'complete_tilawa_dua': 1,
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
      'count': 4,
      'first': 1,
      'last': 4,
      'combat_dua': 1,
      'closing_dua': 1,
      'calamity_guidance': 1,
    });
    expect(tashahhudSection.single, {
      'count': 12,
      'first': 1,
      'last': 12,
      'fifth_tashahhud': 1,
      'first_salawat': 1,
      'seventh_salawat': 1,
    });
    expect(postTashahhudSection.single, {
      'count': 12,
      'first': 1,
      'last': 12,
      'prophetic_guidance': 1,
      'closing_dua': 1,
    });
    expect(afterPrayerSection.single, {
      'count': 34,
      'first': 1,
      'last': 34,
      'opening_takbir': 1,
      'combined_tasbih': 1,
      'fourth_formula_tahlil': 1,
      'morning_dhikr': 1,
      'sunset_dhikr': 1,
      'witr_dhikr': 1,
      'unsupported_dua': 0,
    });
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
    expect(istikharaSection.single, {'count': 1, 'first': 1, 'last': 1});
    expect(distressSection.single, {
      'count': 9,
      'first': 1,
      'last': 9,
      'complete_distress_dua': 1,
    });
    expect(fearSection.single, {
      'count': 9,
      'first': 1,
      'last': 9,
      'qasas_dua': 1,
    });
    expect(satanSection.single, {
      'count': 6,
      'first': 1,
      'last': 6,
      'repeated_refuge': 1,
      'repeated_curse': 1,
    });
    expect(situationalSections, [
      {'id': 36, 'name': 'ما يقول إذا غلبه أمر', 'count': 1},
      {'id': 37, 'name': 'ما يقول إذا استصعب عليه أمر', 'count': 1},
      {'id': 38, 'name': 'ما يقول إذا تطيَّر بشيء', 'count': 1},
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
        3,
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
    expect(absoluteDhikrHierarchy.single, {'nodes': 23, 'max_depth': 2});
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
      {'id': 73, 'parentId': 145, 'order': 2},
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
        (SELECT COUNT(*) FROM titles WHERE id IN (71, 72, 74, 75, 76, 78, 79, 80)) AS titles,
        (SELECT COUNT(*) FROM contents WHERE titleId IN (71, 72, 74, 75, 76, 78, 79, 80))
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
    expect(await childIds('parentId = 113'), [120, 121, 3]);
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
      WHERE titleId = 1 AND "order" IN (27, 28) ORDER BY "order"
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
      WHERE id IN (227, 236, 253, 273, 304, 305, 306, 327, 328, 337, 355, 356,
                   398, 399, 412, 413, 415, 416, 417, 419, 420, 421, 422, 423,
                   425, 426, 427, 428, 429, 430, 431, 432, 454, 468, 607, 608,
                   609, 610, 626, 627, 629, 630, 647, 648, 649, 686, 687, 688,
                   689, 690, 708, 709, 710, 711, 725, 747, 748, 827, 828, 829,
                   830, 831, 833, 846, 847, 1013, 1023)
        AND body LIKE '%﴿ %﴾%' AND body NOT LIKE '%QuranText%'
    ''');
    final supplicationsInTheBooksWords = await database.rawQuery('''
      SELECT id FROM contents
      WHERE id IN (222, 251, 260) AND body NOT LIKE '%QuranText%'
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
    expect(quotedVerses.length, 67,
        reason: 'the book quotes these verses in part; the app shows the same '
            'words, not the whole verse (#116)');
    expect(supplicationsInTheBooksWords.length, 3,
        reason: 'pp89, 97, 99 write these as supplications, not as verses');
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
          {'id': 28, 'count': 1},
        ],
        reason: 'the «تنبيه» is read before the expiation of the gathering');
    expect(
      morningNote.single['body']! as String,
      allOf(startsWith('تنبيه:'), endsWith('ختمه بكفارة المجلس:')),
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
    expect(recordsWithFootnotes.single, {'count': 108});
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
