import 'dart:io';

import 'package:alazkar/src/features/theme/domain/models/zikr_font.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

void main() {
  test('the azkar text starts in Noto Naskh', () {
    expect(ThemeStorage(MemoryStorage()).getZikrFont, ZikrFont.notoNaskh);
  });

  test('a chosen font is remembered', () async {
    final storage = ThemeStorage(MemoryStorage());

    await storage.setZikrFont(ZikrFont.amiri);

    expect(storage.getZikrFont, ZikrFont.amiri);
  });

  test('an unknown stored font falls back to Noto Naskh', () async {
    final box = MemoryStorage();
    await box.write("ZikrFont", "removedFont");

    expect(ThemeStorage(box).getZikrFont, ZikrFont.notoNaskh);
  });

  test('every choosable font is bundled with the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final font in ZikrFont.values) {
      final declaration = RegExp(
        'family: ${font.family}\\n\\s+fonts:\\n\\s+- asset: (\\S+)',
      ).firstMatch(pubspec);
      expect(declaration, isNotNull, reason: font.family);
      expect(File(declaration!.group(1)!).existsSync(), isTrue,
          reason: declaration.group(1));
    }
  });
}
