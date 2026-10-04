part of 'zikr_content_viewer_bloc.dart';

sealed class ZikrContentViewerEvent extends Equatable {
  const ZikrContentViewerEvent();

  @override
  List<Object?> get props => [];
}

class ZikrContentViewerStartEvent extends ZikrContentViewerEvent {
  final int zikrTitleId;
  final int? zikrOrder;

  const ZikrContentViewerStartEvent(this.zikrTitleId, {this.zikrOrder});

  @override
  List<Object?> get props => [zikrTitleId, zikrOrder];
}

class ZikrContentViewerDecreaseEvent extends ZikrContentViewerEvent {
  final Zikr zikr;

  const ZikrContentViewerDecreaseEvent(this.zikr);

  @override
  List<Object> get props => [zikr];
}

class ZikrContentViewerCopyEvent extends ZikrContentViewerEvent {
  final Zikr zikr;

  const ZikrContentViewerCopyEvent(this.zikr);

  @override
  List<Object> get props => [zikr];
}

class ZikrContentViewerShareEvent extends ZikrContentViewerEvent {
  final Zikr zikr;

  const ZikrContentViewerShareEvent(this.zikr);

  @override
  List<Object> get props => [zikr];
}

class ZikrContentViewerNextTitleEvent extends ZikrContentViewerEvent {}

class ZikrContentViewerPreviousTitleEvent extends ZikrContentViewerEvent {}

/// The reader scrolled; [index] is the zikr now in view.
class ZikrContentViewerFocusEvent extends ZikrContentViewerEvent {
  final int index;

  const ZikrContentViewerFocusEvent(this.index);

  @override
  List<Object> get props => [index];
}
