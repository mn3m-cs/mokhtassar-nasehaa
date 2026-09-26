import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_content_builder.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZikrItemCard extends StatefulWidget {
  final Zikr zikr;

  /// False for a passage that is read, not counted; it gets no counter.
  final bool isCounted;

  const ZikrItemCard({
    super.key,
    required this.zikr,
    this.isCounted = true,
  });

  @override
  State<ZikrItemCard> createState() => _ZikrItemCardState();
}

class _ZikrItemCardState extends State<ZikrItemCard> {
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreBelow = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _updateHasMoreBelow(ScrollMetrics metrics) {
    final hasMoreBelow = metrics.extentAfter > 8;
    if (hasMoreBelow != _hasMoreBelow) {
      setState(() => _hasMoreBelow = hasMoreBelow);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final zikr = widget.zikr;
    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    return InkWell(
      onTap: () {
        context
            .read<ZikrContentViewerBloc>()
            .add(ZikrContentViewerDecreaseEvent(zikr));
      },
      onLongPress: () {
        final SnackBar snackBar = SnackBar(
          content: Text(
              "الحكم: ${zikr.hokm}\n\nالمصدر:\n${zikr.source}\n\nرقم الذكر في المصدر:\n${zikr.sourceIndex}"),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          snackBar,
        );
      },
      child: Stack(
        children: [
          if (widget.isCounted)
            Center(
              child: Opacity(
                opacity: .5,
                child: Text(
                  zikr.count == 0 ? "تم" : zikr.count.toString(),
                  style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary.withValues(alpha: .1),
                  ),
                ),
              ),
            ),
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) =>
                _updateHasMoreBelow(notification.metrics),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _updateHasMoreBelow(notification.metrics),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    ZikrContentBuilder(
                      zikr: zikr,
                      enableDiacritics: true,
                      fontSize: context.read<ThemeCubit>().state.fontSize,
                    ),
                    if (zikr.fadl.isNotEmpty) ...[
                      const SizedBox(height: 50),
                    ],
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                key: const ValueKey('more-below-hint'),
                opacity: _hasMoreBelow ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 72,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [background.withValues(alpha: 0), background],
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_double_arrow_down,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
