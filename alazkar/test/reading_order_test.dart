import 'dart:io';

import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  HomeLoadedState stateOf(List<ZikrTitle> titles, {List<ZikrTitle>? shown}) =>
      HomeLoadedState(
        titles: titles,
        titlesToShow: shown ?? titles,
        isSearching: false,
        favouriteTitlesIds: const [],
      );

  test('next section follows the book, not the local order numbers', () async {
    final db = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(db.close);
    final titles = (await db.query('titles')).map(ZikrTitle.fromMap).toList();

    final ids = stateOf(titles).readingOrder().map((t) => t.id).toList();

    expect(ids.take(8), [171, 102, 104, 197, 198, 1, 2, 3]);
    expect(ids.indexOf(68), ids.indexOf(330) + 1,
        reason: "p242 prints the gathering's dhikr right after the sunna's");
    expect(ids.toSet().length, ids.length);
    expect(
      ids.length,
      titles.where((t) => t.nodeType == ZikrTitleNodeType.content).length,
    );
  });

  test('favourites are listed in book order, not in the order added', () async {
    final db = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(db.close);
    final titles = (await db.query('titles')).map(ZikrTitle.fromMap).toList();
    final state = HomeLoadedState(
      titles: titles,
      titlesToShow: titles,
      isSearching: false,
      favouriteTitlesIds: const [74, 209, 9, 197],
    );

    expect(
      state.favouriteTiles().map((t) => t.name),
      [
        'ذِكرُ الله عَزَّ وَجَلَّ في الصباح والمساء من أشرف الوظائف اليومية الراتبة',
        'صِفَةُ الأذان',
        'ما يقول إذا سَمِعَ المؤذِّنَ',
        'صِيَغُ التَّسبيحِ في القُرآنِ والسُّنَّة',
      ],
    );
  });

  test('categories are skipped and hidden sections are left out', () {
    const titles = [
      ZikrTitle(
        id: 10,
        order: 2,
        name: 'باب',
        freq: 'd',
        nodeType: ZikrTitleNodeType.category,
      ),
      ZikrTitle(id: 11, order: 2, name: 'ب', freq: 'd', parentId: 10),
      ZikrTitle(id: 12, order: 1, name: 'أ', freq: 'd', parentId: 10),
      ZikrTitle(id: 20, order: 1, name: 'قبل', freq: 'd'),
      ZikrTitle(id: 30, order: 3, name: 'بعد', freq: 'd'),
    ];

    final all = stateOf(titles).readingOrder().map((t) => t.id);
    final filtered = stateOf(
      titles,
      shown: titles.where((t) => t.id != 11).toList(),
    ).readingOrder().map((t) => t.id);

    expect(all, [20, 12, 11, 30]);
    expect(filtered, [20, 12, 30]);
  });
}
