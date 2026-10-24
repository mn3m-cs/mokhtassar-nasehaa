part of 'zikr_content_viewer_bloc.dart';

sealed class ZikrContentViewerEvent extends Equatable {
  const ZikrContentViewerEvent();

  @override
  List<Object?> get props => [];
}

class ZikrContentViewerStartEvent extends ZikrContentViewerEvent {
  final int zikrTitleId;
  final int? zikrOrder;

  /// Opens this home card instead of the section [zikrTitleId].
  final HomeCard? card;

  const ZikrContentViewerStartEvent(
    this.zikrTitleId, {
    this.zikrOrder,
    this.card,
  });

  /// Opens [card] in one page.
  ZikrContentViewerStartEvent.card(HomeCard this.card)
      : zikrTitleId = card.id,
        zikrOrder = null;

  @override
  List<Object?> get props => [zikrTitleId, zikrOrder, card];
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

/// The reader starts the section again from the book's counts.
class ZikrContentViewerRestartEvent extends ZikrContentViewerEvent {}
