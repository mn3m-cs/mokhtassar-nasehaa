import 'package:alazkar/src/features/theme/domain/models/zikr_font.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Typeface of the azkar text; the picker shows each one on the same zikr so
/// the reader chooses by eye.
class ZikrFontTile extends StatelessWidget {
  const ZikrFontTile({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ThemeCubit>().state.zikrFont;
    return ListTile(
      leading: const Icon(Icons.font_download_outlined),
      title: const Text("خط الأذكار"),
      subtitle: Text(current.label),
      onTap: () => showDialog(
        context: context,
        builder: (_) => const _ZikrFontDialog(),
      ),
    );
  }
}

class _ZikrFontDialog extends StatelessWidget {
  const _ZikrFontDialog();

  static const String _sample = "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ";

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ThemeCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text("خط الأذكار"),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final font in ZikrFont.values)
            ListTile(
              selected: font == cubit.state.zikrFont,
              title: Text(
                _sample,
                style: TextStyle(
                  fontFamily: font.family,
                  fontSize: 24,
                  height: 1.8,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(font.label),
              trailing: font == cubit.state.zikrFont
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                cubit.changeZikrFont(font);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
