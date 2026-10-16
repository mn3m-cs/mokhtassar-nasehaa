import 'dart:io';

import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/models/progress_keeping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late List<ZikrTitle> titles;

  setUpAll(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    titles = (await database.query('titles')).map(ZikrTitle.fromMap).toList();
  });

  tearDownAll(() => database.close());

  String nameOf(int id) => titles.firstWhere((title) => title.id == id).name;

  ProgressKeeping keepingOf(int id) => progressKeepingOf(
        titles.firstWhere((title) => title.id == id),
        titles,
      );

  test('the fixed ids still name the sections and categories they stand for',
      () {
    expect(kDailyTitleIds.map(nameOf).toSet(),
        {'أذكار الصباح', 'أذكار المساء', 'أذكار النوم'});
    expect(kKeptCategoryIds.map(nameOf).toSet(),
        {'حول الكتاب', 'الأذكار المطلقة', 'الأدعية المطلقة'});
  });

  test('every section under the kept categories, at any depth, is kept',
      () async {
    final kept = await database.rawQuery('''
      WITH RECURSIVE under(id) AS (
        SELECT id FROM titles WHERE parentId IN (${kKeptCategoryIds.join(',')})
        UNION ALL
        SELECT titles.id FROM titles JOIN under ON titles.parentId = under.id
      )
      SELECT id FROM under
    ''');
    final keptIds = kept.map((row) => row['id']! as int).toSet();
    final classified = {
      for (final title in titles)
        if (progressKeepingOf(title, titles) == ProgressKeeping.always)
          title.id,
    };

    expect(classified, keptIds);
    expect(keptIds, isNotEmpty);
  });

  test('the sections said at each occasion keep nothing', () {
    expect(keepingOf(16), ProgressKeeping.none, reason: 'after the prayer');
    expect(keepingOf(4), ProgressKeeping.none, reason: 'on waking');
    expect(keepingOf(61), ProgressKeeping.none, reason: 'eating');
    expect(keepingOf(1), ProgressKeeping.forToday);
    expect(keepingOf(18), ProgressKeeping.forToday);
    expect(keepingOf(77), ProgressKeeping.always, reason: 'two levels down');
  });
}
