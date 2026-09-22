import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/fehrs_item_card.dart';
import 'package:flutter/material.dart';

class SearchTitleCard extends StatelessWidget {
  final ZikrTitle title;
  final String path;

  const SearchTitleCard({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FehrsItemCard(zikrTitle: title),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 72, end: 16),
          child: Text(
            path,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
