part of 'zikr_content_viewer_bloc.dart';

sealed class ZikrContentViewerEvent extends Equatable {
  const ZikrContentViewerEvent();

  @override
  List<Object?> get props => [];
}

class ZikrContentViewerStartEvent extends ZikrContentViewerEvent {
  final int zikrTitleId;
  final int? zikrOrder;

  /// Opens the section on its last zikr, for reading backwards.
  final bool fromEnd;
  const ZikrContentViewerStartEvent(
    this.zikrTitleId, {
    this.zikrOrder,
    this.fromEnd = false,
  });

  @override
  List<Object?> get props => [zikrTitleId, zikrOrder, fromEnd];
}

class ZikrContentViewerDecreaseEvent extends ZikrContentViewerEvent {
  final Zikr zikr;

  const ZikrContentViewerDecreaseEvent(this.zikr);

  @override
  List<Object> get props => [zikr];
}

class ZikrContentViewerPageChangeEvent extends ZikrContentViewerEvent {
  final int index;

  const ZikrContentViewerPageChangeEvent(this.index);

  @override
  List<Object> get props => [index];
}

class ZikrContentViewerCopyEvent extends ZikrContentViewerEvent {}

class ZikrContentViewerShareEvent extends ZikrContentViewerEvent {}

class ZikrContentViewerNextTitleEvent extends ZikrContentViewerEvent {}

class ZikrContentViewerPerviousTitleEvent extends ZikrContentViewerEvent {
  final bool fromEnd;

  const ZikrContentViewerPerviousTitleEvent({this.fromEnd = false});

  @override
  List<Object> get props => [fromEnd];
}
