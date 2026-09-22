import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/fehrs_item_card.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:alazkar/src/features/home/presentation/components/titles_freq_filters_card.dart';
import 'package:flutter/material.dart';

class FehrsScreen extends StatelessWidget {
  final List<ZikrTitle> titles;

  const FehrsScreen({super.key, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TitleFreqFilterCard(),
        Expanded(
          child: SectionBrowser(
            titles: titles,
            itemBuilder: (context, title, localOrder, openCategory) {
              return FehrsItemCard(
                zikrTitle: title,
                displayOrder: localOrder,
                onCategoryTap: openCategory,
              );
            },
          ),
        ),
      ],
    );
  }
}
