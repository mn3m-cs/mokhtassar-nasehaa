import 'dart:io';

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/bookmark_title_button.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

const _pinned = [1, 2, 4, 16, 18];
const _morning = ZikrTitle(id: 1, order: 1, name: 'أذكار الصباح', freq: 'd');
const _traveller =
    ZikrTitle(id: 49, order: 2, name: 'أذكار المسافر', freq: 'd');
const _wird = ZikrTitle(id: 69, order: 3, name: 'ورد التهليل', freq: 'd');
const _titles = [_morning, _traveller, _wird];

Zikr _zikr(int titleId) => Zikr(
      id: titleId,
      titleId: titleId,
      order: 1,
      body: 'نص',
      source: '',
      fadl: '',
      hokm: '',
      count: 1,
      search: '',
      sourceIndex: '',
    );

class _FakeAzkarDB implements AzkarDBHelper {
  @override
  Future<List<Zikr>> getContentByTitleId(int id) async => [_zikr(id)];

  @override
  Future<List<ZikrTitle>> getAllTitles() async => [..._titles];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stores favourites in memory and keeps the pinned rule, as the real helper.
class _MemoryBookmarksDB implements BookmarksDBHelper {
  final ids = <int>{...BookmarksDBHelper.defaultTitleIds};

  @override
  Future<List<int>> getAllFavoriteTitles() async => ids.toList()..sort();

  @override
  Future<void> addTitleToFavourite({required int titleId}) async =>
      ids.add(titleId);

  @override
  Future<void> deleteTitleFromFavourite({required int titleId}) async {
    if (!BookmarksDBHelper.isPinned(titleId)) ids.remove(titleId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HomeBloc _bloc(BookmarksDBHelper bookmarks) {
  final filterStorage = ZikrFilterStorage(MemoryStorage());
  if (sl.isRegistered<ZikrFilterStorage>()) sl.unregister<ZikrFilterStorage>();
  sl.registerSingleton(filterStorage);
  return HomeBloc(
    ZikrSourceFilterCubit(filterStorage),
    filterStorage,
    _FakeAzkarDB(),
    bookmarks,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    sqfliteFfiInit();
    await loadAppFonts();
  });

  group('storage', () {
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

    test('the pinned sections are separate from the travelling default', () {
      expect(BookmarksDBHelper.pinnedTitleIds, _pinned);
      expect(BookmarksDBHelper.defaultTitleIds, [..._pinned, 49]);
      expect(BookmarksDBHelper.isPinned(49), isFalse);
    });

    test('a new install holds the six defaults', () async {
      final db = await favouritesDatabase([]);
      await BookmarksDBHelper.addDefaultTitles(db);
      expect(await storedIds(db), [1, 2, 4, 16, 18, 49]);
    });

    test('upgrade restores only the missing pinned sections', () async {
      final db = await favouritesDatabase([2, 16, 99, 140]);

      await BookmarksDBHelper.upgrade(db, 3);

      expect(await storedIds(db), [1, 2, 4, 16, 18, 99, 140]);
    });

    test('upgrade does not bring back a removed traveller section', () async {
      final db = await favouritesDatabase([..._pinned]);

      await BookmarksDBHelper.upgrade(db, 3);

      expect(await storedIds(db), _pinned);
    });

    group('with the real helper', () {
      late Directory dir;
      late BookmarksDBHelper helper;

      // The helper is a singleton that keeps its first connection, so one
      // database serves the group and is reset to a new install before each.
      setUpAll(() async {
        dir = Directory.systemTemp.createTempSync('bookmarks');
        databaseFactory = databaseFactoryFfi;
        await databaseFactoryFfi.setDatabasesPath(dir.path);
        helper = BookmarksDBHelper();
      });

      setUp(() async {
        final db = await helper.database;
        await db.delete('favourite_titles');
        await BookmarksDBHelper.addDefaultTitles(db);
      });

      tearDownAll(() async {
        await helper.close();
        dir.deleteSync(recursive: true);
      });

      test('a direct delete never removes a pinned section', () async {
        for (final id in _pinned) {
          await helper.deleteTitleFromFavourite(titleId: id);
        }
        expect(await helper.getAllFavoriteTitles(), [1, 2, 4, 16, 18, 49]);
      });

      test('travelling can be removed and added again', () async {
        await helper.deleteTitleFromFavourite(titleId: 49);
        expect(await helper.getAllFavoriteTitles(), _pinned);

        await helper.addTitleToFavourite(titleId: 49);
        expect(await helper.getAllFavoriteTitles(), [..._pinned, 49]);
      });
    });
  });

  group('HomeBloc', () {
    late _MemoryBookmarksDB bookmarks;
    late HomeBloc bloc;

    setUp(() async {
      bookmarks = _MemoryBookmarksDB();
      bloc = _bloc(bookmarks)..add(HomeStartEvent());
      await bloc.stream.firstWhere((state) => state is HomeLoadedState);
    });

    tearDown(() => bloc.close());

    Future<List<int>> ids() async {
      await Future<void>.delayed(Duration.zero);
      return (bloc.state as HomeLoadedState).favouriteTitlesIds;
    }

    test('unbookmarking a pinned section keeps it', () async {
      bloc.add(const HomeUnBookmarkTitleEvent(1));
      expect(await ids(), contains(1));
    });

    test('travelling goes and comes back', () async {
      bloc.add(const HomeUnBookmarkTitleEvent(49));
      expect(await ids(), isNot(contains(49)));

      bloc.add(const HomeBookmarkTitleEvent(49));
      expect(await ids(), contains(49));
    });

    test('an optional favourite is added and removed as before', () async {
      bloc.add(const HomeBookmarkTitleEvent(69));
      expect(await ids(), contains(69));

      bloc.add(const HomeUnBookmarkTitleEvent(69));
      expect(await ids(), isNot(contains(69)));
    });
  });

  group('bookmark button', () {
    late _MemoryBookmarksDB bookmarks;
    late HomeBloc bloc;

    Future<void> show(WidgetTester tester, int titleId) async {
      bookmarks = _MemoryBookmarksDB();
      bloc = _bloc(bookmarks)..add(HomeStartEvent());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Cairo'),
            home: Scaffold(body: BookmarkTitleButton(titleId: titleId)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a pinned section shows a fixed icon, not a button',
        (tester) async {
      await show(tester, 1);

      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.bySemanticsLabel('ثابت في المفضلة'), findsOneWidget);
      expect(find.byTooltip('إزالة من المفضلة'), findsNothing);
    });

    testWidgets('an optional favourite still offers removal', (tester) async {
      await show(tester, 49);

      expect(find.byTooltip('إزالة من المفضلة'), findsOneWidget);
    });

    testWidgets('removing shows the bar and undo brings the section back',
        (tester) async {
      await show(tester, 49);

      await tester.tap(find.byTooltip('إزالة من المفضلة'));
      await tester.pump();
      await tester.pump();

      expect(bookmarks.ids, isNot(contains(49)));
      expect(find.text('أُزيل من المفضلة'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('تراجع'));
      await tester.pump();
      await tester.pump();

      expect(bookmarks.ids, contains(49));
      expect(find.byTooltip('إزالة من المفضلة'), findsOneWidget);
    });

    testWidgets('the bar goes away by itself after six seconds',
        (tester) async {
      await show(tester, 49);

      await tester.tap(find.byTooltip('إزالة من المفضلة'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('تراجع'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('تراجع'), findsNothing);
      expect(bookmarks.ids, isNot(contains(49)));
    });
  });
}
