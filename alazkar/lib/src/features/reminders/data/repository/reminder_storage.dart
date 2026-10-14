import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';

class ReminderStorage {
  final KVStorage _box;

  ReminderStorage(this._box);

  static String _enabledKey(ReminderSlot slot) =>
      'reminder_${slot.name}_enabled';
  static String _minuteKey(ReminderSlot slot) => 'reminder_${slot.name}_minute';
  static String _kindKey(ReminderSlot slot) => 'reminder_${slot.name}_kind';
  static String _offsetKey(ReminderSlot slot) => 'reminder_${slot.name}_offset';

  static const String _placeName = 'reminder_place_name';
  static const String _placeCountryName = 'reminder_place_country_name';
  static const String _placeCountryCode = 'reminder_place_country_code';
  static const String _placeLatitude = 'reminder_place_latitude';
  static const String _placeLongitude = 'reminder_place_longitude';
  static const String _method = 'reminder_method';
  static const String _madhab = 'reminder_madhab';

  ReminderSetting read(ReminderSlot slot) {
    final kind =
        ReminderKind.values.asNameMap()[_box.read<String>(_kindKey(slot))];
    return ReminderSetting(
      enabled: _box.read<bool>(_enabledKey(slot)) ?? false,
      kind: slot.kinds.contains(kind) ? kind! : slot.defaultKind,
      minuteOfDay: _box.read<int>(_minuteKey(slot)) ?? kDefaultSleepMinute,
      offsetMinutes: _box.read<int>(_offsetKey(slot)) ?? kDefaultOffsetMinutes,
    );
  }

  Map<ReminderSlot, ReminderSetting> readAll() {
    return {for (final slot in ReminderSlot.values) slot: read(slot)};
  }

  Future<void> write(ReminderSlot slot, ReminderSetting setting) async {
    await _box.write(_enabledKey(slot), setting.enabled);
    await _box.write(_kindKey(slot), setting.kind.name);
    await _box.write(_minuteKey(slot), setting.minuteOfDay);
    await _box.write(_offsetKey(slot), setting.offsetMinutes);
  }

  Place? readPlace() {
    final name = _box.read<String>(_placeName);
    if (name == null) return null;
    return Place(
      name: name,
      countryName: _box.read<String>(_placeCountryName) ?? '',
      countryCode: _box.read<String>(_placeCountryCode) ?? '',
      latitude: _box.read<double>(_placeLatitude) ?? 0,
      longitude: _box.read<double>(_placeLongitude) ?? 0,
    );
  }

  Future<void> writePlace(Place place) async {
    await _box.write(_placeCountryName, place.countryName);
    await _box.write(_placeCountryCode, place.countryCode);
    await _box.write(_placeLatitude, place.latitude);
    await _box.write(_placeLongitude, place.longitude);
    await _box.write(_placeName, place.name);
  }

  /// The method the reader picked by hand; null follows the country.
  PrayerMethod? readMethod() =>
      PrayerMethod.values.asNameMap()[_box.read<String>(_method)];

  Future<void> writeMethod(PrayerMethod method) =>
      _box.write(_method, method.name);

  AsrMadhab readMadhab() =>
      AsrMadhab.values.asNameMap()[_box.read<String>(_madhab)] ??
      AsrMadhab.majority;

  Future<void> writeMadhab(AsrMadhab madhab) =>
      _box.write(_madhab, madhab.name);
}
