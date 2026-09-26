import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/fehrs_item_card.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:flutter/material.dart';

class FehrsScreen extends StatelessWidget {
  final List<ZikrTitle> titles;

  const FehrsScreen({super.key, required this.titles});

  @override
  Widget build(BuildContext context) {
    return SectionBrowser(
      titles: titles,
      itemBuilder: (context, row) {
        return FehrsItemCard(
          zikrTitle: row.title,
          displayOrder: row.localOrder,
          onCategoryTap: row.toggle,
          depth: row.depth,
          isExpanded: row.isExpanded,
        );
      },
    );
  }
}
