import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:flutter/material.dart';

class SectionRow {
  final ZikrTitle title;
  final int localOrder;
  final int depth;
  final bool isExpanded;
  final VoidCallback toggle;

  const SectionRow({
    required this.title,
    required this.localOrder,
    required this.depth,
    required this.isExpanded,
    required this.toggle,
  });
}

typedef SectionItemBuilder = Widget Function(
  BuildContext context,
  SectionRow row,
);

class SectionBrowser extends StatefulWidget {
  final List<ZikrTitle> titles;
  final SectionItemBuilder itemBuilder;

  const SectionBrowser({
    super.key,
    required this.titles,
    required this.itemBuilder,
  });

  @override
  State<SectionBrowser> createState() => _SectionBrowserState();
}

class _SectionBrowserState extends State<SectionBrowser> {
  final Set<int> _expanded = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant SectionBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.titles, widget.titles)) return;
    final availableIds = widget.titles.map((title) => title.id).toSet();
    _expanded.retainAll(availableIds);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle(int id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  List<SectionRow> _visibleRows() {
    final children = <int?, List<ZikrTitle>>{};
    for (final title in widget.titles) {
      children.putIfAbsent(title.parentId, () => []).add(title);
    }
    for (final siblings in children.values) {
      siblings.sort((a, b) => a.order.compareTo(b.order));
    }

    final rows = <SectionRow>[];
    void visit(int? parentId, int depth) {
      final siblings = children[parentId] ?? const <ZikrTitle>[];
      for (var index = 0; index < siblings.length; index++) {
        final title = siblings[index];
        final isExpanded = _expanded.contains(title.id);
        rows.add(
          SectionRow(
            title: title,
            localOrder: index + 1,
            depth: depth,
            isExpanded: isExpanded,
            toggle: () => _toggle(title.id),
          ),
        );
        if (isExpanded) visit(title.id, depth + 1);
      }
    }

    visit(null, 0);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visibleRows();
    if (rows.isEmpty) {
      return const Center(child: Text('لا توجد أقسام أو أذكار هنا'));
    }
    return ListView.builder(
      key: const PageStorageKey<String>('section-tree'),
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) => widget.itemBuilder(context, rows[index]),
    );
  }
}
