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
    final wirdCounts = await database.rawQuery('''
      SELECT COUNT(contents.id) AS count
      FROM titles
      JOIN contents ON contents.titleId = titles.id
      WHERE titles.name LIKE 'الورد %'
      GROUP BY titles.id
      ORDER BY titles."order"
    ''');
    final unclassifiedWirds = await database.rawQuery('''
      SELECT contents.id
      FROM contents
      JOIN titles ON titles.id = contents.titleId
      WHERE titles.name LIKE 'الورد %'
        AND TRIM(COALESCE(contents.hokm, '')) = ''
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
      WHERE titles."order" IN (5, 6)
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
      ORDER BY "order"
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

    expect(await database.getVersion(), 116);
    expect(titleCount.single, {'count': 82});
    expect(foreignKeyViolations, isEmpty);
    expect(
      wirdCounts.map((row) => row['count']),
      [13, 9, 11, 13, 15, 14, 10, 12, 6, 10, 15],
    );
    expect(unclassifiedWirds, isEmpty);
    expect(morningSection.single, {'count': 28, 'first': 1, 'last': 28});
    expect(eveningSection.single, {'count': 26, 'first': 1, 'last': 26});
    expect(nightSection.single, {
      'name': 'ما يُقرأ في الليل',
      'count': 6,
      'first': 1,
      'last': 6,
    });
    expect(khalaSections, [
      {
        'order': 5,
        'name': 'ما يقول إذا أراد دخول الخلاء',
        'count': 2,
      },
      {'order': 6, 'name': 'ما يقول إذا خرج من الخلاء', 'count': 1},
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
      {'id': 13, 'order': 15, 'name': 'ما يقول بين السجدتين وسجدة التلاوة'},
      {'id': 17, 'order': 16, 'name': 'قنوت الوتر في رمضان وغيره'},
      {'id': 14, 'order': 17, 'name': 'التشهد والصلاة على النبي بعد التشهد'},
      {'id': 15, 'order': 18, 'name': 'الدعاء بعد التشهد الأخير'},
      {'id': 16, 'order': 19, 'name': 'ما يقول بعد الصلاة'},
    ]);
    expect(qunutSection.single, {
      'count': 4,
      'first': 1,
      'last': 4,
      'combat_dua': 1,
      'closing_dua': 1,
      'calamity_guidance': 1,
    });
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
