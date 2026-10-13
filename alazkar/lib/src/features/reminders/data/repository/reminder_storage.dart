import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';

class ReminderStorage {
  final KVStorage _box;

  ReminderStorage(this._box);

  static String _enabledKey(ReminderSlot slot) =>
      'reminder_${slot.name}_enabled';
  static String _minuteKey(ReminderSlot slot) => 'reminder_${slot.name}_minute';

  ReminderSetting read(ReminderSlot slot) {
    return ReminderSetting(
      enabled: _box.read<bool>(_enabledKey(slot)) ?? false,
      minuteOfDay: _box.read<int>(_minuteKey(slot)) ?? slot.defaultMinuteOfDay,
    );
  }

  Map<ReminderSlot, ReminderSetting> readAll() {
    return {for (final slot in ReminderSlot.values) slot: read(slot)};
  }

  Future<void> write(ReminderSlot slot, ReminderSetting setting) async {
    await _box.write(_enabledKey(slot), setting.enabled);
    await _box.write(_minuteKey(slot), setting.minuteOfDay);
  }
}
