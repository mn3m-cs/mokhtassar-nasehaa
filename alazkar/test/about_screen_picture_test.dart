import 'dart:io';

import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/features/about/presentation/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screen_picture.dart';

/// Draws the About screen at the normal text size and at the largest one.
/// The folder comes from `--dart-define=ABOUT_PICTURES=<dir>`.
const _folder = String.fromEnvironment('ABOUT_PICTURES');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  kAppVersion = '1.0.0 (1)';

  for (final scale in [1.0, 2.0]) {
    testWidgets('the About screen picture at text scale $scale',
        (tester) async {
      final path = '${_folder.isEmpty ? 'build/test_pictures' : _folder}'
          '/about_screen_x${scale.toInt()}.png';

      await drawScreenPicture(
        tester,
        path: path,
        screen: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFF9EF),
            ),
            fontFamily: 'Cairo',
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const AboutScreen(),
        ),
      );

      expect(File(path).existsSync(), isTrue);
    });
  }
}
