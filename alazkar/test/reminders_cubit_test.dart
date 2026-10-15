import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_reminder_platform.dart';
import 'support/memory_storage.dart';
import 'support/test_cities.dart';

void main() {
  const titles = {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'};

  RemindersCubit cubit(
    FakeReminderPlatform platform, {
    ReminderStorage? storage,
  }) =>
      RemindersCubit(
        storage ?? ReminderStorage(MemoryStorage()),
        platform,
        () async => titles,
        CityRepository(read: () async => kTestCitiesJson),
        clock: () => DateTime(2026, 10, 13, 12),
        utcOffsetOf: (_) => const Duration(hours: 3),
      );

  const makkah = Place(
    name: 'مكة المكرمة',
    countryName: 'السعودية',
    countryCode: 'SA',
    latitude: 21.4267,
    longitude: 39.8261,
  );
  const riyadh = Place(
    name: 'الرياض',
    countryName: 'السعودية',
    countryCode: 'SA',
    latitude: 24.6877,
    longitude: 46.7219,
  );
  const cairo = Place(
    name: 'القاهرة',
    countryName: 'مصر',
    countryCode: 'EG',
    latitude: 30.0626,
    longitude: 31.2497,
  );

  int minuteOf(PlannedReminder reminder) =>
      reminder.at.hour * 60 + reminder.at.minute;

  List<PlannedReminder> forTitle(FakeReminderPlatform platform, int titleId) =>
      platform.scheduled.last.where((r) => r.titleId == titleId).toList();

  test('turning a reminder on with permission schedules it and saves it',
      () async {
    final platform = FakeReminderPlatform();
    final storage = ReminderStorage(MemoryStorage());
    final c = cubit(platform, storage: storage);
    await c.start();

    final ok = await c.setEnabled(ReminderSlot.sleep, true);

    expect(ok, ReminderToggle.done);
    expect(c.state.settings[ReminderSlot.sleep]!.enabled, isTrue);
    expect(storage.read(ReminderSlot.sleep).enabled, isTrue);
    expect(platform.scheduled.last.first.at, DateTime(2026, 10, 13, 22));
    expect(platform.scheduled.last.first.title, 'أذكار النوم');
    expect(platform.scheduled.last.map((r) => r.titleId).toSet(), {18});
  });

  test('a refused permission leaves the reminder off and schedules nothing',
      () async {
    final platform = FakeReminderPlatform(allowed: false, grants: false);
    final c = cubit(platform);
    await c.start();

    final ok = await c.setEnabled(ReminderSlot.morning, true);

    expect(ok, ReminderToggle.notificationsRefused);
    expect(c.state.settings[ReminderSlot.morning]!.enabled, isFalse);
    expect(c.state.notificationsBlocked, isTrue);
    expect(platform.scheduled.every((list) => list.isEmpty), isTrue);
  });

  test('changing the time replaces the old times', () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.sleep, true);

    await c.setMinuteOfDay(ReminderSlot.sleep, 18 * 60 + 30);

    expect(
      platform.scheduled.last
          .every((r) => r.at.hour == 18 && r.at.minute == 30),
      isTrue,
    );
  });

  test('turning the last reminder off schedules an empty list', () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.sleep, true);

    await c.setEnabled(ReminderSlot.sleep, false);

    expect(platform.scheduled.last, isEmpty);
  });

  test('the blocked line follows the phone settings without a restart',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.sleep, true);

    platform.allowed = false;
    await c.refreshPermission();
    expect(c.state.notificationsBlocked, isTrue);

    platform.allowed = true;
    await c.refreshPermission();
    expect(c.state.notificationsBlocked, isFalse);
  });

  test('a reader who never asked for reminders is not told they are blocked',
      () async {
    final c = cubit(FakeReminderPlatform(allowed: false, grants: false));
    await c.start();

    await c.refreshPermission();

    expect(c.state.notificationsBlocked, isFalse);
  });

  test('a refusal stays reported after returning from the permission dialog',
      () async {
    final platform = FakeReminderPlatform(allowed: false, grants: false);
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.morning, true);

    await c.refreshPermission();

    expect(c.state.notificationsBlocked, isTrue);

    platform.allowed = true;
    await c.refreshPermission();
    expect(c.state.notificationsBlocked, isFalse);
  });

  test('a permission revoked in the phone settings shows as blocked on start',
      () async {
    final storage = ReminderStorage(MemoryStorage());
    await storage.write(
      ReminderSlot.sleep,
      const ReminderSetting(enabled: true),
    );
    final c = cubit(FakeReminderPlatform(allowed: false), storage: storage);

    await c.start();

    expect(c.state.notificationsBlocked, isTrue);
    expect(c.state.titles, titles);
  });

  test(
      'AC-009: turning the morning on reads the device location once and '
      'names the nearest city', () async {
    final platform = FakeReminderPlatform(
      location: (latitude: 30.01, longitude: 31.21),
    );
    final storage = ReminderStorage(MemoryStorage());
    final c = cubit(platform, storage: storage);
    await c.start();

    final result = await c.setEnabled(ReminderSlot.morning, true);

    expect(result, ReminderToggle.done);
    expect(c.state.place!.name, 'القاهرة');
    expect(c.state.place!.latitude, 30.01);
    expect(storage.readPlace(), c.state.place);
    expect(c.state.method, PrayerMethod.egyptian);
    final morning = forTitle(platform, 1);
    expect(morning, hasLength(90));
    final fajr = PrayerTimesCalculator(
      latitude: 30.01,
      longitude: 31.21,
      method: PrayerMethod.egyptian,
      madhab: AsrMadhab.majority,
      utcOffsetOf: (_) => const Duration(hours: 3),
    ).dayOf(morning.first.at).fajr;
    expect(minuteOf(morning.first), fajr + 30);

    await c.setEnabled(ReminderSlot.evening, true);
    expect(platform.locationRequests, 1);
  });

  test('AC-009: a refused location leaves the morning off and asks for a city',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();

    final result = await c.setEnabled(ReminderSlot.morning, true);

    expect(result, ReminderToggle.locationNeeded);
    expect(c.state.settings[ReminderSlot.morning]!.enabled, isFalse);
    expect(c.state.locationNeeded, isTrue);
    expect(platform.scheduled.last.where((r) => r.titleId == 1), isEmpty);
    expect(c.state.locating, isFalse);
  });

  test('a chosen city then lets the morning turn on', () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.morning, true);

    await c.setPlace(makkah);
    final result = await c.setEnabled(ReminderSlot.morning, true);

    expect(result, ReminderToggle.done);
    expect(c.state.locationNeeded, isFalse);
    expect(forTitle(platform, 1), hasLength(90));
    expect(platform.locationRequests, 1);
  });

  test('AC-010: the method follows the country unless the reader picked one',
      () async {
    final c = cubit(FakeReminderPlatform());
    await c.start();

    await c.setPlace(cairo);
    expect(c.state.method, PrayerMethod.egyptian);
    await c.setPlace(riyadh);
    expect(c.state.method, PrayerMethod.ummAlQura);

    await c.setMethod(PrayerMethod.muslimWorldLeague);
    await c.setPlace(cairo);
    expect(c.state.method, PrayerMethod.muslimWorldLeague);
  });

  test('changing the madhab or the place plans the reminders again at once',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setPlace(cairo);
    await c.setEnabled(ReminderSlot.evening, true);
    final majority = minuteOf(forTitle(platform, 2).first);

    await c.setMadhab(AsrMadhab.hanafi);
    final hanafi = minuteOf(forTitle(platform, 2).first);
    expect(hanafi, greaterThan(majority + 20));

    await c.setPlace(makkah);
    expect(minuteOf(forTitle(platform, 2).first), isNot(hanafi));
    expect(forTitle(platform, 2), hasLength(90));
  });

  test('the evening can move to before Maghrib, by any 5-minute step',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setPlace(cairo);
    await c.setEnabled(ReminderSlot.evening, true);

    await c.setKind(ReminderSlot.evening, ReminderKind.beforeMaghrib);
    await c.setOffset(ReminderSlot.evening, 10);

    final evening = forTitle(platform, 2);
    expect(minuteOf(evening.first), c.state.today!.maghrib - 10);
    expect(
      c.state.settings[ReminderSlot.evening],
      const ReminderSetting(
        enabled: true,
        kind: ReminderKind.beforeMaghrib,
        offsetMinutes: 10,
      ),
    );
  });

  test("today's prayer times are shown once there is a place", () async {
    final c = cubit(FakeReminderPlatform());
    await c.start();
    expect(c.state.today, isNull);

    await c.setPlace(cairo);

    expect(
      c.state.today,
      PrayerTimesCalculator(
        latitude: cairo.latitude,
        longitude: cairo.longitude,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.majority,
        utcOffsetOf: (_) => const Duration(hours: 3),
      ).dayOf(DateTime(2026, 10, 13)),
    );
  });

  test('a morning reminder saved by phase 1, with no place, asks for one',
      () async {
    final box = MemoryStorage();
    await box.write('reminder_morning_enabled', true);
    await box.write('reminder_morning_minute', 6 * 60);
    final platform = FakeReminderPlatform();
    final c = cubit(platform, storage: ReminderStorage(box));

    await c.start();

    expect(c.state.locationNeeded, isTrue);
    expect(platform.scheduled.last, isEmpty);
  });

  test('a reminder turned on before the titles load still carries its title',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);

    await c.setEnabled(ReminderSlot.sleep, true);

    expect(platform.scheduled.last.first.title, 'أذكار النوم');
  });
}
