import 'dart:io';

import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/theme/domain/models/zikr_font.dart';
import 'package:alazkar/src/features/theme/domain/repository/theme_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements KVStorage {
  final Map<String, dynamic> _data = {};

  @override
  T? read<T>(String key) => _data[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  bool hasData(String key) => _data.containsKey(key);

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Iterable<String> get keys => _data.keys;
}

void main() {
  test('the azkar text starts in Kitab', () {
    expect(ThemeStorage(_MemoryStorage()).getZikrFont, ZikrFont.kitab);
  });

  test('a chosen font is remembered', () async {
    final storage = ThemeStorage(_MemoryStorage());

    await storage.setZikrFont(ZikrFont.amiri);

    expect(storage.getZikrFont, ZikrFont.amiri);
  });

  test('an unknown stored font falls back to Kitab', () async {
    final box = _MemoryStorage();
    await box.write("ZikrFont", "removedFont");

    expect(ThemeStorage(box).getZikrFont, ZikrFont.kitab);
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
