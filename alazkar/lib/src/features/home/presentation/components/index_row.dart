import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/home_header.dart';
import 'package:alazkar/src/features/home/presentation/components/section_browser.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/material.dart';

/// One line of the index, drawn as part of a single rounded group;
/// categories open in place, sections open their page.
class IndexRow extends StatelessWidget {
  final SectionRow row;

  const IndexRow({super.key, required this.row});

  static const double _indentPerLevel = 20;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCategory = row.title.nodeType == ZikrTitleNodeType.category;
    final radius = BorderRadius.vertical(
      top: Radius.circular(row.isFirst ? 18 : 0),
      bottom: Radius.circular(row.isLast ? 18 : 0),
    );
    final mutedColor = colorScheme.onSurface.withValues(alpha: .55);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: homeCardColor(colorScheme),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: isCategory
              ? row.toggle
              : () => Navigator.push(
                    context,
                    ZikrContentViewerScreen.route(zikrTitleId: row.title.id),
                  ),
          child: Semantics(
            expanded: isCategory ? row.isExpanded : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: EdgeInsetsDirectional.only(
                start: 18 + row.depth * _indentPerLevel,
                end: 12,
              ),
              decoration: BoxDecoration(
                border: row.isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: .5),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        row.title.name,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight:
                              isCategory ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      isCategory
                          ? (row.isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more)
                          : Icons.chevron_left,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
