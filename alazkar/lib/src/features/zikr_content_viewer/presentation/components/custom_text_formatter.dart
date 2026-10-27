// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/extension/extension_string.dart';
import 'package:flutter/material.dart';

class StringFormatter extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool enableDiacritics;
  final Color? color;
  final String fontFamily;
  final TextAlign textAlign;
  const StringFormatter({
    super.key,
    required this.text,
    required this.fontSize,
    required this.enableDiacritics,
    this.color,
    this.fontFamily = 'NotoNaskhArabic',
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: fontSize,
      height: 2,
      fontFamilyFallback: kGlyphFallback,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
    return RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      text: customTextSpan(
        text: enableDiacritics ? text : text.removeDiacritics,
        defaultStyle: defaultStyle.copyWith(fontFamily: fontFamily),
        highlightStyle: defaultStyle.copyWith(fontFamily: 'Uthmanic2'),
      ),
    );
  }

  TextSpan customTextSpan({
    required String text,
    required TextStyle defaultStyle,
    required TextStyle highlightStyle,
  }) {
    final pattern = RegExp('﴿(.*?)﴾');
    final matches = pattern.allMatches(text);
    final List<TextSpan> children = [];

    int lastMatchEnd = 0;

    for (final match in matches) {
      final preMatch = text.substring(lastMatchEnd, match.start);
      final highlightedText = text.substring(match.start, match.end);

      if (preMatch.isNotEmpty) {
        children.add(_plainSpan(preMatch, defaultStyle));
      }

      children.add(TextSpan(text: highlightedText, style: highlightStyle));

      lastMatchEnd = match.end;
    }

    final postMatch = text.substring(lastMatchEnd);
    if (postMatch.isNotEmpty) {
      children.add(_plainSpan(postMatch, defaultStyle));
    }

    return TextSpan(children: children);
  }

  /// The screen reader reads an honorific glyph as its words.
  TextSpan _plainSpan(String text, TextStyle style) {
    final words = text.honorificsAsWords;
    return TextSpan(
      text: text,
      style: style,
      semanticsLabel: words == text ? null : words,
    );
  }
}
