import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_content_builder.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/zikr_source_dialog.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _ZikrAction { source, share, copy }

/// One zikr as a card in the section's page: the text, its virtue below it,
/// and for a counted zikr a counter button; the rest sits behind a menu.
class ZikrItemCard extends StatelessWidget {
  final Zikr zikr;

  /// False for a passage that is read, not counted; it gets no counter.
  final bool isCounted;

  const ZikrItemCard({
    super.key,
    required this.zikr,
    this.isCounted = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final done = isCounted && zikr.count == 0;
    final mutedColor = colorScheme.onSurface.withValues(alpha: .65);
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
          borderRadius: BorderRadius.circular(18),
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
                    child: _ActionsMenu(zikr: zikr, color: mutedColor),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: ZikrContentBuilder(
                      zikr: zikr,
                      enableDiacritics: true,
                      fontSize: context.watch<ThemeCubit>().state.fontSize,
                    ),
                  ),
                  if (zikr.fadl.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 8, 10, 0),
                      child: Text(
                        zikr.fadl,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  if (isCounted || zikr.hokm.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(top: 10, end: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              zikr.hokm,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: mutedColor),
                            ),
                          ),
                          if (isCounted) _CounterButton(zikr: zikr),
                        ],
                      ),
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

  const _ActionsMenu({required this.zikr, required this.color});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ZikrContentViewerBloc>();
    return PopupMenuButton<_ZikrAction>(
      tooltip: "خيارات الذكر",
      icon: Icon(Icons.more_horiz, color: color),
      onSelected: (action) {
        switch (action) {
          case _ZikrAction.source:
            showZikrSourceDialog(context, zikr);
          case _ZikrAction.share:
            bloc.add(ZikrContentViewerShareEvent(zikr));
          case _ZikrAction.copy:
            bloc.add(ZikrContentViewerCopyEvent(zikr));
        }
      },
      itemBuilder: (context) => [
        if (zikr.source.isNotEmpty || zikr.hokm.isNotEmpty)
          const PopupMenuItem(
            value: _ZikrAction.source,
            child: ListTile(
              leading: Icon(Icons.menu_book_rounded),
              title: Text("المصدر والحكم"),
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
      ],
    );
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
