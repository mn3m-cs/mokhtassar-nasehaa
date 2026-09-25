import 'dart:io';

import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<Database> favouritesDatabase(List<int> titleIds) async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE favourite_titles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titleId INTEGER NOT NULL UNIQUE
      )
    ''');
    for (final titleId in titleIds) {
      await db.insert('favourite_titles', {'titleId': titleId});
    }
    addTearDown(db.close);
    return db;
  }

  Future<List<int>> storedIds(Database db) async {
    final rows =
        await db.rawQuery('SELECT titleId FROM favourite_titles ORDER BY 1');
    return rows.map((row) => row['titleId']! as int).toList();
  }

  test('default favourites are the intended sections of the bundled database',
      () async {
    final db = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(db.close);

    final rows = await db.rawQuery(
      'SELECT id, name, nodeType FROM titles WHERE id IN '
      '(${BookmarksDBHelper.defaultTitleIds.join(',')}) ORDER BY id',
    );

    expect(rows, [
      {'id': 1, 'name': 'أذكار الصباح', 'nodeType': 'content'},
      {'id': 2, 'name': 'أذكار المساء', 'nodeType': 'content'},
      {'id': 4, 'name': 'أذكار الاستيقاظ', 'nodeType': 'content'},
      {'id': 16, 'name': 'ما يقول بعد الصلاة', 'nodeType': 'content'},
      {'id': 18, 'name': 'أذكار النوم', 'nodeType': 'content'},
      {'id': 49, 'name': 'أذكار المسافر', 'nodeType': 'content'},
    ]);
  });

  test('untouched legacy defaults are replaced by the correct ones', () async {
    final db =
        await favouritesDatabase(BookmarksDBHelper.legacyDefaultTitleIds);

    await BookmarksDBHelper.replaceLegacyDefaults(db);

    expect(await storedIds(db), [1, 2, 4, 16, 18, 49]);
  });

  test('a trimmed legacy set is still treated as untouched', () async {
    final db = await favouritesDatabase([84, 99]);

    await BookmarksDBHelper.replaceLegacyDefaults(db);

    expect(await storedIds(db), [1, 2, 4, 16, 18, 49]);
  });

  test('personal favourites are never rewritten', () async {
    final db = await favouritesDatabase([2, 99, 140]);

    await BookmarksDBHelper.replaceLegacyDefaults(db);

    expect(await storedIds(db), [2, 99, 140]);
  });

  test('an emptied favourites list stays empty', () async {
    final db = await favouritesDatabase([]);

    await BookmarksDBHelper.replaceLegacyDefaults(db);

    expect(await storedIds(db), isEmpty);
  });

  test('categories never appear among favourite titles', () {
    const category = ZikrTitle(
      id: 99,
      order: 1,
      name: 'حول الكتاب',
      freq: 'd',
      nodeType: ZikrTitleNodeType.category,
    );
    const section = ZikrTitle(id: 1, order: 1, name: 'أذكار الصباح', freq: 'd');
    const state = HomeLoadedState(
      titles: [category, section],
      freqFilters: [],
      titlesToShow: [category, section],
      isSearching: false,
      favouriteTitlesIds: [1, 99],
    );

    expect(state.favouriteTitles(), [section]);
  });
}
