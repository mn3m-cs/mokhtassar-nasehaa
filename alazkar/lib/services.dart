import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/di/dependency_injection.dart'
    as service_locator;
import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/extension/extension_platform.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/core/storage/storage_migration_service.dart';
import 'package:alazkar/src/core/utils/app_bloc_observer.dart';
import 'package:alazkar/src/features/quran/data/repository/uthmani_repository.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/ui/data/repository/ui_repo.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();

  // Initialize Hive in Application Support directory instead of Documents on Windows
  final appSupportDir = await getApplicationSupportDirectory();
  await Hive.initFlutter(path.join(appSupportDir.path, 'storage'));
  await Hive.openBox(kHiveBoxName);

  service_locator.initSL();

  // Run migration from GetStorage to Hive
  await StorageMigrationService(sl<KVStorage>()).migrate();
  await resetHiddenReadingFilters();
  await resetHiddenThemeColor();

  phoneDeviceBars();
  final packageInfo = await PackageInfo.fromPlatform();
  kAppVersion = "${packageInfo.version} (${packageInfo.buildNumber})";

  if (PlatformExtension.isDesktopOrWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initDBs();

  initWindowsManager();

  // if(kDebugMode) await viewStatistics();
}

Future<void> phoneDeviceBars() async {
  // Enable edge-to-edge drawing (Android 15+ compatible)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Use a light overlay with transparent background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent for edge-to-edge
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
}

Future<void> initWindowsManager() async {
  if (!PlatformExtension.isDesktop) return;

  await windowManager.ensureInitialized();

  final WindowOptions windowOptions = WindowOptions(
    size: sl<UIRepo>().desktopWindowSize,
    center: true,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> initDBs() async {
  await Future.wait([
    sl<AzkarDBHelper>().init(),
    sl<UthmaniRepository>().init(),
    sl<BookmarksDBHelper>().init(),
  ]);
}

/// The book-hiding filters and the brackets switch are no longer in the
/// settings screen, so a value a reader set earlier could keep book text
/// hidden with no way back. They return to their defaults once.
Future<void> resetHiddenReadingFilters() async {
  final storage = sl<KVStorage>();
  const doneKey = 'hidden_reading_filters_reset';
  if (storage.read<bool>(doneKey) ?? false) return;

  final filters = sl<ZikrFilterStorage>();
  await filters.setEnableFiltersStatus(false);
  await filters.setEnableHokmFiltersStatus(false);
  await filters.setShowOnlyWithFadlStatus(false);
  await sl<SettingsStorage>().setShowTextInBrackets(true);
  await storage.write(doneKey, true);
}

/// The colour picker is no longer in the theme screen, so a colour a reader
/// chose earlier could not be changed back. It returns to the paper colour
/// once.
Future<void> resetHiddenThemeColor() async {
  final storage = sl<KVStorage>();
  const doneKey = 'hidden_theme_color_reset';
  if (storage.read<bool>(doneKey) ?? false) return;

  await sl<ThemeStorage>().resetColor();
  await storage.write(doneKey, true);
}
