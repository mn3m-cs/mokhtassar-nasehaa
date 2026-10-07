import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Top of the home page: the app's name and its source book, with search and
/// settings; the reader's favourite sections as tiles; and the heading of the
/// index.
class HomeHeader extends StatelessWidget {
  final List<ZikrTitle> favourites;

  const HomeHeader({super.key, required this.favourites});

  static const Map<int, IconData> _icons = {
    1: Icons.wb_twilight,
    2: Icons.nights_stay_outlined,
    4: Icons.wb_sunny_outlined,
    16: Icons.mosque_outlined,
    18: Icons.bed_outlined,
    49: Icons.luggage_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "زاد الذاكر",
                      style: TextStyle(
                        fontFamily: "Kitab",
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // The book's title as its cover prints it.
                    Text(
                      "مختصر النصيحة في الأذكار والأدعية الصحيحة",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: .65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "البحث",
                icon: const Icon(Icons.search),
                onPressed: () => context
                    .read<HomeBloc>()
                    .add(const HomeToggleSearchEvent(true)),
              ),
              IconButton(
                tooltip: "الإعدادات",
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          if (favourites.isNotEmpty) ...[
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                for (final title in favourites)
                  _Tile(title: title, icon: _icons[title.id] ?? Icons.bookmark),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
            child: Text(
              "الفهرس",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ZikrTitle title;
  final IconData icon;

  const _Tile({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: homeCardColor(colorScheme),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          ZikrContentViewerScreen.route(zikrTitleId: title.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              Text(
                title.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lighter surface the home tiles and index rows sit on.
Color homeCardColor(ColorScheme colorScheme) => Color.alphaBlend(
      colorScheme.surface.withValues(alpha: .7),
      colorScheme.surfaceContainerHighest,
    );
