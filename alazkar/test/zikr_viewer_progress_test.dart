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

  test('a passage with no count is not treated as a finished zikr', () {
    final s = state(initial: [zikr(1, 0), zikr(2, 3)]);

    expect(s.isCounted(s.azkar[0]), isFalse);
    expect(s.isCounted(s.azkar[1]), isTrue);
    expect(s.progress(), 0);
  });

  test('progress counts only the azkar that were counted down', () {
    final initial = [zikr(1, 0), zikr(2, 3), zikr(3, 1)];
    final s = state(
      initial: initial,
      current: [zikr(1, 0), zikr(2, 3), zikr(3, 0)],
    );

    expect(s.isCounted(s.azkar[2]), isTrue);
    expect(s.progress(), 0.5);
  });

  test('a reading-only section reports how far the reader has paged', () {
    final initial = [zikr(1, 0), zikr(2, 0), zikr(3, 0), zikr(4, 0)];

    expect(state(initial: initial).progress(), 0.25);
    expect(state(initial: initial, activeZikrIndex: 3).progress(), 1);
  });
}
