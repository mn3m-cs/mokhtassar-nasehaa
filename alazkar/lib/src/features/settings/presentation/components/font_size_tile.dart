import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Size of the azkar text, moved here from the reading page's toolbar.
class FontSizeTile extends StatelessWidget {
  const FontSizeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: const Text("حجم خط الأذكار"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "تصغير حجم الخط",
            onPressed: cubit.decreaseFontSize,
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            tooltip: "تكبير حجم الخط",
            onPressed: cubit.increaseFontSize,
            icon: const Icon(Icons.text_increase),
          ),
          IconButton(
            tooltip: "إعادة ضبط الخط",
            onPressed: cubit.restoreFontSize,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
