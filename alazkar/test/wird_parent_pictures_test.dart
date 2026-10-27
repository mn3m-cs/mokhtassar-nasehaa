import 'dart:io';
import 'dart:ui' as ui;

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/home/presentation/screens/home_page_screen.dart';
import 'package:alazkar/src/features/quran/data/repository/uthmani_repository.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
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

/// Test pictures of #230's cases, drawn from the bundled database through the
/// real home page. Run on main with `--dart-define=PHASE=before` and on the
/// branch with `PHASE=after`; the file uses only what both trees have.
/// `--dart-define=PICTURE_DIR=<dir>` chooses where the PNGs go.
const _dir =
    String.fromEnvironment('PICTURE_DIR', defaultValue: 'build/test_pictures');
const _phase = String.fromEnvironment('PHASE', defaultValue: 'after');
const double _pixelRatio = 2.625;

/// The morning, evening and sleep cards; «الوِرْدُ السابع» and «الوِرْدُ
/// الأوَّل»; and «فضائل الحولَقَة».
const _withWirds = [-1, -2, -18, 87, 92, 156];

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

  late Directory dir;
  late AzkarDBHelper azkarDB;
  late UthmaniRepository quran;

  setUpAll(() async {
    await loadAppFonts();
    sqfliteFfiInit();
    dir = Directory.systemTemp.createTempSync('wird_parent_pictures');
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(dir.path);
    azkarDB = AzkarDBHelper();
    await azkarDB.init();
    quran = UthmaniRepository();
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  tearDown(() => sl.reset());

  Future<void> draw(
    WidgetTester tester,
    String name, {
    required List<int> favourites,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
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
        _MemoryBookmarksDB(favourites),
      ),
    ))!;
    addTearDown(homeBloc.close);
    await tester.runAsync(() async {
      homeBloc.add(HomeStartEvent());
      await homeBloc.stream.firstWhere((s) => s is HomeLoadedState);
    });
    final themeCubit = ThemeCubit(ZikrTextRepo(storage), ThemeStorage(storage));
    addTearDown(themeCubit.close);
    await themeCubit.changeBrightness(brightness);

    tester.view.devicePixelRatio = _pixelRatio;
    tester.view.physicalSize = const Size(412, 915) * _pixelRatio;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  testWidgets('case1_wirds', (tester) async {
    await draw(tester, 'case1_wirds', favourites: _withWirds);
  });

  testWidgets('case2_defaults', (tester) async {
    await draw(
      tester,
      'case2_defaults',
      favourites: BookmarksDBHelper.defaultTitleIds,
    );
  });

  testWidgets('case3_night', (tester) async {
    await draw(
      tester,
      'case3_night',
      favourites: _withWirds,
      brightness: Brightness.dark,
    );
  });

  // The app's font size reaches the azkar, not the home page, so the largest
  // text there is the phone's own: Android's largest font scale before 14.
  testWidgets('case4_largest_text', (tester) async {
    await draw(
      tester,
      'case4_largest_text',
      favourites: _withWirds,
      textScale: 1.3,
    );
  });
}
