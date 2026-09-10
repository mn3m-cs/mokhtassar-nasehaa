import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';

class ZikrTextRepo {
  final KVStorage box;
  ZikrTextRepo(this.box);

  ///MARK: Font
  /* ******* Font Size ******* */
  static const String fontSizeKey = 'ThemeFontSize';
  double get fontSize => box.read<double>(fontSizeKey) ?? kFontDefault;

  Future<void> changFontSize(double value) async {
    final double tempValue = value.clamp(kFontMin, kFontMax);
    await box.write(fontSizeKey, tempValue);
  }

  void resetFontSize() {
    changFontSize(kFontDefault);
  }

  void increaseFontSize() {
    changFontSize(fontSize + kFontChangeBy);
  }

  void decreaseFontSize() {
    changFontSize(fontSize - kFontChangeBy);
  }

  /* ******* Diacritics ******* */

  bool get showDiacritics => box.read('showDiacritics') ?? true;

  Future<void> changDiacriticsStatus({required bool value}) =>
      box.write('tashkel_status', value);
}
