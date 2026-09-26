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

  /// Share of the text already on screen, or null when it all fits.
  int? _seenPercent;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _updateSeenPercent(ScrollMetrics metrics) {
    final int? seenPercent = metrics.maxScrollExtent <= 0
        ? null
        : ((metrics.pixels + metrics.viewportDimension) /
                (metrics.maxScrollExtent + metrics.viewportDimension) *
                100)
            .round()
            .clamp(0, 100);
    if (seenPercent != _seenPercent) {
      setState(() => _seenPercent = seenPercent);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final zikr = widget.zikr;
    final colorScheme = Theme.of(context).colorScheme;
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
              child: Text(
                zikr.count == 0 ? "تم" : zikr.count.toString(),
                style: TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary.withValues(alpha: .14),
                ),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (notification) =>
                      _updateSeenPercent(notification.metrics),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) =>
                        _updateSeenPercent(notification.metrics),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
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
              ),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    _seenPercent == null ? "" : "$_seenPercent%",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: .45),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
