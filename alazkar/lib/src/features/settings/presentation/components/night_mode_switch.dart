import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Night mode, moved here from the theme screen, which had nothing else left.
class NightModeSwitch extends StatelessWidget {
  const NightModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.brightness == Brightness.dark;
        return SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          value: isDark,
          title: const Text("المظهر الليلي"),
          onChanged: (value) {
            context
                .read<ThemeCubit>()
                .changeBrightness(value ? Brightness.dark : Brightness.light);
          },
        );
      },
    );
  }
}
