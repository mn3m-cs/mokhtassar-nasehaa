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

  @override
  List<Object?> get props => [card?.id, title];
}

final class HomeLoadedState extends HomeState {
  final List<ZikrTitle> titles;
  final List<ZikrTitle> titlesToShow;
  final bool isSearching;
  final List<int> favouriteTitlesIds;

  /// For each home card, by id, the index section its first zikr sits in.
  final Map<int, int> cardSections;

  const HomeLoadedState({
    required this.titles,
    required this.titlesToShow,
    required this.isSearching,
    required this.favouriteTitlesIds,
    this.cardSections = const {},
  });

  /// The favourites, in the order the book reads them. A favourite that is a
  /// home card shows the card, where the section of its first zikr stands;
  /// any other shows its section.
  List<HomeTile> favouriteTiles() {
    final tiles = <HomeTile>[];
    for (final title in readingOrder()) {
      for (final card in kHomeCards) {
        if (cardSections[card.id] == title.id &&
            favouriteTitlesIds.contains(card.favouriteId)) {
          tiles.add(HomeTile.card(card));
        }
      }
      if (favouriteTitlesIds.contains(title.id) &&
          homeCardByFavouriteId(title.id) == null) {
        tiles.add(HomeTile.section(title));
      }
    }
    return tiles;
  }

  /// Shown sections in the order the book reads them: depth-first through
  /// the index, siblings by their local order, categories skipped.
  List<ZikrTitle> readingOrder() {
    final shownIds = titlesToShow.map((title) => title.id).toSet();
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
        if (title.nodeType == ZikrTitleNodeType.content &&
            shownIds.contains(title.id)) {
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
  }) {
    return HomeLoadedState(
      titles: titles ?? this.titles,
      titlesToShow: titlesToShow ?? this.titlesToShow,
      isSearching: isSearching ?? this.isSearching,
      favouriteTitlesIds: favouriteTitlesIds ?? this.favouriteTitlesIds,
      cardSections: cardSections,
    );
  }
}
