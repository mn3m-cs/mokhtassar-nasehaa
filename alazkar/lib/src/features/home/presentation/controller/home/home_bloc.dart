import 'dart:async';

import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/models/home_card.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/core/utils/app_print.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_list_extension.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ZikrSourceFilterCubit zikrSourceFilterCubit;
  final ZikrFilterStorage zikrFilterStorage;
  late StreamSubscription zikrSourceFilterCubitStram;
  final AzkarDBHelper azkarDBHelper;
  final BookmarksDBHelper bookmarksDBHelper;
  HomeBloc(
    this.zikrSourceFilterCubit,
    this.zikrFilterStorage,
    this.azkarDBHelper,
    this.bookmarksDBHelper,
  ) : super(HomeLoadingState()) {
    zikrSourceFilterCubitStram =
        zikrSourceFilterCubit.stream.listen(zikrSourceFilterCubitChanged);

    on<HomeStartEvent>(_start);

    on<HomeToggleSearchEvent>(_search);

    on<HomeBookmarkTitleEvent>(_bookmarkTitle);
    on<HomeUnBookmarkTitleEvent>(_unBookmarkTitle);
    on<HomeBookmarksChangedEvent>(_bookmarksChanged);
    on<HomeFiltersChange>(_handleSettingsFiltersChanges);
  }

  Future<void> _start(
    HomeStartEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoadingState());

    final List<ZikrTitle> titlesToSet;

    /// Get titles form db
    final List<ZikrTitle> dbTitles = (await azkarDBHelper.getAllTitles())
      ..sort(
        (a, b) => a.order.compareTo(b.order),
      );

    /// Wire bookmaked data
    final List<int> favouriteTitlesIds =
        await bookmarksDBHelper.getAllFavoriteTitles();

    /// Filters
    final filters = zikrFilterStorage.getAllFilters();
    titlesToSet = await applyFiltersOnTitles(dbTitles, zikrFilters: filters);

    emit(
      HomeLoadedState(
        titles: dbTitles,
        titlesToShow: titlesToSet,
        isSearching: false,
        favouriteTitlesIds: favouriteTitlesIds,
        cardSections: await cardSectionsOf(filters),
      ),
    );
  }

  /// For each home card with a zikr the [filters] show, the index section its
  /// first zikr sits in. A card none of whose azkar is in the database is
  /// left out, and the log says so.
  Future<Map<int, int>> cardSectionsOf(List<Filter> filters) async {
    final rows = await azkarDBHelper.getContentByIds([
      for (final card in kHomeCards) ...card.zikrIds,
    ]);
    final byId = {for (final zikr in rows) zikr.id: zikr};
    final sections = <int, int>{};
    for (final card in kHomeCards) {
      final azkar = [
        for (final id in card.zikrIds)
          if (byId[id] case final zikr?) zikr,
      ];
      if (azkar.isEmpty) {
        appPrint("home card ${card.id}: none of its azkar is in the database");
        continue;
      }
      if (filters.getFilteredZikr(azkar).isEmpty) continue;
      sections[card.id] = azkar.first.titleId;
    }
    return sections;
  }

  Future<List<ZikrTitle>> applyFiltersOnTitles(
    List<ZikrTitle> titles, {
    List<Filter>? zikrFilters,
  }) async {
    final contentTitles = titles
        .where((title) => title.nodeType == ZikrTitleNodeType.content)
        .toList();
    final matchingContentTitles = await _contentTitlesMatchingFilters(
      contentTitles,
      zikrFilters ?? zikrFilterStorage.getAllFilters(),
    );
    return _titlesWithAncestors(titles, matchingContentTitles);
  }

  Future<List<ZikrTitle>> _contentTitlesMatchingFilters(
    List<ZikrTitle> titles,
    List<Filter> filters,
  ) async {
    final matchingTitles = <ZikrTitle>[];
    for (final title in titles) {
      final azkarFromDB = await azkarDBHelper.getContentByTitleId(title.id);
      final azkarToSet = filters.getFilteredZikr(azkarFromDB);
      if (azkarToSet.isNotEmpty) matchingTitles.add(title);
    }
    return matchingTitles;
  }

  List<ZikrTitle> _titlesWithAncestors(
    List<ZikrTitle> allTitles,
    List<ZikrTitle> contentTitles,
  ) {
    final titlesById = {for (final title in allTitles) title.id: title};
    final visibleIds = contentTitles.map((title) => title.id).toSet();
    for (final title in contentTitles) {
      var parentId = title.parentId;
      while (parentId != null && visibleIds.add(parentId)) {
        parentId = titlesById[parentId]?.parentId;
      }
    }
    return allTitles.where((title) => visibleIds.contains(title.id)).toList();
  }

  Future<void> _search(
    HomeToggleSearchEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    emit(
      state.copyWith(
        isSearching: event.isSearching,
      ),
    );
  }

  Future<void> _bookmarkTitle(
    HomeBookmarkTitleEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    await bookmarksDBHelper.addTitleToFavourite(titleId: event.zikrTitleId);

    add(HomeBookmarksChangedEvent());
  }

  Future<void> _unBookmarkTitle(
    HomeUnBookmarkTitleEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    await bookmarksDBHelper.deleteTitleFromFavourite(
      titleId: event.zikrTitleId,
    );

    add(HomeBookmarksChangedEvent());
  }

  Future<void> _bookmarksChanged(
    HomeBookmarksChangedEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    final List<int> favouriteTitlesIds =
        await bookmarksDBHelper.getAllFavoriteTitles();

    emit(
      state.copyWith(favouriteTitlesIds: favouriteTitlesIds),
    );
  }

  @override
  Future<void> close() {
    zikrSourceFilterCubitStram.cancel();
    return super.close();
  }

  Future<void> zikrSourceFilterCubitChanged(
    ZikrSourceFilterState filterState,
  ) async {
    appPrint(
      "from homeBLoc filters chaanged ${filterState.filters.where((f) => f.isActivated).length}",
    );

    add(HomeFiltersChange(filterState.filters));
  }

  Future<void> _handleSettingsFiltersChanges(
    HomeFiltersChange event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    final List<ZikrTitle> titleToView = await applyFiltersOnTitles(
      List.of(state.titles),
      zikrFilters: event.filters,
    );

    emit(
      state.copyWith(
        titlesToShow: titleToView,
        cardSections: await cardSectionsOf(event.filters),
      ),
    );
  }
}
