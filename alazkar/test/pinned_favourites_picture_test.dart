import 'dart:io';
import 'dart:ui' as ui;

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/models/home_card.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/bookmark_title_button.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

/// Test pictures for the pinned favourites ticket (#166). Run with
/// `--dart-define=PICTURE_DIR=<dir>` to choose where the PNGs go.
const _dir =
    String.fromEnvironment('PICTURE_DIR', defaultValue: 'build/test_pictures');

const _titles = [
  ZikrTitle(id: 1, order: 1, name: 'أذكار الصباح', freq: 'd'),
  ZikrTitle(id: 49, order: 2, name: 'أذكار المسافر', freq: 'd'),
  ZikrTitle(id: 69, order: 3, name: 'ورد التهليل', freq: 'd'),
];

/// The rows of the picture, each with its row in `favourite_titles`: the
/// morning and travelling cards, and a section of the index.
const _rows = [
  (name: 'أذكار الصباح', favouriteId: -1),
  (name: 'أذكار المسافر', favouriteId: -49),
  (name: 'ورد التهليل', favouriteId: 69),
];

class _FakeAzkarDB implements AzkarDBHelper {
  @override
  Future<List<Zikr>> getContentByTitleId(int id) async => [
        Zikr(
          id: id,
          titleId: id,
          order: 1,
          body: 'نص',
          source: '',
          fadl: '',
          hokm: '',
          count: 1,
          search: '',
          sourceIndex: '',
        ),
      ];

  /// A card's azkar sit in the section of the card's id, as before #220.
  @override
  Future<List<Zikr>> getContentByIds(List<int> ids) async => [
        for (final id in ids)
          (await getContentByTitleId(
            kHomeCards.firstWhere((card) => card.zikrIds.contains(id)).id,
          ))
              .single,
      ];

  @override
  Future<List<ZikrTitle>> getAllTitles() async => [..._titles];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryBookmarksDB implements BookmarksDBHelper {
  final ids = <int>{...BookmarksDBHelper.defaultTitleIds, 69};

  @override
  Future<List<int>> getAllFavoriteTitles() async => ids.toList()..sort();

  @override
  Future<void> addTitleToFavourite({required int titleId}) async =>
      ids.add(titleId);

  @override
  Future<void> deleteTitleFromFavourite({required int titleId}) async =>
      ids.remove(titleId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  final boundaryKey = GlobalKey();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.625);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_dir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Finder buttonOf(String name) => find.descendant(
        of: find.widgetWithText(ListTile, name),
        matching: find.byType(IconButton),
      );

  Future<void> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(412, 500) * 2.625;
    addTearDown(tester.view.reset);

    final filterStorage = ZikrFilterStorage(MemoryStorage());
    if (sl.isRegistered<ZikrFilterStorage>()) {
      sl.unregister<ZikrFilterStorage>();
    }
    sl.registerSingleton(filterStorage);
    final bloc = HomeBloc(
      ZikrSourceFilterCubit(filterStorage),
      filterStorage,
      _FakeAzkarDB(),
      _MemoryBookmarksDB(),
    )..add(HomeStartEvent());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFFFFF9EF)),
              fontFamily: 'Cairo',
            ),
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar', 'EG')],
            home: Scaffold(
              appBar: AppBar(title: const Text('المفضلة')),
              body: ListView(
                children: [
                  for (final row in _rows)
                    ListTile(
                      title: Text(row.name),
                      trailing: BookmarkTitleButton(titleId: row.favouriteId),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('case 1: a pinned section', (tester) async {
    await open(tester);
    await shoot(tester, 'case1_pinned_morning');
  });

  testWidgets('case 2: travelling, removed, then undone', (tester) async {
    await open(tester);
    await shoot(tester, 'case2a_traveller_before_removal');

    await tester.tap(buttonOf('أذكار المسافر'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await shoot(tester, 'case2b_traveller_bar_after_removal');

    final undo = find.text('تراجع');
    if (undo.evaluate().isNotEmpty) {
      await tester.tap(undo);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    await shoot(tester, 'case2c_traveller_after_undo');
  });

  testWidgets('case 3: another optional favourite', (tester) async {
    await open(tester);
    await tester.tap(buttonOf('ورد التهليل'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await shoot(tester, 'case3_optional_bar_after_removal');
  });
}
