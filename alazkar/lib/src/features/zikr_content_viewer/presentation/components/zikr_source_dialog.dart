import 'package:alazkar/src/core/models/zikr.dart';
import 'package:flutter/material.dart';

/// The book's source for a zikr: its takhrij and footnotes, gradings
/// included in the book's own words.
Future<void> showZikrSourceDialog(BuildContext context, Zikr zikr) {
  return showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: Icon(
          Icons.menu_book_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text("المصدر"),
        content: SingleChildScrollView(
          child: Text(
            zikr.source,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
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
