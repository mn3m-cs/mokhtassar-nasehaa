import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

class FakeReminderPlatform implements ReminderPlatform {
  bool allowed;
  bool grants;
  final List<List<PlannedReminder>> scheduled = [];
  int settingsOpened = 0;

  FakeReminderPlatform({this.allowed = true, this.grants = true});

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async =>
      scheduled.add(reminders);

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  Future<bool> requestNotificationPermission() async {
    allowed = grants;
    return grants;
  }
}

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
        clock: () => DateTime(2026, 10, 13, 12),
      );

  test('turning a reminder on with permission schedules it and saves it',
      () async {
    final platform = FakeReminderPlatform();
    final storage = ReminderStorage(MemoryStorage());
    final c = cubit(platform, storage: storage);
    await c.start();

    final ok = await c.setEnabled(ReminderSlot.evening, true);

    expect(ok, isTrue);
    expect(c.state.settings[ReminderSlot.evening]!.enabled, isTrue);
    expect(storage.read(ReminderSlot.evening).enabled, isTrue);
    expect(platform.scheduled.last.first.at, DateTime(2026, 10, 13, 17));
    expect(platform.scheduled.last.first.title, 'أذكار المساء');
    expect(platform.scheduled.last.map((r) => r.titleId).toSet(), {2});
  });

  test('a refused permission leaves the reminder off and schedules nothing',
      () async {
    final platform = FakeReminderPlatform(allowed: false, grants: false);
    final c = cubit(platform);
    await c.start();

    final ok = await c.setEnabled(ReminderSlot.morning, true);

    expect(ok, isFalse);
    expect(c.state.settings[ReminderSlot.morning]!.enabled, isFalse);
    expect(c.state.notificationsBlocked, isTrue);
    expect(platform.scheduled.every((list) => list.isEmpty), isTrue);
  });

  test('changing the time replaces the old times', () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.evening, true);

    await c.setMinuteOfDay(ReminderSlot.evening, 18 * 60 + 30);

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
    await c.setEnabled(ReminderSlot.morning, true);

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
      ReminderSlot.morning,
      const ReminderSetting(enabled: true, minuteOfDay: 6 * 60),
    );
    final c = cubit(FakeReminderPlatform(allowed: false), storage: storage);

    await c.start();

    expect(c.state.notificationsBlocked, isTrue);
    expect(c.state.titles, titles);
  });
}
