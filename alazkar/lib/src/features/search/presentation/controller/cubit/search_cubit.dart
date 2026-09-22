import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/search/data/models/located_search_result.dart';
import 'package:alazkar/src/features/search/data/models/search_for.dart';
import 'package:alazkar/src/features/search/data/models/search_type.dart';
import 'package:alazkar/src/features/search/data/models/title_paths.dart';
import 'package:alazkar/src/features/search/domain/repository/search_repo.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final TextEditingController searchController = TextEditingController();
  late final PagingController<int, LocatedSearchResult<ZikrTitle>>
      titlePagingController;
  late final PagingController<int, LocatedSearchResult<Zikr>>
      contentPagingController;
  Map<int, String> _titlePaths = const {};

  ///
  final HomeBloc homeBloc;
  final ZikrFilterStorage zikrFilterStorage;
  final AzkarDBHelper azkarDBHelper;
  final BookmarksDBHelper bookmarksDBHelper;
  final SearchRepo searchRepo;
  SearchCubit(
    this.homeBloc,
    this.zikrFilterStorage,
    this.azkarDBHelper,
    this.bookmarksDBHelper,
    this.searchRepo,
  ) : super(const SearchLoadingState()) {
    homeBloc.stream.listen((event) {
      final homeBlocState = homeBloc.state;
      if (homeBlocState is! HomeLoadedState) return;
      final state = this.state;
      if (state is! SearchLoadedState) return;
    });

    titlePagingController = PagingController(firstPageKey: 0)
      ..addPageRequestListener(fetchPage);

    contentPagingController = PagingController(firstPageKey: 0)
      ..addPageRequestListener(fetchPage);

    searchController.addListener(() {
      EasyDebounce.debounce(
        'search',
        const Duration(milliseconds: 500),
        () {
          updateSearchText(searchController.text);
        },
      );
    });
  }

  Future start() async {
    _titlePaths = buildTitlePaths(await azkarDBHelper.getAllTitles());
    final state = SearchLoadedState(
      searchText: "",
      searchType: searchRepo.searchType,
      searchFor: searchRepo.searchFor,
      searchResultCount: 0,
    );

    emit(state);
  }

  Future fetchPage(int pageKey) async {
    final state = this.state;
    if (state is! SearchLoadedState) return;

    switch (state.searchFor) {
      case SearchFor.title:
        searchTitleByName(pageKey, state);
      case SearchFor.content:
        searchContent(pageKey, state);
    }
  }

  Future searchContent(int offset, SearchLoadedState state) async {
    try {
      final (count, content) = await azkarDBHelper.searchContent(
        searchText: state.searchText,
        searchType: state.searchType,
        limit: state.pageSize,
        offset: offset,
      );

      emit(state.copyWith(searchResultCount: count));

      final locatedContent = content
          .map(
            (zikr) => LocatedSearchResult(
              value: zikr,
              path: _titlePaths[zikr.titleId] ?? '',
            ),
          )
          .toList();
      final isLastPage = locatedContent.length < state.pageSize;
      if (isLastPage) {
        contentPagingController.appendLastPage(locatedContent);
      } else {
        final nextPageKey = offset + locatedContent.length;
        contentPagingController.appendPage(locatedContent, nextPageKey);
      }
    } catch (e) {
      contentPagingController.error = e;
    }
  }

  Future searchTitleByName(int offset, SearchLoadedState state) async {
    try {
      final (count, titles) = await azkarDBHelper.searchTitleByName(
        searchText: state.searchText,
        searchType: state.searchType,
        limit: state.pageSize,
        offset: offset,
      );

      emit(state.copyWith(searchResultCount: count));

      final locatedTitles = titles
          .map(
            (title) => LocatedSearchResult(
              value: title,
              path: _titlePaths[title.id] ?? title.name,
            ),
          )
          .toList();
      final isLastPage = titles.length < state.pageSize;
      if (isLastPage) {
        titlePagingController.appendLastPage(locatedTitles);
      } else {
        final nextPageKey = offset + titles.length;
        titlePagingController.appendPage(locatedTitles, nextPageKey);
      }
    } catch (e) {
      titlePagingController.error = e;
    }
  }

  ///MARK: Search header
  Future _startNewSearch() async {
    final state = this.state;
    if (state is! SearchLoadedState) return;

    switch (state.searchFor) {
      case SearchFor.title:
        titlePagingController.refresh();

      case SearchFor.content:
        contentPagingController.refresh();
    }
  }

  ///MARK: Search text

  Future updateSearchText(String searchText) async {
    final state = this.state;
    if (state is! SearchLoadedState) return;

    emit(
      state.copyWith(
        searchText: searchText,
      ),
    );

    _startNewSearch();
  }

  ///MARK: SearchType
  Future changeSearchType(SearchType searchType) async {
    final state = this.state;
    if (state is! SearchLoadedState) return;

    await searchRepo.setSearchType(searchType);

    emit(state.copyWith(searchType: searchType));
    _startNewSearch();
  }

  ///MARK: Search For
  Future changeSearchFor(SearchFor searchFor) async {
    final state = this.state;
    if (state is! SearchLoadedState) return;

    await searchRepo.setSearchFor(searchFor);

    emit(state.copyWith(searchFor: searchFor));
    _startNewSearch();
  }

  ///MARK: clear
  Future clear() async {
    final state = this.state;
    if (state is! SearchLoadedState) return;

    searchController.clear();
  }

  @override
  Future<void> close() {
    titlePagingController.dispose();
    contentPagingController.dispose();
    searchController.dispose();
    EasyDebounce.cancel('search');
    return super.close();
  }
}
