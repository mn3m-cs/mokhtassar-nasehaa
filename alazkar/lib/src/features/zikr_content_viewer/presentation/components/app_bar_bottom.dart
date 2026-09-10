import 'package:alazkar/src/features/zikr_content_viewer/presentation/controller/bloc/zikr_content_viewer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZikrContentViewerAppBarBottom extends StatelessWidget {
  final ZikrContentViewerLoadedState state;
  const ZikrContentViewerAppBarBottom({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (state.activeZikr != null)
          IconButton(
            tooltip: "مشاركة الذكر",
            onPressed: () {
              context
                  .read<ZikrContentViewerBloc>()
                  .add(ZikrContentViewerShareEvent());
            },
            icon: const Icon(Icons.share),
          ),
        if (state.activeZikr?.fadl.isNotEmpty ?? false)
          IconButton(
            tooltip: "فضل الذكر",
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    icon: Icon(
                      Icons.emoji_events_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text("فضل الذكر"),
                    content: SingleChildScrollView(
                      child: Text(
                        state.activeZikr!.fadl,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("إغلاق"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.emoji_events_rounded,
            ),
          ),
        if (state.azkar.isNotEmpty && state.activeZikr!.source.isNotEmpty)
          IconButton(
            tooltip: "مصدر الذكر وحكمه",
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    icon: Icon(
                      Icons.menu_book_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text("مصدر الذكر وحكمه"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.activeZikr!.hokm.isNotEmpty) ...[
                            Text(
                              "الحكم",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.activeZikr!.hokm,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.5,
                                  ),
                            ),
                          ],
                          if (state.activeZikr!.source.isNotEmpty) ...[
                            const Divider(height: 32),
                            Text(
                              "المصدر",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.activeZikr!.source,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.5,
                                  ),
                            ),
                          ],
                          if (state.activeZikr!.sourceIndex.isNotEmpty) ...[
                            const Divider(height: 32),
                            Text(
                              "رقم الذكر في طبعة دار ابن حزم",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.activeZikr!.sourceIndex,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("إغلاق"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.comment,
            ),
          ),
        if (state.azkar.isNotEmpty)
          Text(
            "${state.azkar.length} :: ${state.activeZikrIndex + 1}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
