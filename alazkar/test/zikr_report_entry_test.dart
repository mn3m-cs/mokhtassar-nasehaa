import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/settings/data/repository/zikr_text_repo.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_report_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

const _morning =
    ZikrTitle(id: 1, order: 1, name: 'أذكار الصباح', freq: 'd', parentId: 100);

const _category = ZikrTitle(
  id: 100,
  order: 100,
  name: '',
  freq: 'd',
  nodeType: ZikrTitleNodeType.category,
);

Zikr _zikr(int id, String body, int count) => Zikr(
      id: id,
      titleId: 1,
      order: id,
      body: body,
      source: 'مرجع الذكر',
      fadl: '',
      hokm: '',
      count: count,
      search: '',
      sourceIndex: '',
    );

/// The reader opens on the first, so the first is the zikr in view.
final _azkar = [
  _zikr(1, 'رضيت بالله ربا', 3),
  _zikr(2, 'سبحان الله وبحمده', 1),
  _zikr(3, 'فائدة تُقرأ ولا تُعد', 0),
];

class _FakeAzkarDB implements AzkarDBHelper {
  @override
  Future<List<Zikr>> getContentByTitleId(int id) async => _azkar;

  @override
  Future<Zikr> getContentById(int id) async =>
      _azkar.firstWhere((zikr) => zikr.id == id);

  @override
  Future<ZikrTitle> getTitlesById(int id) async => _morning;

  @override
  Future<List<ZikrTitle>> getAllTitles() async => [_category, _morning];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBookmarksDB implements BookmarksDBHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> clipboard;

  setUp(() {
    clipboard = [];
    messenger.setMockMethodCallHandler(
      VolumeButtonManager.channel,
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (_) async => true,
    );
  });

  tearDown(() async {
    await sl.reset();
    messenger.setMockMethodCallHandler(VolumeButtonManager.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      null,
    );
  });

  /// The reader screen itself, wired as the app wires it, on the section
  /// above.
  Future<void> openReader(WidgetTester tester) async {
    final storage = MemoryStorage();
    final filterStorage = ZikrFilterStorage(MemoryStorage());
    final db = _FakeAzkarDB();
    final homeBloc = HomeBloc(
      ZikrSourceFilterCubit(filterStorage),
      filterStorage,
      db,
      _FakeBookmarksDB(),
    );
    addTearDown(homeBloc.close);
    sl.registerSingleton(filterStorage);
    sl.registerFactory<ZikrContentViewerBloc>(
      () => ZikrContentViewerBloc(
        homeBloc,
        SettingsStorage(MemoryStorage()),
        filterStorage,
        db,
        ReadingProgressStorage(MemoryStorage()),
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: homeBloc),
          BlocProvider(create: (_) => SettingsCubit(SettingsStorage(storage))),
          BlocProvider(
            create: (_) =>
                ThemeCubit(ZikrTextRepo(storage), ThemeStorage(storage)),
          ),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ZikrContentViewerScreen(zikrTitleId: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inDialog(String text) => find.descendant(
        of: find.byType(ZikrReportDialog),
        matching: find.text(text),
      );

  testWidgets('a card menu reports its own zikr, not the one in view',
      (tester) async {
    await openReader(tester);

    await tester.tap(find.byTooltip('خيارات الذكر').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإبلاغ عن خطأ'));
    await tester.pumpAndSettle();

    expect(inDialog('سبحان الله وبحمده'), findsOneWidget);
    expect(inDialog('رضيت بالله ربا'), findsNothing);
  });

  testWidgets('a passage read, not counted, can be reported too',
      (tester) async {
    await openReader(tester);

    expect(find.byTooltip('خيارات الذكر'), findsNWidgets(2));
    await tester.longPress(
      find.text('فائدة تُقرأ ولا تُعد', findRichText: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإبلاغ عن خطأ'));
    await tester.pumpAndSettle();

    expect(inDialog('فائدة تُقرأ ولا تُعد'), findsOneWidget);
  });

  testWidgets('a passage long press opens all actions and copies to clipboard',
      (tester) async {
    await openReader(tester);

    await tester.longPress(
      find.text('فائدة تُقرأ ولا تُعد', findRichText: true),
    );
    await tester.pumpAndSettle();

    for (final action in ['المصدر', 'مشاركة', 'نسخ', 'الإبلاغ عن خطأ']) {
      expect(find.text(action), findsOneWidget);
    }

    await tester.tap(find.text('نسخ'));
    await tester.pumpAndSettle();
    expect(clipboard, hasLength(1));
    expect(clipboard.single, contains('فائدة تُقرأ ولا تُعد'));
    // Let the copy toast's timer run out before the test ends.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the app bar flag reports the zikr in view', (tester) async {
    await openReader(tester);

    await tester.tap(find.byKey(const ValueKey('reader-report')));
    await tester.pumpAndSettle();

    expect(inDialog('رضيت بالله ربا'), findsOneWidget);
  });
}
