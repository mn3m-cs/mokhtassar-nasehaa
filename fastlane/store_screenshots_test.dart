import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/manager/screen_awake_manager.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/home/presentation/screens/home_page_screen.dart';
import 'package:alazkar/src/features/quran/data/repository/uthmani_repository.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:alazkar/src/features/search/domain/repository/search_repo.dart';
import 'package:alazkar/src/features/search/presentation/controller/cubit/search_cubit.dart';
import 'package:alazkar/src/features/search/presentation/screens/search_screen.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_source_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../alazkar/test/support/fake_reminder_platform.dart';
import '../alazkar/test/support/memory_storage.dart';
import '../alazkar/test/support/screen_picture.dart';

// Run from alazkar/: fvm flutter test ../fastlane/store_screenshots_test.dart
// Output is staged in build/ so normal verification never overwrites metadata.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory databaseDir;
  late AzkarDBHelper database;
  late BookmarksDBHelper bookmarks;
  late UthmaniRepository quran;
  late HomeBloc home;
  late ThemeCubit theme;
  late MemoryStorage storage;
  late ZikrFilterStorage filters;

  setUpAll(() async {
    await loadAppFonts();
    final symbols =
        FontLoader('packages/material_symbols_icons/MaterialSymbolsOutlined')
          ..addFont(
            rootBundle.load(
              'packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf',
            ),
          );
    await symbols.load();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseDir = Directory.systemTemp.createTempSync('store_screenshots_');
    await databaseFactoryFfi.setDatabasesPath(databaseDir.path);
    database = AzkarDBHelper();
    await database.init();
    bookmarks = BookmarksDBHelper();
    await bookmarks.init();
    quran = UthmaniRepository();
    await quran.init();
  });

  tearDownAll(() async {
    await (await database.database).close();
    await (await bookmarks.database).close();
    await (await quran.database).close();
    databaseDir.deleteSync(recursive: true);
  });

  setUp(() async {
    storage = MemoryStorage();
    filters = ZikrFilterStorage(storage);
    theme = ThemeCubit(ZikrTextRepo(storage), ThemeStorage(storage));
    sl.registerSingleton(filters);
    sl.registerSingleton(quran);
    home = HomeBloc(
      ZikrSourceFilterCubit(filters),
      filters,
      database,
      bookmarks,
    )..add(HomeStartEvent());
    await home.stream
        .firstWhere((state) => state is HomeLoadedState)
        .timeout(const Duration(seconds: 15));
    sl.registerSingleton<KVStorage>(storage);
    sl.registerFactory<ZikrContentViewerBloc>(
      () => ZikrContentViewerBloc(
        home,
        SettingsStorage(storage),
        filters,
        database,
        ReadingProgressStorage(storage),
      ),
    );
    // These void methods match the app's own platform channel contracts.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      VolumeButtonManager.channel,
      ScreenAwakeManager.channel,
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    }
  });

  tearDown(() async {
    await sl.reset();
    await home.close();
    await theme.close();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      VolumeButtonManager.channel,
      ScreenAwakeManager.channel,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  Widget app(Widget screen, {SearchCubit? search}) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: home),
      BlocProvider.value(value: theme),
      BlocProvider(create: (_) => SettingsCubit(SettingsStorage(storage))),
      if (search != null) BlocProvider.value(value: search),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(theme.state),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: screen,
    ),
  );

  Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 50 && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ready(), isTrue);
  }

  Future<void> draw(
    WidgetTester tester,
    int index,
    Widget screen, {
    Future<void> Function(WidgetTester)? beforeCapture,
  }) async {
    await drawScreenPicture(
      tester,
      screen: screen,
      path: 'build/store_screenshots/0$index.png',
      size: const Size(360, 640),
      pixelRatio: 3,
      beforeCapture: beforeCapture,
    );
    expect(tester.takeException(), isNull);
    final bytes = File('build/store_screenshots/0$index.png').readAsBytesSync();
    final header = ByteData.sublistView(bytes);
    expect(header.getUint32(16), 1080);
    expect(header.getUint32(20), 1920);
  }

  Future<void> reader(
    WidgetTester tester,
    int index, {
    bool dark = false,
    bool source = false,
  }) async {
    if (dark) await theme.changeBrightness(Brightness.dark);
    final zikr = (await tester.runAsync(() => database.getContentByIds([2])))!
        .single;
    await draw(
      tester,
      index,
      app(const ZikrContentViewerScreen(zikrTitleId: 1, zikrOrder: 2)),
      beforeCapture: (tester) async {
        await waitFor(
          tester,
          () => find.byType(ZikrItemCard).evaluate().isNotEmpty,
        );
        if (source) {
          unawaited(
            showZikrSourceDialog(
              tester.element(find.byType(ZikrItemCard).first),
              zikr,
            ),
          );
        }
      },
    );
    expect(find.byType(ZikrContentViewerScreen), findsOneWidget);
    if (source) {
      expect(find.text(zikr.source), findsOneWidget);
    } else {
      expect(find.text('3'), findsWidgets);
    }
  }

  testWidgets('00: index and default favourites from the database', (
    tester,
  ) async {
    await draw(tester, 0, app(const HomePageScreen()));
    expect(find.text('الفهرس'), findsOneWidget);
  });

  testWidgets('01: a section with its counter', (tester) => reader(tester, 1));
  testWidgets(
    '02: a passage with its source dialog',
    (tester) => reader(tester, 2, source: true),
  );
  testWidgets('03: night mode', (tester) => reader(tester, 3, dark: true));

  testWidgets('04: daily reminders', (tester) async {
    final cities = CityRepository();
    final cairo = (await tester.runAsync(cities.all))!
        .firstWhere((city) => city.name == 'القاهرة');
    final reminderStorage = ReminderStorage(storage);
    await reminderStorage.writePlace(cairo);
    for (final slot in ReminderSlot.values) {
      await reminderStorage.write(
        slot,
        reminderStorage.read(slot).copyWith(enabled: true),
      );
    }
    final reminders = RemindersCubit(
      reminderStorage,
      FakeReminderPlatform(),
      () async => {
        for (final title in await database.getAllTitles()) title.id: title.name,
      },
      cities,
      clock: () => DateTime(2026, 10, 29, 12),
      utcOffsetOf: (_) => const Duration(hours: 2),
    );
    await tester.runAsync(reminders.start);
    sl.registerSingleton(reminders);
    addTearDown(reminders.close);
    await draw(tester, 4, app(const RemindersScreen()));
    expect(
      find.byKey(const ValueKey('reminder-switch-morning')),
      findsOneWidget,
    );
  });

  testWidgets('05: search with real results and their paths', (tester) async {
    final search = SearchCubit(
      home,
      filters,
      database,
      bookmarks,
      SearchRepo(storage),
    );
    await tester.runAsync(search.start);
    sl.registerSingleton(search);
    addTearDown(search.close);
    await draw(
      tester,
      5,
      app(const SearchScreen(), search: search),
      beforeCapture: (tester) async {
        await tester.enterText(find.byType(TextField), 'ما هو');
        await tester.pump(const Duration(milliseconds: 600));
        await waitFor(
          tester,
          () => search.titlePagingController.itemList?.isNotEmpty ?? false,
        );
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
    expect(
      (search.state as SearchLoadedState).searchResultCount,
      greaterThan(0),
    );
    expect(search.titlePagingController.error, isNull);
  });
}
