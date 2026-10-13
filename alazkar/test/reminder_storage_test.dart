import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

void main() {
  test('every reminder starts off at its default time', () {
    final settings = ReminderStorage(MemoryStorage()).readAll();

    expect(settings, {
      ReminderSlot.morning:
          const ReminderSetting(enabled: false, minuteOfDay: 6 * 60),
      ReminderSlot.evening:
          const ReminderSetting(enabled: false, minuteOfDay: 17 * 60),
      ReminderSlot.sleep:
          const ReminderSetting(enabled: false, minuteOfDay: 22 * 60),
    });
  });

  test('a saved reminder is read back, and the others are untouched', () async {
    final storage = ReminderStorage(MemoryStorage());

    await storage.write(
      ReminderSlot.evening,
      const ReminderSetting(enabled: true, minuteOfDay: 18 * 60 + 30),
    );

    expect(
      storage.read(ReminderSlot.evening),
      const ReminderSetting(enabled: true, minuteOfDay: 18 * 60 + 30),
    );
    expect(storage.read(ReminderSlot.morning).enabled, isFalse);
  });
}
