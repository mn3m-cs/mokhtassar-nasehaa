import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:alazkar/src/features/reminders/presentation/components/reminder_launch_listener.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

/// Test pictures for the home cards kept as they were (#220, amendment of
/// 2026-10-23), drawn from the bundled database through the real home page
/// and reader. Run on `72aa4ee` with `--dart-define=PHASE=before` and on the
/// branch with `PHASE=after`; the file uses only what both trees have.
/// `--dart-define=PICTURE_DIR=<dir>` chooses where the PNGs go; a reader page
/// also writes a `.txt` with the number of azkar on it.
const _dir =
    String.fromEnvironment('PICTURE_DIR', defaultValue: 'build/test_pictures');
const _phase = String.fromEnvironment('PHASE', defaultValue: 'after');
const double _pixelRatio = 2.625;

/// The defaults, and «أذكار الأذان» as a reader saved it before the update:
/// before #220 under its section id, after it under its card's.
const _favourites = [1, 2, 4, 16, 18, 49, if (_phase == 'before') 9 else -9];

/// Stores favourites in memory.
class _MemoryBookmarksDB implements BookmarksDBHelper {
  @override
  Future<List<int>> getAllFavoriteTitles() async => [..._favourites];

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

  setUpAll(() async {
    await loadAppFonts();
    sqfliteFfiInit();
    dir = Directory.systemTemp.createTempSync('home_cards_pictures');
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(dir.path);
    azkarDB = AzkarDBHelper();
    await azkarDB.init();
    quran = UthmaniRepository();
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  setUp(() {
    for (final channel in [
      VolumeButtonManager.channel,
      ScreenAwakeManager.channel,
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    }
  });

  tearDown(() async {
    await sl.reset();
    messenger.setMockMethodCallHandler(VolumeButtonManager.channel, null);
    messenger.setMockMethodCallHandler(ScreenAwakeManager.channel, null);
  });

  /// Shows the home page, wired as the app wires it, and returns the key to
  /// draw it by.
  Future<GlobalKey> showHome(WidgetTester tester) async {
    final storage = MemoryStorage();
    final filterStorage = ZikrFilterStorage(MemoryStorage());
    sl.registerSingleton(filterStorage);
    sl.registerSingleton(quran);
    sl.registerSingleton<KVStorage>(MemoryStorage());
    // The bloc lives in the real zone, where the database answers.
    final homeBloc = (await tester.runAsync(
      () async => HomeBloc(
        ZikrSourceFilterCubit(filterStorage),
        filterStorage,
        azkarDB,
        _MemoryBookmarksDB(),
      ),
    ))!;
    addTearDown(homeBloc.close);
    sl.registerFactory<ZikrContentViewerBloc>(
      () => ZikrContentViewerBloc(
        homeBloc,
        SettingsStorage(MemoryStorage()),
        filterStorage,
        azkarDB,
        ReadingProgressStorage(MemoryStorage()),
      ),
    );
    await tester.runAsync(() async {
      homeBloc.add(HomeStartEvent());
      await homeBloc.stream.firstWhere((s) => s is HomeLoadedState);
    });
    final themeCubit = ThemeCubit(ZikrTextRepo(storage), ThemeStorage(storage));

    tester.view.devicePixelRatio = _pixelRatio;
    tester.view.physicalSize = const Size(412, 915) * _pixelRatio;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: homeBloc),
            BlocProvider(
              create: (_) => SettingsCubit(SettingsStorage(storage)),
            ),
            BlocProvider.value(value: themeCubit),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(themeCubit.state),
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar', 'EG')],
            locale: const Locale('ar', 'EG'),
            home: const HomePageScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = boundary.toImageSync(pixelRatio: _pixelRatio);
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    ))!;
    final file = File('$_dir/${name}_$_phase.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes.buffer.asUint8List());
  }

  testWidgets('case1_home', (tester) async {
    final key = await showHome(tester);
    await capture(tester, key, 'case1_home');
  });

  // Each tile is found by its icon, which is the same in both trees.
  for (final (name, icon) in [
    ('case2_adhan', Icons.bookmark),
    ('case3_travel', Icons.luggage_outlined),
    ('case4_morning', Icons.wb_twilight),
  ]) {
    testWidgets(name, (tester) async {
      final key = await showHome(tester);
      await tester.tap(find.byIcon(icon));
      // The page loads from the database in the real zone; wait for its
      // azkar, then let the route finish.
      for (var i = 0;
          i < 40 && find.byType(ZikrItemCard).evaluate().isEmpty;
          i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));
      final shown = find.byType(ZikrItemCard).evaluate().length;
      expect(shown, greaterThan(0));
      File('$_dir/${name}_$_phase.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('$shown\n');
      await capture(tester, key, name);
    });
  }

  testWidgets('case5_sleep_reminder', (tester) async {
    late Map<int, String> titles;
    await tester.runAsync(() async {
      titles = await loadReminderTitles(azkarDB);
    });
    await drawScreenPicture(
      tester,
      size: const Size(412, 140),
      path: '$_dir/case5_sleep_reminder_$_phase.png',
      screen: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Cairo'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.grey.shade300,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(
                    titles[ReminderSlot.sleep.titleId]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('زاد الذاكر'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  });
}
