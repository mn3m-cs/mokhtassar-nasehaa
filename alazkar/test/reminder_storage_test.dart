import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

void main() {
  const cairo = Place(
    name: 'القاهرة',
    countryName: 'مصر',
    countryCode: 'EG',
    latitude: 30.05,
    longitude: 31.24,
  );

  test(
      'every reminder starts off, morning after Fajr, evening after Asr, '
      'sleep at 22:00, by 30 minutes', () {
    final settings = ReminderStorage(MemoryStorage()).readAll();

    expect(settings, {
      ReminderSlot.morning: const ReminderSetting(
        enabled: false,
        kind: ReminderKind.afterFajr,
      ),
      ReminderSlot.evening: const ReminderSetting(
        enabled: false,
        kind: ReminderKind.afterAsr,
      ),
      ReminderSlot.sleep: const ReminderSetting(enabled: false),
    });
    expect(settings[ReminderSlot.morning]!.offsetMinutes, 30);
    expect(settings[ReminderSlot.sleep]!.minuteOfDay, 22 * 60);
  });

  test('a saved reminder is read back, and the others are untouched', () async {
    final storage = ReminderStorage(MemoryStorage());
    const evening = ReminderSetting(
      enabled: true,
      kind: ReminderKind.beforeMaghrib,
      offsetMinutes: 15,
    );

    await storage.write(ReminderSlot.evening, evening);

    expect(storage.read(ReminderSlot.evening), evening);
    expect(storage.read(ReminderSlot.morning).enabled, isFalse);
  });

  test('a phase 1 clock time saved for the morning reads as after Fajr',
      () async {
    final box = MemoryStorage();
    await box.write('reminder_morning_enabled', true);
    await box.write('reminder_morning_minute', 6 * 60);

    final morning = ReminderStorage(box).read(ReminderSlot.morning);

    expect(morning.enabled, isTrue);
    expect(morning.kind, ReminderKind.afterFajr);
  });

  test('a kind the slot does not offer falls back to its default', () async {
    final storage = ReminderStorage(MemoryStorage());

    await storage.write(
      ReminderSlot.sleep,
      const ReminderSetting(enabled: true, kind: ReminderKind.afterAsr),
    );

    expect(storage.read(ReminderSlot.sleep).kind, ReminderKind.fixed);
  });

  test('the place, method and madhab are kept', () async {
    final storage = ReminderStorage(MemoryStorage());
    expect(storage.readPlace(), isNull);
    expect(storage.readMethod(), isNull);
    expect(storage.readMadhab(), AsrMadhab.majority);

    await storage.writePlace(cairo);
    await storage.writeMethod(PrayerMethod.muslimWorldLeague);
    await storage.writeMadhab(AsrMadhab.hanafi);

    expect(storage.readPlace(), cairo);
    expect(storage.readMethod(), PrayerMethod.muslimWorldLeague);
    expect(storage.readMadhab(), AsrMadhab.hanafi);
  });
}
