// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:alazkar/src/core/helpers/bookmarks_helper.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookmarkTitleButton extends StatelessWidget {
  static const Duration undoDuration = Duration(seconds: 6);

  final int titleId;
  const BookmarkTitleButton({
    super.key,
    required this.titleId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: context.read<HomeBloc>(),
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const SizedBox();
        }
        final isBookmarked = state.favouriteTitlesIds.contains(titleId);

        if (isBookmarked && BookmarksDBHelper.isPinned(titleId)) {
          return Semantics(
            label: 'ثابت في المفضلة',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (isBookmarked) {
          return IconButton(
            tooltip: "إزالة من المفضلة",
            onPressed: () {
              final bloc = context.read<HomeBloc>();
              bloc.add(HomeUnBookmarkTitleEvent(titleId));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('أُزيل من المفضلة'),
                    duration: undoDuration,
                    // A bar with an action stays until dismissed by default.
                    persist: false,
                    action: SnackBarAction(
                      label: 'تراجع',
                      onPressed: () =>
                          bloc.add(HomeBookmarkTitleEvent(titleId)),
                    ),
                  ),
                );
            },
            icon: Icon(
              Icons.bookmark,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          return IconButton(
            tooltip: "إضافة إلى المفضلة",
            onPressed: () {
              context.read<HomeBloc>().add(HomeBookmarkTitleEvent(titleId));
            },
            icon: const Icon(
              Icons.bookmark_add_outlined,
            ),
          );
        }
      },
    );
  }
}
