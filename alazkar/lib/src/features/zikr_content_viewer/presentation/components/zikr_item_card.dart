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
                width: double.infinity,
                height: widget.isCounted ? 72 : 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.isCounted) _RemainingCount(count: zikr.count),
                    PositionedDirectional(
                      end: 20,
                      child: Text(
                        _seenPercent == null ? "" : "$_seenPercent%",
                        semanticsLabel: _seenPercent == null
                            ? ""
                            : "قرأت $_seenPercent٪ من النص",
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: .65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Repetitions left for a counted zikr, kept below the text so it never
/// sits behind the words; a check mark once it is done.
class _RemainingCount extends StatelessWidget {
  final int count;

  const _RemainingCount({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = count == 0;
    return Semantics(
      label: done ? "تم العدّ" : "العدد المتبقي $count",
      excludeSemantics: true,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: .12),
        ),
        child: done
            ? Icon(Icons.check, color: colorScheme.onPrimary)
            : Text(
                "$count",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
      ),
    );
  }
}
