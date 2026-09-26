import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/bookmark_title_button.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/material.dart';

class FehrsItemCard extends StatelessWidget {
  static const double _indentPerLevel = 24;
  static const double _expanderWidth = 24;

  final ZikrTitle zikrTitle;
  final int? displayOrder;
  final VoidCallback? onCategoryTap;

  /// Tree depth of the row; null when the card is shown outside the index tree.
  final int? depth;
  final bool isExpanded;

  const FehrsItemCard({
    super.key,
    required this.zikrTitle,
    this.displayOrder,
    this.onCategoryTap,
    this.depth,
    this.isExpanded = false,
  });

  bool get _isCategory => zikrTitle.nodeType == ZikrTitleNodeType.category;

  @override
  Widget build(BuildContext context) {
    final inTree = depth != null;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: (depth ?? 0) * _indentPerLevel,
      ),
      child: Semantics(
        expanded: inTree && _isCategory ? isExpanded : null,
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inTree)
                SizedBox(
                  width: _expanderWidth,
                  child: _isCategory
                      ? Icon(
                          isExpanded ? Icons.expand_more : Icons.chevron_right,
                        )
                      : null,
                ),
              ExcludeSemantics(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 25),
                      child: Text((displayOrder ?? zikrTitle.order).toString()),
                    ),
                  ),
                ),
              ),
              if (_isCategory)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    isExpanded
                        ? Icons.folder_open_outlined
                        : Icons.folder_outlined,
                  ),
                )
              else
                BookmarkTitleButton(titleId: zikrTitle.id),
            ],
          ),
          title: Text(zikrTitle.name),
          onTap: () {
            if (_isCategory) {
              onCategoryTap?.call();
              return;
            }
            Navigator.push(
              context,
              ZikrContentViewerScreen.route(zikrTitleId: zikrTitle.id),
            );
          },
        ),
      ),
    );
  }
}
