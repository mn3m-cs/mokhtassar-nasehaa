// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeLoadingState extends HomeState {}

/// A tile on the home page: a home card, or a favourite section of the index.
final class HomeTile extends Equatable {
  final HomeCard? card;
  final ZikrTitle? title;

  const HomeTile.card(HomeCard this.card) : title = null;
  const HomeTile.section(ZikrTitle this.title) : card = null;

  String get name => card?.name ?? title!.name;

  /// The card's id, or the section's.
  int get id => card?.id ?? title!.id;

  @override
  List<Object?> get props => [card?.id, title];
}

final class HomeLoadedState extends HomeState {
  final List<ZikrTitle> titles;
  final List<ZikrTitle> titlesToShow;
  final bool isSearching;
  final List<int> favouriteTitlesIds;

  /// For each home card the filters show, by id, the index section its first
  /// zikr sits in.
  final Map<int, int> cardSections;

  const HomeLoadedState({
    required this.titles,
    required this.titlesToShow,
    required this.isSearching,
    required this.favouriteTitlesIds,
    required this.cardSections,
  });

  /// The favourites, in the order the book reads them. A favourite home card
  /// stands where the section of its first zikr stands, even when the
  /// filters hide that section; a favourite section shows when it is shown.
  List<HomeTile> favouriteTiles() {
    final shownIds = titlesToShow.map((title) => title.id).toSet();
    final tiles = <HomeTile>[];
    for (final title in _bookOrder()) {
      for (final card in kHomeCards) {
        if (cardSections[card.id] == title.id &&
            favouriteTitlesIds.contains(card.favouriteId)) {
          tiles.add(HomeTile.card(card));
        }
      }
      if (shownIds.contains(title.id) &&
          favouriteTitlesIds.contains(title.id)) {
        tiles.add(HomeTile.section(title));
      }
    }
    return tiles;
  }

  /// Shown sections in the order the book reads them: depth-first through
  /// the index, siblings by their local order, categories skipped.
  List<ZikrTitle> readingOrder() {
    final shownIds = titlesToShow.map((title) => title.id).toSet();
    return _bookOrder().where((title) => shownIds.contains(title.id)).toList();
  }

  /// The first shown section after ([step] 1) or before ([step] -1) the
  /// section [fromId] in book order, if any. [fromId] may be a section the
  /// filters hide, as the first or last section of a home card can be.
  ZikrTitle? shownSectionFrom(int fromId, int step) {
    final shownIds = titlesToShow.map((title) => title.id).toSet();
    final order = _bookOrder();
    final from = order.indexWhere((title) => title.id == fromId);
    if (from == -1) return null;
    for (var i = from + step; i >= 0 && i < order.length; i += step) {
      if (shownIds.contains(order[i].id)) return order[i];
    }
    return null;
  }

  /// Every section in the order the book reads it, shown or not.
  List<ZikrTitle> _bookOrder() {
    final children = <int?, List<ZikrTitle>>{};
    for (final title in titles) {
      children.putIfAbsent(title.parentId, () => []).add(title);
    }
    for (final siblings in children.values) {
      siblings.sort((a, b) => a.order.compareTo(b.order));
    }

    final ordered = <ZikrTitle>[];
    void visit(int? parentId) {
      for (final title in children[parentId] ?? const <ZikrTitle>[]) {
        if (title.nodeType == ZikrTitleNodeType.content) {
          ordered.add(title);
        }
        visit(title.id);
      }
    }

    visit(null);
    return ordered;
  }

  @override
  List<Object> get props => [
        titles,
        titlesToShow,
        isSearching,
        favouriteTitlesIds,
        cardSections,
      ];

  HomeLoadedState copyWith({
    List<ZikrTitle>? titles,
    List<ZikrTitle>? titlesToShow,
    bool? isSearching,
    List<int>? favouriteTitlesIds,
    Map<int, int>? cardSections,
  }) {
    return HomeLoadedState(
      titles: titles ?? this.titles,
      titlesToShow: titlesToShow ?? this.titlesToShow,
      isSearching: isSearching ?? this.isSearching,
      favouriteTitlesIds: favouriteTitlesIds ?? this.favouriteTitlesIds,
      cardSections: cardSections ?? this.cardSections,
    );
  }
}
