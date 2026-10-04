part of 'zikr_content_viewer_bloc.dart';

sealed class ZikrContentViewerState extends Equatable {
  const ZikrContentViewerState();

  @override
  List<Object> get props => [];
}

final class ZikrContentViewerLoadingState extends ZikrContentViewerState {}

final class ZikrContentViewerLoadedState extends ZikrContentViewerState {
  final List<Zikr> azkar;

  /// The zikr the reader is on: the one last counted, or after a scroll the
  /// first one whose middle is on the page.
  final int activeZikrIndex;
  final ZikrTitle zikrTitle;

  /// Categories above [zikrTitle], empty for a top-level section.
  final String sectionPath;

  /// Repetitions each zikr starts with, by id; 0 marks a passage to read,
  /// not a zikr to count.
  final Map<int, int> initialCounts;

  /// Order of the zikr to bring into view on opening, from a search result.
  final int? focusOrder;

  const ZikrContentViewerLoadedState({
    required this.zikrTitle,
    required this.azkar,
    required this.activeZikrIndex,
    required this.initialCounts,
    this.sectionPath = '',
    this.focusOrder,
  });

  ZikrContentViewerLoadedState copyWith({
    List<Zikr>? azkar,
    int? activeZikrIndex,
  }) {
    return ZikrContentViewerLoadedState(
      zikrTitle: zikrTitle,
      azkar: azkar ?? this.azkar,
      activeZikrIndex: activeZikrIndex ?? this.activeZikrIndex,
      initialCounts: initialCounts,
      sectionPath: sectionPath,
      focusOrder: focusOrder,
    );
  }

  bool isCounted(Zikr zikr) => (initialCounts[zikr.id] ?? 0) > 0;

  /// The zikr the volume keys count: the one in view while it has
  /// repetitions left, else the next such zikr below it, never one above.
  Zikr? get keyTarget {
    for (final zikr in azkar.skip(activeZikrIndex.clamp(0, azkar.length))) {
      if (isCounted(zikr) && zikr.count > 0) return zikr;
    }
    return null;
  }

  int get finishedCount =>
      azkar.where((zikr) => isCounted(zikr) && zikr.count == 0).length;

  int get countedTotal => azkar.where(isCounted).length;

  Zikr? get activeZikr {
    if (azkar.isEmpty) return null;
    return azkar[activeZikrIndex.clamp(0, azkar.length - 1)];
  }

  @override
  List<Object> get props =>
      [azkar, zikrTitle, activeZikrIndex, initialCounts, sectionPath];
}
