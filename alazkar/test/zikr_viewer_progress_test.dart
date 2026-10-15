import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/manager/volume_button_manager.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/settings/data/repository/settings_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/data/repository/reading_progress_storage.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

const _title = ZikrTitle(id: 1, order: 1, name: 'أذكار الصباح', freq: 'd');

Zikr _zikr(int id, int count) => Zikr(
      id: id,
      titleId: _title.id,
      order: id,
      body: 'نص $id',
      source: '',
      fadl: '',
      hokm: '',
      count: count,
      search: '',
      sourceIndex: '',
    );

/// The section: one zikr said once, one said three times, one said once,
/// and a passage to read.
final _azkar = [_zikr(1, 1), _zikr(2, 3), _zikr(3, 1), _zikr(4, 0)];

class _FakeAzkarDB implements AzkarDBHelper {
  @override
  Future<List<Zikr>> getContentByTitleId(int id) async => _azkar;

  @override
  Future<ZikrTitle> getTitlesById(int id) async => _title;

  @override
  Future<List<ZikrTitle>> getAllTitles() async => [_title];

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
  late MemoryStorage box;
  late DateTime now;
  late ZikrFilterStorage filterStorage;
  final blocs = <ZikrContentViewerBloc>[];

  setUp(() {
    messenger.setMockMethodCallHandler(
      VolumeButtonManager.channel,
      (_) async => null,
    );
    box = MemoryStorage();
    now = DateTime(2026, 10, 15, 7);
    filterStorage = ZikrFilterStorage(MemoryStorage());
    sl.registerSingleton(filterStorage);
  });

  tearDown(() async {
    for (final bloc in blocs) {
      await bloc.close();
    }
    blocs.clear();
    await sl.reset();
    messenger.setMockMethodCallHandler(VolumeButtonManager.channel, null);
  });

  /// Opens the section in a new bloc, as the screen does on every visit.
  Future<ZikrContentViewerLoadedState> open({int? zikrOrder}) async {
    final db = _FakeAzkarDB();
    final bloc = ZikrContentViewerBloc(
      HomeBloc(
        ZikrSourceFilterCubit(filterStorage),
        filterStorage,
        db,
        _FakeBookmarksDB(),
      ),
      SettingsStorage(MemoryStorage()),
      filterStorage,
      db,
      ReadingProgressStorage(box, now: () => now),
    );
    blocs.add(bloc);
    bloc.add(ZikrContentViewerStartEvent(_title.id, zikrOrder: zikrOrder));
    return await bloc.stream.firstWhere(
      (state) => state is ZikrContentViewerLoadedState,
    ) as ZikrContentViewerLoadedState;
  }

  ZikrContentViewerBloc current() => blocs.last;

  ZikrContentViewerLoadedState loaded() =>
      current().state as ZikrContentViewerLoadedState;

  /// Counts the zikr with [id] once, and waits for it to be saved.
  Future<void> count(int id) async {
    current().add(
      ZikrContentViewerDecreaseEvent(
        loaded().azkar.firstWhere((zikr) => zikr.id == id),
      ),
    );
    await pumpEventQueue();
  }

  Map<int, int> counts(ZikrContentViewerLoadedState state) =>
      {for (final zikr in state.azkar) zikr.id: zikr.count};

  test('a section reopened the same day is as it was left', () async {
    await open();
    await count(1);
    await count(2);
    final left = loaded();
    await current().close();

    now = DateTime(2026, 10, 15, 22);
    final reopened = await open();

    expect(counts(reopened), {1: 0, 2: 2, 3: 1, 4: 0});
    expect(reopened.finishedCount, left.finishedCount);
    expect(reopened.finishedCount, 1);
    expect(reopened.initialCounts, {1: 1, 2: 3, 3: 1, 4: 0});
    expect(reopened.resumeZikrId, 2);
    expect(reopened.activeZikr?.id, 2);
    expect(reopened.hasProgress, isTrue);
  });

  test('a section reopened the next day starts fresh', () async {
    await open();
    await count(1);
    await count(2);
    await current().close();

    now = DateTime(2026, 10, 16, 0, 5);
    final reopened = await open();

    expect(counts(reopened), {1: 1, 2: 3, 3: 1, 4: 0});
    expect(reopened.finishedCount, 0);
    expect(reopened.resumeZikrId, isNull);
    expect(reopened.activeZikrIndex, 0);
    expect(reopened.hasProgress, isFalse);
  });

  test('a section opened from search goes to the result, counts kept',
      () async {
    await open();
    await count(1);
    await count(2);
    await current().close();

    final reopened = await open(zikrOrder: 3);

    expect(counts(reopened), {1: 0, 2: 2, 3: 1, 4: 0});
    expect(reopened.resumeZikrId, isNull);
    expect(reopened.activeZikr?.order, 3);
  });

  test('a saved zikr no longer listed is ignored, a count is never raised',
      () async {
    await ReadingProgressStorage(box, now: () => now).write(
      _title.id,
      const ReadingProgress(counts: {2: 9, 3: 0, 99: 1}, zikrId: 99),
    );

    final opened = await open();

    expect(counts(opened), {1: 1, 2: 3, 3: 0, 4: 0});
    expect(opened.finishedCount, 1);
    expect(opened.resumeZikrId, isNull);
    expect(opened.activeZikrIndex, 0);
  });

  test('scrolling saves the zikr in view', () async {
    await open();
    current().add(const ZikrContentViewerFocusEvent(2));
    await pumpEventQueue();
    await current().close();

    final reopened = await open();

    expect(reopened.resumeZikrId, 3);
    expect(reopened.hasProgress, isFalse);
  });

  test('starting again restores the book and forgets the progress', () async {
    await open();
    await count(1);
    await count(2);

    current().add(ZikrContentViewerRestartEvent());
    await pumpEventQueue();

    expect(counts(loaded()), {1: 1, 2: 3, 3: 1, 4: 0});
    expect(loaded().activeZikrIndex, 0);
    expect(loaded().resumeZikrId, isNull);
    expect(loaded().hasProgress, isFalse);
    await current().close();

    final reopened = await open();

    expect(counts(reopened), {1: 1, 2: 3, 3: 1, 4: 0});
    expect(reopened.resumeZikrId, isNull);
    expect(box.hasData('reading_progress_${_title.id}'), isFalse);
  });
}
