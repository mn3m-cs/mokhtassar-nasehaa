import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/core/models/zikr_extension.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/components/custom_text_formatter.dart';
import 'package:flutter/material.dart';

class ZikrContentBuilder extends StatelessWidget {
  final Zikr zikr;
  final double fontSize;
  final bool enableDiacritics;
  final Color? color;

  /// The reader's chosen typeface for the azkar text.
  final String fontFamily;
  const ZikrContentBuilder({
    super.key,
    required this.zikr,
    required this.fontSize,
    required this.enableDiacritics,
    this.color,
    this.fontFamily = "NotoNaskhArabic",
  });

  @override
  Widget build(BuildContext context) {
    final containsQuranText = zikr.body.contains("QuranText");
    return containsQuranText
        ? ZikrContentTextWithQuran(
            zikr: zikr,
            enableDiacritics: enableDiacritics,
            fontSize: fontSize,
            color: color,
            fontFamily: fontFamily,
          )
        : ZikrContentPlainText(
            zikr: zikr,
            enableDiacritics: enableDiacritics,
            fontSize: fontSize,
            color: color,
            fontFamily: fontFamily,
          );
  }
}

class ZikrContentPlainText extends StatelessWidget {
  final Zikr zikr;
  final double fontSize;
  final bool enableDiacritics;
  final Color? color;
  final String fontFamily;
  const ZikrContentPlainText({
    super.key,
    required this.zikr,
    required this.fontSize,
    required this.enableDiacritics,
    this.color,
    this.fontFamily = "NotoNaskhArabic",
  });

  @override
  Widget build(BuildContext context) {
    return StringFormatter(
      //TDOD remove after database update
      text: zikr.body.replaceAll("، ،", "،").replaceAll("  ", " "),
      fontSize: fontSize,
      color: color,
      enableDiacritics: enableDiacritics,
      fontFamily: fontFamily,
    );
  }
}

/// Text with Quranic verses, whose spans are loaded asynchronously. They are
/// loaded once per zikr and kept, so a rebuild of the page never swaps the
/// verses for a loading bar and reflows everything around them.
class ZikrContentTextWithQuran extends StatefulWidget {
  final Zikr zikr;
  final double fontSize;
  final bool enableDiacritics;
  final Color? color;
  final String fontFamily;
  const ZikrContentTextWithQuran({
    super.key,
    required this.zikr,
    required this.fontSize,
    required this.enableDiacritics,
    this.color,
    this.fontFamily = "NotoNaskhArabic",
  });

  @override
  State<ZikrContentTextWithQuran> createState() =>
      _ZikrContentTextWithQuranState();
}

class _ZikrContentTextWithQuranState extends State<ZikrContentTextWithQuran> {
  late Future<List<InlineSpan>> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _load();
  }

  @override
  void didUpdateWidget(ZikrContentTextWithQuran oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zikr.body != widget.zikr.body ||
        oldWidget.enableDiacritics != widget.enableDiacritics) {
      _spans = _load();
    }
  }

  Future<List<InlineSpan>> _load() =>
      widget.zikr.getTextSpan(enableDiacritics: widget.enableDiacritics);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _spans,
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();

        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: snap.data ?? [],
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 2,
              fontFamily: widget.fontFamily,
              color:
                  widget.color ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        );
      },
    );
  }
}
