import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/models/home_card.dart';
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

  test('default favourites are the default home cards', () {
    expect(BookmarksDBHelper.defaultTitleIds, [
      for (final card in kHomeCards)
        if (card.isDefault) card.favouriteId,
    ]);
    expect(
      BookmarksDBHelper.defaultTitleIds.map((id) => homeCardById(-id)!.name),
      [
        'أذكار الصباح',
        'أذكار المساء',
        'أذكار الاستيقاظ',
        'ما يقول بعد الصلاة',
        'أذكار النوم',
        'أذكار المسافر',
      ],
    );
  });

  for (final oldVersion in [1, 2]) {
    test('upgrading from version $oldVersion ends with the correct defaults',
        () async {
      final db =
          await favouritesDatabase(BookmarksDBHelper.legacyDefaultTitleIds);

      await BookmarksDBHelper.upgrade(db, oldVersion);

      expect(await storedIds(db), [-49, -18, -16, -4, -2, -1]);
    });
  }

  test('untouched legacy defaults are replaced by the correct ones', () async {
    final db =
        await favouritesDatabase(BookmarksDBHelper.legacyDefaultTitleIds);

    await BookmarksDBHelper.replaceLegacyDefaults(db);

    expect(await storedIds(db), [-49, -18, -16, -4, -2, -1]);
  });

  test('a trimmed legacy set is still treated as untouched', () async {
    final db = await favouritesDatabase([84, 99]);

    await BookmarksDBHelper.replaceLegacyDefaults(db);

    expect(await storedIds(db), [-49, -18, -16, -4, -2, -1]);
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
    const section = ZikrTitle(id: 197, order: 1, name: 'ذكر الله', freq: 'd');
    const state = HomeLoadedState(
      titles: [category, section],
      titlesToShow: [category, section],
      isSearching: false,
      favouriteTitlesIds: [197, 99],
      cardSections: {},
    );

    expect(state.favouriteTiles(), [const HomeTile.section(section)]);
  });
}
