import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const title = ZikrTitle(id: 1, order: 1, name: 'قسم', freq: 'd');

  Zikr zikr(int id, int count) => Zikr(
        id: id,
        titleId: 1,
        order: id,
        body: 'نص',
        source: '',
        fadl: '',
        hokm: '',
        count: count,
        search: '',
        sourceIndex: '',
      );

  ZikrContentViewerLoadedState state({
    required List<Zikr> initial,
    List<Zikr>? current,
    int activeZikrIndex = 0,
  }) =>
      ZikrContentViewerLoadedState(
        zikrTitle: title,
        azkar: current ?? initial,
        activeZikrIndex: activeZikrIndex,
        initialCounts: {for (final z in initial) z.id: z.count},
      );

  test('a passage with no count is not treated as a zikr to count', () {
    final s = state(initial: [zikr(1, 0), zikr(2, 3)]);

    expect(s.isCounted(s.azkar[0]), isFalse);
    expect(s.isCounted(s.azkar[1]), isTrue);
  });

  test('the volume keys count the zikr in view', () {
    final initial = [zikr(1, 3), zikr(2, 3), zikr(3, 3)];

    expect(state(initial: initial, activeZikrIndex: 1).keyTarget?.id, 2);
  });

  test('the volume keys never count an unfinished zikr above the one in view',
      () {
    final initial = [zikr(1, 3), zikr(2, 3), zikr(3, 3)];

    expect(state(initial: initial, activeZikrIndex: 2).keyTarget?.id, 3);
  });

  test('past a finished zikr or a passage, the keys count the next one below',
      () {
    final initial = [zikr(1, 3), zikr(2, 1), zikr(3, 0), zikr(4, 2)];
    final s = state(
      initial: initial,
      current: [zikr(1, 3), zikr(2, 0), zikr(3, 0), zikr(4, 2)],
      activeZikrIndex: 1,
    );

    expect(s.keyTarget?.id, 4);
  });

  test('with nothing left to count below, the keys count nothing', () {
    final initial = [zikr(1, 3), zikr(2, 1)];
    final s = state(
      initial: initial,
      current: [zikr(1, 3), zikr(2, 0)],
      activeZikrIndex: 1,
    );

    expect(s.keyTarget, isNull);
  });
}
