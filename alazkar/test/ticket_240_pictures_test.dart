import 'dart:io';

import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/manager/screen_awake_manager.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/models/home_card.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/quran/data/repository/uthmani_repository.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/app_theme.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_storage.dart';
import 'support/screen_picture.dart';

const _pictureDir = '../docs/pictures/240';

class _NoFavourites implements BookmarksDBHelper {
  @override
  Future<List<int>> getAllFavoriteTitles() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory databaseDir;
  late AzkarDBHelper azkarDB;
  late UthmaniRepository quran;

  setUpAll(() async {
    await loadAppFonts();
    sqfliteFfiInit();
    databaseDir = Directory.systemTemp.createTempSync('ticket_241_pictures');
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(databaseDir.path);
    azkarDB = AzkarDBHelper();
    await azkarDB.init();
    quran = UthmaniRepository();
  });

  tearDownAll(() => databaseDir.deleteSync(recursive: true));

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

  Future<Widget> reader({
    HomeCard? card,
    int? titleId,
    int? zikrOrder,
    bool dark = false,
  }) async {
    final storage = MemoryStorage();
    final themeStorage = ThemeStorage(storage);
    if (dark) await themeStorage.setBrightness(Brightness.dark);
    final filterStorage = ZikrFilterStorage(MemoryStorage());
    sl.registerSingleton(filterStorage);
    sl.registerSingleton(quran);
    sl.registerSingleton<KVStorage>(MemoryStorage());
    final homeBloc = HomeBloc(
      ZikrSourceFilterCubit(filterStorage),
      filterStorage,
      azkarDB,
      _NoFavourites(),
    );
    addTearDown(homeBloc.close);
    homeBloc.add(HomeStartEvent());
    await homeBloc.stream.firstWhere((state) => state is HomeLoadedState);
    sl.registerFactory<ZikrContentViewerBloc>(
      () => ZikrContentViewerBloc(
        homeBloc,
        SettingsStorage(MemoryStorage()),
        filterStorage,
        azkarDB,
        ReadingProgressStorage(MemoryStorage()),
      ),
    );
    final themeCubit = ThemeCubit(ZikrTextRepo(storage), themeStorage);
    addTearDown(themeCubit.close);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: homeBloc),
        BlocProvider(create: (_) => SettingsCubit(SettingsStorage(storage))),
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
        home: ZikrContentViewerScreen(
          zikrTitleId: titleId ?? card!.id,
          zikrOrder: zikrOrder,
          card: card,
        ),
      ),
    );
  }

  Future<void> waitForReader(WidgetTester tester) async {
    for (var i = 0;
        i < 40 && find.byType(ZikrItemCard).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ZikrItemCard), findsWidgets);
  }

  Future<void> draw(
    WidgetTester tester, {
    required String file,
    HomeCard? card,
    int? titleId,
    int? zikrOrder,
    bool dark = false,
    Future<void> Function(WidgetTester tester)? afterLoad,
  }) async {
    final screen = await tester.runAsync(
      () => reader(
        card: card,
        titleId: titleId,
        zikrOrder: zikrOrder,
        dark: dark,
      ),
    );
    await drawScreenPicture(
      tester,
      path: '$_pictureDir/$file',
      screen: screen!,
      beforeCapture: (tester) async {
        await waitForReader(tester);
        await afterLoad?.call(tester);
      },
    );
  }

  testWidgets('case 1: no shake tip over the reader', (tester) async {
    await draw(
      tester,
      file: '1-after-prayer-no-tip.png',
      card: homeCardById(16),
    );
  });

  testWidgets('case 2: the app bar flag still opens the report',
      (tester) async {
    await draw(
      tester,
      file: '2-app-bar-report.png',
      card: homeCardById(16),
      afterLoad: (tester) async {
        await tester.tap(find.byTooltip('الإبلاغ عن خطأ'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
      },
    );
  });
}
