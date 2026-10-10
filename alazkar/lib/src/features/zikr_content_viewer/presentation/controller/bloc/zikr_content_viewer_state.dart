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

  /// A zikr the book offers in place of the one before it, printed «أو:».
  /// True when this tap ends a zikr that was to be said more than once.
  bool completesRepeated(Zikr zikr) =>
      zikr.count == 1 && (initialCounts[zikr.id] ?? 0) > 1;

  static bool isAlternative(Zikr zikr) => zikr.body.startsWith('أو:');

  /// The counted azkar grouped into choices: a zikr opens a choice, and the
  /// «أو:» alternatives after it join that choice. A choice is done once any
  /// one of its azkar is.
  List<List<Zikr>> get choices {
    final groups = <List<Zikr>>[];
    for (final zikr in azkar.where(isCounted)) {
      if (groups.isNotEmpty && isAlternative(zikr)) {
        groups.last.add(zikr);
      } else {
        groups.add([zikr]);
      }
    }
    return groups;
  }

  bool _choiceDone(List<Zikr> choice) => choice.any((zikr) => zikr.count == 0);

  /// Whether [zikr] still waits to be counted: it has repetitions left and
  /// no alternative of its choice is done.
  bool isPending(Zikr zikr) {
    if (!isCounted(zikr) || zikr.count == 0) return false;
    final choice = choices.firstWhere((group) => group.contains(zikr));
    return !_choiceDone(choice);
  }

  /// The zikr the volume keys count: the one in view while it is pending,
  /// else the next pending zikr below it, never one above.
  Zikr? get keyTarget {
    for (final zikr in azkar.skip(activeZikrIndex.clamp(0, azkar.length))) {
      if (isPending(zikr)) return zikr;
    }
    return null;
  }

  int get finishedCount => choices.where(_choiceDone).length;

  int get countedTotal => choices.length;

  Zikr? get activeZikr {
    if (azkar.isEmpty) return null;
    return azkar[activeZikrIndex.clamp(0, azkar.length - 1)];
  }

  @override
  List<Object> get props =>
      [azkar, zikrTitle, activeZikrIndex, initialCounts, sectionPath];
}
