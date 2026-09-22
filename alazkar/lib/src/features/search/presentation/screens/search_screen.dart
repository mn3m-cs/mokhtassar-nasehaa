import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/core/widgets/loading.dart';
import 'package:alazkar/src/features/search/data/models/located_search_result.dart';
import 'package:alazkar/src/features/search/data/models/search_for.dart';
import 'package:alazkar/src/features/search/presentation/components/search_app_bar.dart';
import 'package:alazkar/src/features/search/presentation/components/search_content_card.dart';
import 'package:alazkar/src/features/search/presentation/components/search_filters_dialog.dart';
import 'package:alazkar/src/features/search/presentation/components/search_for_bar.dart';
import 'package:alazkar/src/features/search/presentation/components/search_result_viewer.dart';
import 'package:alazkar/src/features/search/presentation/components/search_title_card.dart';
import 'package:alazkar/src/features/search/presentation/controller/cubit/search_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Scaffold(
            body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              const SearchAppBar(),
              const SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SearchForBar(),
                    SearchFiltersButton(),
                  ],
                ),
              ),
            ];
          },
          body: state is! SearchLoadedState
              ? const Loading()
              : switch (state.searchFor) {
                  SearchFor.title =>
                    SearchResultViewer<LocatedSearchResult<ZikrTitle>>(
                      pagingController: sl<SearchCubit>().titlePagingController,
                      itemBuilder: (context, item, index) {
                        return SearchTitleCard(
                          title: item.value,
                          path: item.path,
                        );
                      },
                    ),
                  SearchFor.content =>
                    SearchResultViewer<LocatedSearchResult<Zikr>>(
                      pagingController:
                          sl<SearchCubit>().contentPagingController,
                      itemBuilder: (context, item, index) {
                        return SearchContentCard(
                          index: index,
                          zikr: item.value,
                          path: item.path,
                          searchText: state.searchText,
                        );
                      },
                    ),
                },
        ));
      },
    );
  }
}
