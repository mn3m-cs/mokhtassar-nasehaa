import 'package:flutter/material.dart';

class NoItemsFoundIndicatorBuilder extends StatelessWidget {
  final String searchText;
  const NoItemsFoundIndicatorBuilder({
    super.key,
    required this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search),
        const SizedBox(height: 10),
        Text(
          searchText.trim().isEmpty
              ? 'اكتب كلمة للبحث في الفهرس أو في نصوص الأذكار'
              : 'لا توجد نتائج\n"$searchText"',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
