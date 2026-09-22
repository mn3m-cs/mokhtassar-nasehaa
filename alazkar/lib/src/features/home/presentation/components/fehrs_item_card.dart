import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/home/presentation/components/bookmark_title_button.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/material.dart';

class FehrsItemCard extends StatelessWidget {
  final ZikrTitle zikrTitle;
  final int? displayOrder;
  final VoidCallback? onCategoryTap;

  const FehrsItemCard({
    super.key,
    required this.zikrTitle,
    this.displayOrder,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 25),
                child: Text((displayOrder ?? zikrTitle.order).toString()),
              ),
            ),
          ),
          if (zikrTitle.nodeType == ZikrTitleNodeType.category)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.folder_outlined),
            )
          else
            BookmarkTitleButton(titleId: zikrTitle.id),
        ],
      ),
      title: Text(zikrTitle.name),
      trailing: zikrTitle.nodeType == ZikrTitleNodeType.category
          ? const Icon(Icons.chevron_left)
          : null,
      onTap: () {
        if (zikrTitle.nodeType == ZikrTitleNodeType.category) {
          onCategoryTap?.call();
          return;
        }
        Navigator.push(
          context,
          ZikrContentViewerScreen.route(zikrTitleId: zikrTitle.id),
        );
      },
    );
  }
}
