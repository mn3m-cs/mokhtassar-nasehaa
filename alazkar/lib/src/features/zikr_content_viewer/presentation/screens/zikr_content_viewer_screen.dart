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
    final bool hasShown = storage.read<bool>(key) ?? false;
    if (!hasShown) {
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
          final bool isSliding =
              getTextWidth(state.zikrTitle.name, headerStyle, context) >
                  (screenSize.width * .5);
          return Scaffold(
            appBar: AppBar(
              title: isSliding
                  ? SizedBox(
                      height: 60,
                      child: Marquee(
                        text: state.zikrTitle.name,
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
                  : Text(
                      state.zikrTitle.name,
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
                      value: state.progress(),
                    ),
                  ],
                ),
              ),
            ),
            body: PageView.builder(
              controller: _bloc.pageController,
              itemCount: state.azkar.length,
              itemBuilder: (context, index) {
                final zikr = state.azkar[index];
                return ZikrItemCard(zikr: zikr);
              },
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
