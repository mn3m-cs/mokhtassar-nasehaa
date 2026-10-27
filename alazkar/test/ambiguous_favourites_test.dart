import 'dart:io';

import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/home_header.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The wirds' parent, «جامع أدعية القرآن المجيد والسنة الصحيحة».
const _wirdsParent = 191;
const _seventhWird = 87;
const _firstWird = 92;

/// «فضائل الحولَقَة», a section with a parent and a name that says where it
/// is.
const _hawqalaVirtues = 156;

void main() {
  late List<ZikrTitle> titles;

  setUpAll(() async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      File('assets/db/Al-Azkar.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    titles = [
      for (final row in await database.rawQuery('SELECT * FROM titles'))
        ZikrTitle.fromMap(row),
    ];
    await database.close();
  });

  String nameOf(int id) => titles.firstWhere((t) => t.id == id).name;

  List<HomeTile> tilesOf(List<int> favourites) => HomeLoadedState(
        titles: titles,
        titlesToShow: titles,
        isSearching: false,
        favouriteTitlesIds: favourites,
        cardSections: const {},
      ).favouriteTiles();

  test('the ambiguous sections are exactly the wirds of the book', () {
    final wirds = {
      for (final title in titles)
        if (title.parentId == _wirdsParent && title.name.startsWith('الوِرْدُ'))
          title.id,
    };
    expect(wirds, hasLength(11));
    expect(HomeTile.ambiguousTitleIds, wirds);
  });

  test('a wird names its parent, any other section none', () {
    final parentOf = {
      for (final tile in tilesOf([_seventhWird, _hawqalaVirtues, _firstWird]))
        tile.id: tile.parent?.id,
    };
    expect(parentOf, {
      _firstWird: _wirdsParent,
      _seventhWird: _wirdsParent,
      _hawqalaVirtues: null,
    });
  });

  testWidgets('the tile shows the parent above a wird alone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeHeader(
              favourites: tilesOf([_seventhWird, _hawqalaVirtues, _firstWird]),
            ),
          ),
        ),
      ),
    );

    Finder tileOf(int id) => find.ancestor(
          of: find.text(nameOf(id)),
          matching: find.byType(InkWell),
        );
    final parent = find.text(nameOf(_wirdsParent));
    expect(parent, findsNWidgets(2));
    for (final wird in [_seventhWird, _firstWird]) {
      expect(
        find.descendant(of: tileOf(wird), matching: parent),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: tileOf(_hawqalaVirtues), matching: find.byType(Text)),
      findsOneWidget,
    );
  });
}
