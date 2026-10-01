part of 'zikr_content_viewer_bloc.dart';

sealed class ZikrContentViewerState extends Equatable {
  const ZikrContentViewerState();

  @override
  List<Object> get props => [];
}

final class ZikrContentViewerLoadingState extends ZikrContentViewerState {}

final class ZikrContentViewerLoadedState extends ZikrContentViewerState {
  final List<Zikr> azkar;
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

  /// Share of counted azkar finished; a section with nothing to count
  /// reports how far the reader has paged instead.
  double progress() {
    if (azkar.isEmpty) return 1;
    final counted = azkar.where(isCounted).toList();
    if (counted.isEmpty) return (activeZikrIndex + 1) / azkar.length;
    final done = counted.where((zikr) => zikr.count == 0).length;
    return done / counted.length;
  }

  /// The first counted zikr not yet finished, or -1 when none is left; the
  /// volume keys count it and the page brings it into view.
  int get currentIndex =>
      azkar.indexWhere((zikr) => isCounted(zikr) && zikr.count > 0);

  Zikr? get currentZikr {
    final index = currentIndex;
    return index == -1 ? null : azkar[index];
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
