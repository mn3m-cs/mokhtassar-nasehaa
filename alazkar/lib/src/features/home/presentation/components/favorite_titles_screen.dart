import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/fehrs_item_card.dart';
import 'package:flutter/material.dart';

class FavoriteTitlesScreen extends StatelessWidget {
  final List<ZikrTitle> titles;

  const FavoriteTitlesScreen({super.key, required this.titles});

  @override
  Widget build(BuildContext context) {
    if (titles.isEmpty) {
      return const Center(child: Text('لا توجد أذكار مفضلة'));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: titles.length,
      itemBuilder: (context, index) => FehrsItemCard(
        zikrTitle: titles[index],
        displayOrder: index + 1,
      ),
    );
  }
}
