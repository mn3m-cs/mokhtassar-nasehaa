import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's font families and the files that hold them, as in `pubspec.yaml`.
const _fonts = <String, List<String>>{
  'Cairo': [
    'assets/fonts/Cairo-Regular.ttf',
    'assets/fonts/Cairo-Medium.ttf',
    'assets/fonts/Cairo-Bold.ttf',
  ],
  'Kitab': ['assets/fonts/kitab.ttf'],
  'Amiri': ['assets/fonts/Amiri-Regular.ttf'],
  'NotoNaskhArabic': ['assets/fonts/NotoNaskhArabic-Regular.ttf'],
  'IBMPlexSansArabic': ['assets/fonts/IBMPlexSansArabic-Regular.ttf'],
  'Uthmanic': ['assets/fonts/uthmanic_hafs_ver12.otf'],
  'Uthmanic2': ['assets/fonts/UthmanicHafs_v2-1.ttf'],
};

/// Loads the app's real fonts, so a picture drawn by a test shows Arabic
/// letters and not the squares `flutter test` draws by default.
///
/// Call it once before drawing, e.g. in `setUpAll`.
Future<void> loadAppFonts() async {
  for (final entry in _fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }

  // The icons are glyphs of this font, and draw as boxes without it.
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();

  checkArabicFontLoaded();
}

/// Throws unless an Arabic word measured in Cairo is not drawn as the squares
/// `flutter test` uses when no font is loaded.
///
/// Without a font every glyph is a square as wide as the font size, so the
/// word is as wide as its letters times that size. Real Arabic letters join
/// and have their own widths.
void checkArabicFontLoaded() {
  const word = 'الإعدادات';
  const fontSize = 40.0;
  final painter = TextPainter(
    text: const TextSpan(
      text: word,
      style: TextStyle(fontFamily: 'Cairo', fontSize: fontSize),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  final width = painter.width;
  painter.dispose();
  if (width == word.length * fontSize) {
    throw StateError(
      'The app fonts were not loaded: «$word» measured $width, the width of '
      '${word.length} squares. A picture drawn now would show squares, not '
      'Arabic letters.',
    );
  }
}

/// Draws [screen] at [size] logical pixels, with the app's fonts, and saves it
/// as a PNG at [path].
///
/// [screen] is the whole tree to draw, usually a `MaterialApp` whose theme sets
/// `fontFamily: 'Cairo'`, as the app's does. It is a test picture, not an
/// emulator one, and the pull request must say so.
Future<void> drawScreenPicture(
  WidgetTester tester, {
  required Widget screen,
  required String path,
  Future<void> Function(WidgetTester tester)? beforeCapture,
  Size size = const Size(412, 915),
  double pixelRatio = 2.625,
}) async {
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.physicalSize = size * pixelRatio;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: screen));
  if (beforeCapture == null) {
    await tester.pumpAndSettle();
  } else {
    // A screen that loads first shows a spinner, which never settles; the
    // hook waits for the load, and the screen settles after it.
    await tester.pump();
    await beforeCapture(tester);
    await tester.pumpAndSettle();
  }

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
