import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/theme/domain/models/zikr_font.dart';
import 'package:flutter/material.dart';

class ThemeStorage {
  final KVStorage box;
  ThemeStorage(this.box);

  /// *****************************
  static const String _brightnessKey = "ThemeBrightness";

  /// The reader's own choice, or the phone's setting until they make one.
  Brightness get getBrightness {
    final String? brightness = box.read(_brightnessKey);
    if (brightness == null) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
    return brightness == Brightness.dark.toString()
        ? Brightness.dark
        : Brightness.light;
  }

  Future setBrightness(Brightness brightness) async {
    await box.write(_brightnessKey, brightness.toString());
  }

  /// *****************************
  static const String _useMaterial3Key = "ThemeUseMaterial3";
  bool get getUseMaterial3 {
    final bool? useMaterial3 = box.read(_useMaterial3Key);
    return useMaterial3 ?? true;
  }

  Future setUseMaterial3(bool useMaterial3) async {
    await box.write(_useMaterial3Key, useMaterial3);
  }

  /// *****************************
  static const String _colorKey = "ThemeColor";
  Color get getColor {
    final int? colorValue = box.read(_colorKey);
    return colorValue != null ? Color(colorValue) : const Color(0xFFFFF9EF);
  }

  Future setColor(Color color) async {
    await box.write(_colorKey, color.toARGB32());
  }

  /// *****************************
  static const String _zikrFontKey = "ZikrFont";
  ZikrFont get getZikrFont {
    final String? name = box.read(_zikrFontKey);
    return ZikrFont.values.firstWhere(
      (font) => font.name == name,
      orElse: () => ZikrFont.kitab,
    );
  }

  Future setZikrFont(ZikrFont font) async {
    await box.write(_zikrFontKey, font.name);
  }
}
