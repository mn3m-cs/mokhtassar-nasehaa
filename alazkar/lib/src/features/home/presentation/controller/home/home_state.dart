// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeLoadingState extends HomeState {}

final class HomeLoadedState extends HomeState {
  final List<ZikrTitle> titles;
  final List<ZikrTitle> titlesToShow;
  final bool isSearching;
  final List<int> favouriteTitlesIds;

  const HomeLoadedState({
    required this.titles,
    required this.titlesToShow,
    required this.isSearching,
    required this.favouriteTitlesIds,
  });

  /// Favourite sections, in the order the book reads them.
  List<ZikrTitle> favouriteTitles() {
    return readingOrder()
        .where((title) => favouriteTitlesIds.contains(title.id))
        .toList();
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
    );
  }
}
