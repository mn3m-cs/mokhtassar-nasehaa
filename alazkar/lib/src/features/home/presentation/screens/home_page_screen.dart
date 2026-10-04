import 'package:alazkar/src/core/widgets/loading.dart';
import 'package:alazkar/src/features/home/presentation/components/home_header.dart';
import 'package:alazkar/src/features/home/presentation/components/index_row.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePageScreen extends StatelessWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: context.read<HomeBloc>(),
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const Loading();
        }
        if (state.isSearching) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              context.read<HomeBloc>().add(const HomeToggleSearchEvent(false));
            },
            child: const SearchScreen(),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: SectionBrowser(
              titles: state.titlesToShow,
              header: HomeHeader(favourites: state.favouriteTitles()),
              itemBuilder: (context, row) => IndexRow(row: row),
            ),
          ),
        );
      },
    );
  }
}
