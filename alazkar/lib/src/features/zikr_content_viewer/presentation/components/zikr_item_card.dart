import 'package:alazkar/src/core/extension/extension_string.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_content_builder.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_source_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _ZikrAction { source, share, copy, report }

/// One zikr as a card in the section's page: the text, its virtue below it,
/// and for a counted zikr a counter button; the rest sits behind a menu.
class ZikrItemCard extends StatelessWidget {
  final Zikr zikr;

  /// False for a passage that is read, not counted; it gets no counter.
  final bool isCounted;

  /// True for the zikr the volume keys will count next; it gets a frame.
  final bool isKeyTarget;

  /// Opens the report dialog for this card's zikr, which need not be the one
  /// in view. The menu offers the report only when it is given.
  final ValueChanged<Zikr>? onReport;

  const ZikrItemCard({
    super.key,
    required this.zikr,
    this.isCounted = true,
    this.isKeyTarget = false,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final done = isCounted && zikr.count == 0;
    final mutedColor = colorScheme.onSurface.withValues(alpha: .65);
    final themeState = context.watch<ThemeCubit>().state;
    if (!isCounted && zikr.style == 'small') {
      // A line the book sets apart in small bold type, such as the closing
      // date of the introduction: a block at the end side, its lines centred
      // on each other, at the size of the virtue line whatever the reader's
      // text size. It is a line of the book, not an item, so it has no menu:
      // there is nothing to share or look up on a closing date.
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 12),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            zikr.body,
            semanticsLabel: zikr.body.honorificsAsWords,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: themeState.zikrFont.family,
              fontWeight: FontWeight.bold,
              height: 1.7,
            ),
          ),
        ),
      );
    }
    if (!isCounted) {
      // A passage to read sits on the page like the book's prose, not in a
      // card: no background, set as a paragraph. Its lines start at the
      // right and are not justified: Flutter justifies Arabic only by
      // widening the spaces, which leaves holes in short lines of long words.
      Offset? pressPosition;
      return Builder(
        builder: (passageContext) {
          void openMenu() => _showActionsMenu(
                passageContext,
                zikr,
                onReport,
                position: pressPosition,
              );
          return Semantics(
            hint: 'خيارات الفقرة',
            onLongPress: openMenu,
            child: Listener(
              onPointerDown: (event) => pressPosition = event.position,
              onPointerUp: (_) => pressPosition = null,
              onPointerCancel: (_) => pressPosition = null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onLongPress: openMenu,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ZikrContentBuilder(
                        zikr: zikr,
                        enableDiacritics: true,
                        fontSize: themeState.fontSize,
                        fontFamily: themeState.zikrFont.family,
                        textAlign: TextAlign.start,
                      ),
                      if (zikr.fadl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 8),
                          child: Text(
                            zikr.fadl,
                            semanticsLabel: zikr.fadl.honorificsAsWords,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.7,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    return AnimatedOpacity(
      opacity: done ? .5 : 1,
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Material(
          color: Color.alphaBlend(
            colorScheme.surface.withValues(alpha: .7),
            colorScheme.surfaceContainerHighest,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isKeyTarget
                ? BorderSide(
                    color: colorScheme.primary.withValues(alpha: .6),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            // A tap anywhere on a counted zikr counts it, like its button.
            onTap: isCounted && zikr.count > 0
                ? () => context
                    .read<ZikrContentViewerBloc>()
                    .add(ZikrContentViewerDecreaseEvent(zikr))
                : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _ActionsMenu(
                        zikr: zikr, color: mutedColor, onReport: onReport),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: ZikrContentBuilder(
                      zikr: zikr,
                      enableDiacritics: true,
                      fontSize: themeState.fontSize,
                      fontFamily: themeState.zikrFont.family,
                    ),
                  ),
                  if (zikr.fadl.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 8, 10, 0),
                      child: Text(
                        zikr.fadl,
                        semanticsLabel: zikr.fadl.honorificsAsWords,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  // The book prints no grading under a zikr; it stays in
                  // the source, as the book's takhrij gives it.
                  if (isCounted)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(top: 10, end: 10),
                      child: Center(child: _CounterButton(zikr: zikr)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  final Zikr zikr;
  final Color color;
  final ValueChanged<Zikr>? onReport;

  const _ActionsMenu({
    required this.zikr,
    required this.color,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ZikrAction>(
      tooltip: "خيارات الذكر",
      icon: Icon(Icons.more_horiz, color: color),
      onSelected: (action) => _runAction(context, zikr, onReport, action),
      itemBuilder: (_) => _actionItems(zikr, onReport),
    );
  }
}

Future<void> _showActionsMenu(
  BuildContext context,
  Zikr zikr,
  ValueChanged<Zikr>? onReport, {
  Offset? position,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final passage = context.findRenderObject()! as RenderBox;
  final menuPosition = position == null
      ? passage.localToGlobal(
          passage.size.center(Offset.zero),
          ancestor: overlay,
        )
      : overlay.globalToLocal(position);
  final action = await showMenu<_ZikrAction>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromCircle(center: menuPosition, radius: 1),
      Offset.zero & overlay.size,
    ),
    items: _actionItems(zikr, onReport),
  );
  if (action != null && context.mounted) {
    _runAction(context, zikr, onReport, action);
  }
}

List<PopupMenuEntry<_ZikrAction>> _actionItems(
  Zikr zikr,
  ValueChanged<Zikr>? onReport,
) =>
    [
      if (zikr.source.isNotEmpty)
        const PopupMenuItem(
          value: _ZikrAction.source,
          child: ListTile(
            leading: Icon(Icons.menu_book_rounded),
            title: Text("المصدر"),
          ),
        ),
      const PopupMenuItem(
        value: _ZikrAction.share,
        child: ListTile(
          leading: Icon(Icons.share),
          title: Text("مشاركة"),
        ),
      ),
      const PopupMenuItem(
        value: _ZikrAction.copy,
        child: ListTile(
          leading: Icon(Icons.copy),
          title: Text("نسخ"),
        ),
      ),
      if (onReport != null)
        const PopupMenuItem(
          value: _ZikrAction.report,
          child: ListTile(
            leading: Icon(Icons.flag_outlined),
            title: Text("الإبلاغ عن خطأ"),
          ),
        ),
    ];

void _runAction(
  BuildContext context,
  Zikr zikr,
  ValueChanged<Zikr>? onReport,
  _ZikrAction action,
) {
  final bloc = context.read<ZikrContentViewerBloc>();
  switch (action) {
    case _ZikrAction.source:
      showZikrSourceDialog(context, zikr);
    case _ZikrAction.share:
      bloc.add(ZikrContentViewerShareEvent(zikr));
    case _ZikrAction.copy:
      bloc.add(ZikrContentViewerCopyEvent(zikr));
    case _ZikrAction.report:
      onReport?.call(zikr);
  }
}

/// Repetitions left; each press counts one, and it turns into a check mark
/// once the zikr is done.
class _CounterButton extends StatelessWidget {
  final Zikr zikr;

  const _CounterButton({required this.zikr});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = zikr.count == 0;
    return Semantics(
      button: !done,
      label: done ? "تم العدّ" : "العدد المتبقي ${zikr.count}، اضغط للعدّ",
      excludeSemantics: true,
      child: SizedBox(
        width: 52,
        height: 52,
        child: done
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
                child: Icon(Icons.check, color: colorScheme.onPrimary),
              )
            : OutlinedButton(
                onPressed: () => context
                    .read<ZikrContentViewerBloc>()
                    .add(ZikrContentViewerDecreaseEvent(zikr)),
                style: OutlinedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  backgroundColor: colorScheme.primary.withValues(alpha: .1),
                ),
                child: Text(
                  "${zikr.count}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
      ),
    );
  }
}
