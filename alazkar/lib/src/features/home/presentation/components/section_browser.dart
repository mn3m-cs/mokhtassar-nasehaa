import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:flutter/material.dart';

class SectionRow {
  final ZikrTitle title;
  final int localOrder;
  final int depth;
  final bool isExpanded;
  final VoidCallback toggle;

  /// Where the row sits among the visible rows, so a list can draw them as
  /// one rounded group.
  final bool isFirst;
  final bool isLast;

  const SectionRow({
    required this.title,
    required this.localOrder,
    required this.depth,
    required this.isExpanded,
    required this.toggle,
    this.isFirst = false,
    this.isLast = false,
  });
}

typedef SectionItemBuilder = Widget Function(
  BuildContext context,
  SectionRow row,
);

class SectionBrowser extends StatefulWidget {
  final List<ZikrTitle> titles;
  final SectionItemBuilder itemBuilder;

  /// Scrolls with the rows, above them.
  final Widget? header;

  const SectionBrowser({
    super.key,
    required this.titles,
    required this.itemBuilder,
    this.header,
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
    return [
      for (var index = 0; index < rows.length; index++)
        SectionRow(
          title: rows[index].title,
          localOrder: rows[index].localOrder,
          depth: rows[index].depth,
          isExpanded: rows[index].isExpanded,
          toggle: rows[index].toggle,
          isFirst: index == 0,
          isLast: index == rows.length - 1,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visibleRows();
    if (rows.isEmpty) {
      return const Center(child: Text('لا توجد أقسام أو أذكار هنا'));
    }
    final header = widget.header;
    final offset = header == null ? 0 : 1;
    return ListView.builder(
      key: const PageStorageKey<String>('section-tree'),
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length + offset,
      itemBuilder: (context, index) => header != null && index == 0
          ? header
          : widget.itemBuilder(context, rows[index - offset]),
    );
  }
}
