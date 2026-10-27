import 'dart:convert';
import 'dart:io';

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/models/home_card.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/quran/data/repository/uthmani_repository.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/presentation/components/reminder_launch_listener.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/models/progress_keeping.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';

/// The home cards as `main` held them at `2688f25`, before #220: each section
/// id, its name, and its `contents.id` in order. Extracted from that commit's
/// database with
///   git show 2688f25:alazkar/assets/db/Al-Azkar.db > old.db
///   SELECT id FROM contents WHERE titleId = ? ORDER BY "order"
final List<({int id, String name, List<int> zikrIds})> _before = [
  for (final card in (jsonDecode(
    File('test/fixtures/home_cards_2688f25.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>())
    (
      id: card['id'] as int,
      name: card['name'] as String,
      zikrIds: (card['zikrIds'] as List).cast<int>(),
    ),
];

/// Stores favourites in memory, as the real helper does.
class _MemoryBookmarksDB implements BookmarksDBHelper {
  final List<int> ids;

  _MemoryBookmarksDB(this.ids);

  @override
  Future<List<int>> getAllFavoriteTitles() async => [...ids];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory dir;
  late AzkarDBHelper azkarDB;
  late UthmaniRepository quran;
  late ZikrFilterStorage filterStorage;
  late MemoryStorage progressBox;
  final closers = <Future<void> Function()>[];

  // The helper copies the bundled database on first use, as on a phone.
  setUpAll(() async {
    sqfliteFfiInit();
    dir = Directory.systemTemp.createTempSync('home_cards');
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(dir.path);
    azkarDB = AzkarDBHelper();
    await azkarDB.init();
    quran = UthmaniRepository();
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  setUp(() {
    messenger.setMockMethodCallHandler(
      VolumeButtonManager.channel,
      (_) async => null,
    );
    filterStorage = ZikrFilterStorage(MemoryStorage());
    sl.registerSingleton(filterStorage);
    sl.registerSingleton(quran);
    progressBox = MemoryStorage();
  });

  tearDown(() async {
    for (final close in closers.reversed) {
      await close();
    }
    closers.clear();
    await sl.reset();
    messenger.setMockMethodCallHandler(VolumeButtonManager.channel, null);
  });

  Future<HomeLoadedState> home(List<int> favourites) async {
    final bloc = HomeBloc(
      ZikrSourceFilterCubit(filterStorage),
      filterStorage,
      azkarDB,
      _MemoryBookmarksDB(favourites),
    );
    closers.add(bloc.close);
    bloc.add(HomeStartEvent());
    return await bloc.stream.firstWhere((s) => s is HomeLoadedState)
        as HomeLoadedState;
  }

  /// Opens [card] as its home tile does, through the viewer and the bundled
  /// database.
  Future<(ZikrContentViewerBloc, ZikrContentViewerLoadedState)> open(
    HomeCard card,
  ) async {
    final homeBloc = HomeBloc(
      ZikrSourceFilterCubit(filterStorage),
      filterStorage,
      azkarDB,
      _MemoryBookmarksDB(BookmarksDBHelper.defaultTitleIds),
    );
    closers.add(homeBloc.close);
    homeBloc.add(HomeStartEvent());
    await homeBloc.stream.firstWhere((s) => s is HomeLoadedState);
    final bloc = ZikrContentViewerBloc(
      homeBloc,
      SettingsStorage(MemoryStorage()),
      filterStorage,
      azkarDB,
      ReadingProgressStorage(progressBox),
    );
    closers.add(bloc.close);
    bloc.add(ZikrContentViewerStartEvent.card(card));
    final state =
        await bloc.stream.firstWhere((s) => s is ZikrContentViewerLoadedState);
    return (bloc, state as ZikrContentViewerLoadedState);
  }

  test('the cards are the sections the home page had at 2688f25', () {
    expect(
      kHomeCards.map((card) => (card.id, card.name)),
      _before.map((card) => (card.id, card.name)),
    );
  });

  for (final before in _before) {
    test(
        '«${before.name}» opens the ${before.zikrIds.length} azkar it opened '
        'at 2688f25, in their order', () async {
      final (_, page) = await open(homeCardById(before.id)!);

      expect(page.zikrTitle.name, before.name);
      expect(page.azkar.map((zikr) => zikr.id), before.zikrIds);
    });
  }

  test('a card keeps the progress its section kept, under its old id',
      () async {
    final keeping = {
      for (final card in kHomeCards)
        card.id: (await open(card)).$2.progressKeeping,
    };
    expect(keeping, {
      1: ProgressKeeping.forToday,
      2: ProgressKeeping.forToday,
      4: ProgressKeeping.none,
      9: ProgressKeeping.none,
      16: ProgressKeeping.none,
      18: ProgressKeeping.forToday,
      49: ProgressKeeping.none,
      176: ProgressKeeping.always,
    });

    final (bloc, page) = await open(homeCardById(1)!);
    final counted = page.azkar.firstWhere(page.isCounted);
    bloc.add(ZikrContentViewerDecreaseEvent(counted));
    await pumpEventQueue();

    expect(progressBox.read<String>('reading_progress_1'), isNotNull);
    final reopened = (await open(homeCardById(1)!)).$2;
    expect(
      reopened.azkar.firstWhere((zikr) => zikr.id == counted.id).count,
      counted.count - 1,
    );
  });

  test('a card goes on from the section of its last zikr', () async {
    final (_, page) = await open(homeCardById(9)!);
    final order = (await home(BookmarksDBHelper.defaultTitleIds))
        .readingOrder()
        .map((title) => title.id)
        .toList();

    expect(page.lastSectionId, 209);
    expect(page.nextFromId, 209);
    expect(page.previousFromId, 9);
    expect(order.indexOf(209), greaterThan(order.indexOf(9)));
  });

  test('the default tiles carry the old names, in book order', () async {
    final state = await home(const [-49, -18, -1, -16, -2, -4]);

    expect(state.favouriteTiles().map((tile) => tile.name), [
      'أذكار الصباح',
      'أذكار المساء',
      'أذكار الاستيقاظ',
      'ما يقول بعد الصلاة',
      'أذكار النوم',
      'أذكار المسافر',
    ]);
    expect(
      state.favouriteTiles().every((tile) => tile.card?.isDefault ?? false),
      isTrue,
    );
  });

  test('a saved card and the index section that kept its id are two tiles',
      () async {
    final state = await home(const [-1, -2, -4, -16, -18, -49, -9, 9, -176]);

    expect(
      state.favouriteTiles().map((tile) => tile.name),
      containsAllInOrder([
        'أذكار الأذان',
        'صِفَةُ الأذان',
        'ورد التسبيح',
      ]),
    );
  });

  test('the defaults are the default cards', () {
    expect(
      kHomeCards
          .where((card) => card.isDefault)
          .map((card) => card.favouriteId),
      BookmarksDBHelper.defaultTitleIds,
    );
  });

  test("an index section that kept a card's id is a favourite of its own",
      () async {
    final state = await home([...BookmarksDBHelper.defaultTitleIds, 49]);

    expect(
      state.favouriteTiles().map((tile) => tile.name),
      containsAllInOrder(['أذكار المسافر', 'ما يقول المسافر ومَن يُودِّعه']),
    );
    expect(BookmarksDBHelper.isPinned(-1), isTrue);
    expect(BookmarksDBHelper.isPinned(1), isFalse);
  });

  test('the filters do not move a card off the home page', () async {
    await filterStorage.setEnableHokmFiltersStatus(true);

    final state = await home(BookmarksDBHelper.defaultTitleIds);

    final shownIds = state.titlesToShow.map((title) => title.id);
    expect(shownIds, isNot(contains(197)),
        reason: 'the morning card starts in 197');
    // A card stays while any of its azkar passes the filters, as its
    // section did before #220.
    expect(
      state.favouriteTiles().map((tile) => tile.name),
      containsAllInOrder(['أذكار الصباح', 'أذكار المساء']),
    );
    // The morning card goes on from its hidden first section.
    expect(state.shownSectionFrom(197, 1)?.id, 1);
    expect(state.shownSectionFrom(1, -1)?.id, isNot(anyOf(197, 198)));
  });

  test('a card and the index section that kept its id count apart', () async {
    final (cardBloc, cardPage) = await open(homeCardById(1)!);
    final counted = cardPage.azkar.firstWhere(
      (zikr) => cardPage.isCounted(zikr) && zikr.titleId == 1,
    );
    cardBloc.add(ZikrContentViewerDecreaseEvent(counted));
    await pumpEventQueue();

    final homeBloc = HomeBloc(
      ZikrSourceFilterCubit(filterStorage),
      filterStorage,
      azkarDB,
      _MemoryBookmarksDB(BookmarksDBHelper.defaultTitleIds),
    );
    closers.add(homeBloc.close);
    final sectionBloc = ZikrContentViewerBloc(
      homeBloc,
      SettingsStorage(MemoryStorage()),
      filterStorage,
      azkarDB,
      ReadingProgressStorage(progressBox),
    );
    closers.add(sectionBloc.close);
    sectionBloc.add(const ZikrContentViewerStartEvent(1));
    final section = await sectionBloc.stream
            .firstWhere((s) => s is ZikrContentViewerLoadedState)
        as ZikrContentViewerLoadedState;
    expect(
      section.azkar.firstWhere((zikr) => zikr.id == counted.id).count,
      counted.count,
      reason: "the section does not take the card's counts",
    );
    sectionBloc.add(ZikrContentViewerDecreaseEvent(section.azkar.last));
    await pumpEventQueue();

    expect(progressBox.read<String>('reading_progress_-1'), isNotNull);
    final reopened = (await open(homeCardById(1)!)).$2;
    expect(
      reopened.azkar.firstWhere((zikr) => zikr.id == counted.id).count,
      counted.count - 1,
    );
    expect(reopened.resumeZikrId, counted.id);
  });

  test('the reminders carry the old names', () async {
    expect(await loadReminderTitles(azkarDB), {
      ReminderSlot.morning.titleId: 'أذكار الصباح',
      ReminderSlot.evening.titleId: 'أذكار المساء',
      ReminderSlot.sleep.titleId: 'أذكار النوم',
    });
  });

  group('favourites saved before #220', () {
    Future<Database> favourites(List<int> titleIds) async {
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

    Future<List<int>> stored(Database db) async =>
        (await db.rawQuery('SELECT titleId FROM favourite_titles ORDER BY 1'))
            .map((row) => row['titleId']! as int)
            .toList();

    test('«أذكار الأذان» and «ورد التسبيح» stay their old cards', () async {
      final db = await favourites([1, 2, 4, 16, 18, 49, 9, 176]);

      await BookmarksDBHelper.upgrade(db, 4);

      expect(await stored(db), [-176, -49, -18, -16, -9, -4, -2, -1]);
    });

    test('a reader who saved neither keeps the defaults alone', () async {
      final db = await favourites([1, 2, 4, 16, 18, 49]);

      await BookmarksDBHelper.upgrade(db, 4);

      expect(await stored(db), [-49, -18, -16, -4, -2, -1]);
    });
  });
}
