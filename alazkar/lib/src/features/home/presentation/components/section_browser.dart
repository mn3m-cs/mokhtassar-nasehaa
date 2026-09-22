import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:flutter/material.dart';

typedef SectionItemBuilder = Widget Function(
  BuildContext context,
  ZikrTitle title,
  int localOrder,
  VoidCallback openCategory,
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
  final List<ZikrTitle> _path = [];
  final Map<int?, ScrollController> _scrollControllers = {};

  int? get _currentParentId => _path.isEmpty ? null : _path.last.id;

  ScrollController _controllerFor(int? parentId) =>
      _scrollControllers.putIfAbsent(parentId, ScrollController.new);

  List<ZikrTitle> get _visibleTitles => widget.titles
      .where((title) => title.parentId == _currentParentId)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  @override
  void didUpdateWidget(covariant SectionBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.titles, widget.titles) || _path.isEmpty) return;

    final availableIds = widget.titles.map((title) => title.id).toSet();
    final firstMissingIndex = _path.indexWhere(
      (category) => !availableIds.contains(category.id),
    );
    if (firstMissingIndex != -1) {
      _path.removeRange(firstMissingIndex, _path.length);
    }
  }

  void _openCategory(ZikrTitle category) {
    setState(() => _path.add(category));
  }

  void _goToDepth(int depth) {
    setState(() => _path.removeRange(depth, _path.length));
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = _visibleTitles;
    return PopScope(
      canPop: _path.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _path.isNotEmpty) _goToDepth(_path.length - 1);
      },
      child: Column(
        children: [
          if (_path.isNotEmpty)
            _Breadcrumbs(path: _path, onSelected: _goToDepth),
          Expanded(
            child: titles.isEmpty
                ? const Center(child: Text('لا توجد أقسام أو أذكار هنا'))
                : ListView.builder(
                    key: PageStorageKey<int?>(_currentParentId),
                    controller: _controllerFor(_currentParentId),
                    physics: const BouncingScrollPhysics(),
                    itemCount: titles.length,
                    itemBuilder: (context, index) {
                      final title = titles[index];
                      return widget.itemBuilder(
                        context,
                        title,
                        index + 1,
                        () => _openCategory(title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  final List<ZikrTitle> path;
  final ValueChanged<int> onSelected;

  const _Breadcrumbs({required this.path, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'مسار القسم',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () => onSelected(path.length - 1),
              icon: const Icon(Icons.arrow_forward),
            ),
            TextButton(
              onPressed: () => onSelected(0),
              child: const Text('الفهرس'),
            ),
            for (var index = 0; index < path.length; index++) ...[
              const Icon(Icons.chevron_left, size: 18),
              TextButton(
                onPressed: index == path.length - 1
                    ? null
                    : () => onSelected(index + 1),
                child: Text(path[index].name),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
