import 'package:alazkar/src/core/storage/kv_storage.dart';

class SettingsStorage {
  final KVStorage _box;
  SettingsStorage(this._box);

  static const String _settingsPrefixNameKey = "SettingsStorage";

  ///MARK: showTextInBrackets
  static const String _showTextInBrackets =
      "${_settingsPrefixNameKey}showTextInBrackets";

  bool showTextInBrackets() {
    final bool? data = _box.read(_showTextInBrackets);

    return data ?? true;
  }

  Future setShowTextInBrackets(bool showTextInBrackets) {
    return _box.write(_showTextInBrackets, showTextInBrackets);
  }

  ///MARK: praiseWithVolumeKeys
  static const praiseWithVolumeKeysKey = 'praiseWithVolumeKeys';
  bool get praiseWithVolumeKeys => _box.read(praiseWithVolumeKeysKey) ?? true;
  Future<void> changePraiseWithVolumeKeysStatus({required bool value}) =>
      _box.write(praiseWithVolumeKeysKey, value);
}
