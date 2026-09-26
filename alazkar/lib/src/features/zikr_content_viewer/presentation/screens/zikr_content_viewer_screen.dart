import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/extension/extension_platform.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/core/widgets/loading.dart';
import 'package:alazkar/src/features/home/presentation/components/bookmark_title_button.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/app_bar_bottom.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/bottom_app_bar.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/shake_tutorial_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_report_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'package:shake/shake.dart';

class ZikrContentViewerScreen extends StatefulWidget {
  static const String routeName = "ZikrContentViewer";

  final int zikrTitleId;
  final int? zikrOrder;
  const ZikrContentViewerScreen({
    super.key,
    required this.zikrTitleId,
    this.zikrOrder,
  });

  static Route route({required int zikrTitleId, int? zikrOrder}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (_) => ZikrContentViewerScreen(
        zikrTitleId: zikrTitleId,
        zikrOrder: zikrOrder,
      ),
    );
  }

  @override
  State<ZikrContentViewerScreen> createState() =>
      _ZikrContentViewerScreenState();
}

class _ZikrContentViewerScreenState extends State<ZikrContentViewerScreen> {
  ShakeDetector? _shakeDetector;
  bool _dialogOpen = false;
  late final ZikrContentViewerBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ZikrContentViewerBloc>()
      ..add(ZikrContentViewerStartEvent(widget.zikrTitleId,
          zikrOrder: widget.zikrOrder));

    if (PlatformExtension.isPhone) {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: (event) {
          _showReportDialog();
        },
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showShakeTutorialIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    _bloc.close();
    super.dispose();
  }

  Future<void> _showShakeTutorialIfNeeded() async {
    final storage = sl<KVStorage>();
    const String key = 'has_shown_shake_tutorial';
    const String opensKey = 'viewer_open_count';
    final bool hasShown = storage.read<bool>(key) ?? false;
    if (hasShown) return;
    final int opens = (storage.read<int>(opensKey) ?? 0) + 1;
    await storage.write(opensKey, opens);

    /// A first-time reader came to read; the tip waits for the third visit.
    if (opens >= 3) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ShakeTutorialDialog(),
      );
      await storage.write(key, true);
    }
  }

  void _showReportDialog() {
    if (!mounted || _dialogOpen) return;

    final state = _bloc.state;
    if (state is! ZikrContentViewerLoadedState) return;

    final zikr = state.activeZikr;
    final zikrTitle = state.zikrTitle;
    if (zikr == null) return;

    setState(() {
      _dialogOpen = true;
    });

    showDialog(
      context: context,
      builder: (context) => ZikrReportDialog(
        zikr: zikr,
        zikrTitle: zikrTitle,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _dialogOpen = false;
        });
      }
    });
  }

  /// How far past the first or last zikr a drag must go to change section.
  static const double _crossSectionThreshold = 72;
  final Map<int, double> _edgeDrag = {};
  final Set<int> _crossedSection = {};

  /// With continuous reading on, dragging sideways past the last zikr, or up
  /// past the end of its text, opens the next section; dragging sideways
  /// before the first zikr opens the previous one at its end.
  bool _crossSectionEdge(ScrollNotification notification) {
    final depth = notification.depth;
    if (depth > 1) return false;
    if (notification is ScrollStartNotification ||
        notification is ScrollEndNotification) {
      _edgeDrag.remove(depth);
      _crossedSection.remove(depth);
      return false;
    }
    if (_crossedSection.contains(depth) ||
        !_bloc.settingsStorage.continuousReading) {
      return false;
    }

    final metrics = notification.metrics;
    var drag = _edgeDrag[depth] ?? 0;
    if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      drag += notification.overscroll;
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      if (metrics.pixels > metrics.maxScrollExtent) {
        drag = metrics.pixels - metrics.maxScrollExtent;
      } else if (metrics.pixels < metrics.minScrollExtent) {
        drag = metrics.pixels - metrics.minScrollExtent;
      }
    }
    _edgeDrag[depth] = drag;

    final state = _bloc.state;
    final onLastZikr = state is ZikrContentViewerLoadedState &&
        state.activeZikrIndex == state.azkar.length - 1;
    if (depth == 1 && !onLastZikr) return false;

    if (drag > _crossSectionThreshold) {
      _crossedSection.add(depth);
      _bloc.add(ZikrContentViewerNextTitleEvent());
    } else if (depth == 0 && drag < -_crossSectionThreshold) {
      _crossedSection.add(depth);
      _bloc.add(const ZikrContentViewerPerviousTitleEvent(fromEnd: true));
    }
    return false;
  }

  double getTextWidth(String text, TextStyle style, BuildContext context) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1, // Set to 1 for single line text
    );
    textPainter.layout(
      maxWidth: MediaQuery.of(context)
          .size
          .width, // You can adjust this width as needed
    );
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ZikrContentViewerBloc, ZikrContentViewerState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is! ZikrContentViewerLoadedState) {
            return const Loading();
          }
          const headerStyle = TextStyle(
            fontFamily: "Kitab",
            fontWeight: FontWeight.bold,
          );
          final Size screenSize = MediaQuery.of(context).size;
          final String breadcrumb = state.sectionPath.isEmpty
              ? state.zikrTitle.name
              : "${state.sectionPath} › ${state.zikrTitle.name}";
          final List<String> pathParts = state.sectionPath.isEmpty
              ? const []
              : state.sectionPath.split(' › ');
          final Color mutedColor =
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
          final bool isSliding =
              getTextWidth(breadcrumb, headerStyle, context) >
                  (screenSize.width * .5);
          return Scaffold(
            appBar: AppBar(
              title: isSliding
                  ? SizedBox(
                      height: 60,
                      child: Marquee(
                        text: breadcrumb,
                        blankSpace: screenSize.width,
                        pauseAfterRound: const Duration(seconds: 1),
                        accelerationCurve: Curves.easeInOut,
                        decelerationCurve: Curves.easeOut,
                        fadingEdgeEndFraction: 1,
                        fadingEdgeStartFraction: .5,
                        showFadingOnlyWhenScrolling: false,
                        style: headerStyle,
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          for (final category in pathParts) ...[
                            TextSpan(
                              text: category,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: mutedColor,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 22,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                          TextSpan(text: state.zikrTitle.name),
                        ],
                      ),
                      style: headerStyle,
                    ),
              centerTitle: true,
              actions: [BookmarkTitleButton(titleId: state.zikrTitle.id)],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Column(
                  children: [
                    ZikrContentViewerAppBarBottom(state: state),
                    LinearProgressIndicator(
                      semanticsLabel: "التقدم في الباب",
                      value: state.progress(),
                    ),
                  ],
                ),
              ),
            ),
            body: NotificationListener<ScrollNotification>(
              onNotification: _crossSectionEdge,
              child: PageView.builder(
                controller: _bloc.pageController,
                itemCount: state.azkar.length,
                itemBuilder: (context, index) {
                  final zikr = state.azkar[index];
                  return ZikrItemCard(
                    zikr: zikr,
                    isCounted: state.isCounted(zikr),
                  );
                },
              ),
            ),
            bottomNavigationBar: ZikrContentViewerBottomAppBar(
              state: state,
            ),
          );
        },
      ),
    );
  }
}
