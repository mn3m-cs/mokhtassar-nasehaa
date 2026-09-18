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

    expect(await database.getVersion(), 111);
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
    expect(adhanListenerSection.single, {'count': 7, 'first': 1, 'last': 7});
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
