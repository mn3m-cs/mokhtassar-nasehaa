import 'package:alazkar/src/core/models/zikr.dart';
import 'package:flutter/material.dart';

Future<void> showZikrSourceDialog(BuildContext context, Zikr zikr) {
  return showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final headingStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      );
      final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.6);
      return AlertDialog(
        icon: Icon(
          Icons.menu_book_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text("مصدر الذكر وحكمه"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (zikr.hokm.isNotEmpty) ...[
                Text("الحكم", style: headingStyle),
                const SizedBox(height: 8),
                Text(
                  zikr.hokm,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
                ),
              ],
              if (zikr.hokm.isNotEmpty && zikr.source.isNotEmpty)
                const Divider(height: 32),
              if (zikr.source.isNotEmpty) ...[
                Text("المصدر", style: headingStyle),
                const SizedBox(height: 8),
                Text(
                  zikr.source,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إغلاق"),
          ),
        ],
      );
    },
  );
}
