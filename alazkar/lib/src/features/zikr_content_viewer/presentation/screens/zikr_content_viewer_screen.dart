import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/extension/extension_platform.dart';
import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/core/widgets/loading.dart';
import 'package:alazkar/src/features/home/presentation/components/bookmark_title_button.dart';
import 'package:alazkar/src/features/home/presentation/controller/home/home_bloc.dart';
import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/shake_tutorial_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_item_card.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_report_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};
  final GlobalKey _viewportKey = GlobalKey();

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
    _scrollController.dispose();
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

  GlobalKey _keyFor(int zikrId) => _cardKeys.putIfAbsent(zikrId, GlobalKey.new);

  void _bringIntoView(int zikrId) {
    final cardContext = _cardKeys[zikrId]?.currentContext;
    if (cardContext == null) return;
    Scrollable.ensureVisible(
      cardContext,
      alignment: .05,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  /// Tells the bloc which zikr is in view: the first card whose middle is on
  /// the page.
  void _reportFocus() {
    final state = _bloc.state;
    if (state is! ZikrContentViewerLoadedState || state.azkar.isEmpty) return;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;
    final pageTop = viewport.localToGlobal(Offset.zero).dy;
    var focus = state.azkar.length - 1;
    for (var i = 0; i < state.azkar.length; i++) {
      final card = _cardKeys[state.azkar[i].id]
          ?.currentContext
          ?.findRenderObject() as RenderBox?;
      if (card == null || !card.attached) continue;
      if (card.localToGlobal(Offset(0, card.size.height / 2)).dy >= pageTop) {
        focus = i;
        break;
      }
    }
    _bloc.add(ZikrContentViewerFocusEvent(focus));
  }

  bool _isBelowPage(int zikrId) {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    final card =
        _cardKeys[zikrId]?.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || card == null) return false;
    final pageBottom =
        viewport.localToGlobal(Offset(0, viewport.size.height)).dy;
    return card.localToGlobal(Offset.zero).dy >= pageBottom;
  }

  /// A new section starts at its top, or at the zikr a search result named.
  /// Finishing a zikr brings the next unfinished one after it into view; a
  /// count below the page, from the volume keys, scrolls down to show it.
  void _onStateChange(
    ZikrContentViewerState previous,
    ZikrContentViewerState current,
  ) {
    if (current is! ZikrContentViewerLoadedState) return;
    final sameSection = previous is ZikrContentViewerLoadedState &&
        previous.zikrTitle.id == current.zikrTitle.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!sameSection) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        final focus = current.azkar
            .where((zikr) => zikr.order == current.focusOrder)
            .firstOrNull;
        if (focus != null) _bringIntoView(focus.id);
        return;
      }
      final counted = current.azkar.indexWhere(
        (zikr) =>
            previous.azkar.any((p) => p.id == zikr.id && p.count > zikr.count),
      );
      if (counted == -1) return;
      if (current.azkar[counted].count > 0) {
        // Only a zikr wholly below the page moves it; a tap on the card in
        // view never shifts the text being read.
        if (_isBelowPage(current.azkar[counted].id)) {
          _bringIntoView(current.azkar[counted].id);
        }
        return;
      }
      // Move on past the zikr just finished, never back to one skipped.
      final next = current.azkar.skip(counted + 1).where(current.isPending);
      if (next.isNotEmpty) _bringIntoView(next.first.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ZikrContentViewerBloc, ZikrContentViewerState>(
        bloc: _bloc,
        listener: (_, __) {},
        listenWhen: (previous, current) {
          _onStateChange(previous, current);
          return false;
        },
        builder: (context, state) {
          if (state is! ZikrContentViewerLoadedState) {
            return const Loading();
          }
          final theme = Theme.of(context);
          final mutedColor = theme.colorScheme.onSurface.withValues(alpha: .65);
          final keysCount =
              context.watch<SettingsCubit>().state.praiseWithVolumeKeys;
          final keyTarget = state.keyTarget;
          final pathParts = state.sectionPath.isEmpty
              ? const <String>[]
              : state.sectionPath.split(' › ');
          final subtitle = state.countedTotal > 0
              ? "أتممت ${state.finishedCount} من ${state.countedTotal}"
              : pathParts.isEmpty
                  ? ""
                  : pathParts.last;
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.zikrTitle.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Kitab",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: mutedColor),
                    ),
                ],
              ),
              actions: [BookmarkTitleButton(titleId: state.zikrTitle.id)],
            ),
            body: NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                _reportFocus();
                return false;
              },
              child: SingleChildScrollView(
                key: _viewportKey,
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 6, bottom: 24),
                // The section is painted once and moved as the reader
                // scrolls, instead of being repainted on every frame.
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final zikr in state.azkar)
                        ZikrItemCard(
                          key: _keyFor(zikr.id),
                          zikr: zikr,
                          isCounted: state.isCounted(zikr),
                          isKeyTarget: keysCount && keyTarget?.id == zikr.id,
                        ),
                      _SectionEnd(
                        previous: _titleAt(state.zikrTitle, -1),
                        next: _titleAt(state.zikrTitle, 1),
                        mutedColor: mutedColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The section [step] places from [current] in book order, if any.
  ZikrTitle? _titleAt(ZikrTitle current, int step) {
    final homeState = _bloc.homeBloc.state;
    if (homeState is! HomeLoadedState) return null;
    final titles = homeState.readingOrder();
    final index = titles.indexWhere((title) => title.id == current.id);
    if (index == -1) return null;
    final target = index + step;
    if (target < 0 || target >= titles.length) return null;
    return titles[target];
  }
}

/// The close of a section: a plain marker, then a clear way on to the next
/// section in book order, back to the previous one, or to the index.
class _SectionEnd extends StatelessWidget {
  final ZikrTitle? previous;
  final ZikrTitle? next;
  final Color mutedColor;

  const _SectionEnd({
    required this.previous,
    required this.next,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        children: [
          Text(
            next == null ? "تمّ الكتاب بحمد الله" : "تمّ الباب",
            style: TextStyle(color: mutedColor),
          ),
          const SizedBox(height: 12),
          if (next != null)
            Material(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context
                    .read<ZikrContentViewerBloc>()
                    .add(ZikrContentViewerNextTitleEvent()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الباب التالي",
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onPrimary
                                    .withValues(alpha: .85),
                              ),
                            ),
                            Text(
                              next!.name,
                              style: TextStyle(
                                fontFamily: "Kitab",
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Icon(
                          Icons.chevron_left,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              if (previous != null)
                TextButton(
                  onPressed: () => context
                      .read<ZikrContentViewerBloc>()
                      .add(ZikrContentViewerPreviousTitleEvent()),
                  child: const Text("الباب السابق"),
                ),
              TextButton(
                // A section opened from search sits above the results; the
                // index is under them, with search closed.
                onPressed: () {
                  context
                      .read<ZikrContentViewerBloc>()
                      .homeBloc
                      .add(const HomeToggleSearchEvent(false));
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("العودة إلى الفهرس"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
