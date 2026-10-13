# Daily Reminders, Phase 1 (fixed times): Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The reader can turn on daily reminders for «أذكار الصباح», «أذكار المساء» and «أذكار النوم» at a time they pick. A notification arrives daily, and tapping it opens that section.

**Architecture:** Dart plans the next 90 days of reminders as a list of local date-times and hands it to Android over a method channel. Kotlin stores the list and keeps exactly one inexact system alarm set, for the earliest entry. A receiver posts the notification and sets the next alarm; a boot and clock receiver re-sets it. No Dart runs in the background, and no new library is added.

**Tech Stack:** Flutter 3.47.2 via `fvm`, `flutter_bloc` cubits, `get_it` DI, Hive `KVStorage`, Kotlin in `MainActivity`, framework `AlarmManager` and `Notification.Builder`.

**Spec:** [design.md](design.md), [intent.md](intent.md) (AC-001 to AC-007; AC-008 to AC-010 belong to phase 2).

## Global Constraints

- Flutter commands only through `fvm` (`fvm flutter …`, `fvm dart format <files>`); the bare `dart` on PATH is a different SDK.
- Never run two Flutter commands in this checkout at once.
- No new pub or Gradle dependency.
- Do not declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`.
- Alarm window: 15 minutes (`AlarmManager.setWindow`).
- Plan length: 90 days. Renewal line on entries in the last 7 days of the list.
- Sections: morning = title 1, evening = title 2, sleep = title 18.
- Default times: morning 06:00, evening 17:00, sleep 22:00. All reminders off by default.
- Notification title: the section's title read from the database (`titles.name`), never typed by hand. The only other text allowed is the renewal line «افتح التطبيق لتجديد التذكير».
- UI strings added by this phase (app text, not book text): «التذكير», «الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف», «افتح التطبيق لتجديد التذكير».
- Android only: the Settings entry and the launch handling are skipped on every other platform.
- Commits carry no AI attribution.

## Review Focus

1. **Time-zone change after planning:** the reminder must still fire at the same local time. Entries are stored as local date + minute; Task 4 checks it on the emulator with `cmd alarm set-timezone`.
2. **Phone off across a reminder time:** no late burst of old notifications after boot. Entries over an hour overdue are dropped; Task 4 checks a reboot past an entry.
3. **Two reminders at the same minute:** both notifications show. The notification id is the title id; Task 4 checks two reminders set to the same time.
4. **Permission revoked in the phone's settings while reminders are on:** the screen says notifications are blocked. The cubit test in Task 3 covers it.
5. **Notification tapped while a section is already open:** the reminded section opens on top, and back returns to where the reader was. Task 5 checks it by hand.

---

## File Structure

```
alazkar/lib/src/features/reminders/
  data/models/reminder.dart              ReminderSlot, ReminderSetting, PlannedReminder
  data/repository/reminder_storage.dart  settings on KVStorage
  data/reminder_platform.dart            ReminderPlatform interface + ReminderChannel
  domain/reminder_planner.dart           planReminders(), pure
  presentation/controller/reminders_cubit.dart
  presentation/controller/reminders_state.dart
  presentation/screens/reminders_screen.dart
  presentation/components/reminder_launch_listener.dart
alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/reminders/
  ReminderStore.kt     the stored list
  ReminderScheduler.kt one alarm for the earliest entry
  ReminderReceiver.kt  posts due notifications, sets the next alarm
  BootReceiver.kt      re-sets the alarm after boot and clock changes
  ReminderNotifier.kt  the notification
alazkar/test/reminder_planner_test.dart
alazkar/test/reminder_storage_test.dart
alazkar/test/reminders_cubit_test.dart
```

Modified: `MainActivity.kt`, `AndroidManifest.xml`, `res/values/strings.xml`, `dependency_injection.dart`, `app.dart`, `settings_screen.dart`, `integration_test/app_journeys_test.dart`, `privacy.md`.

---

### Task 1: Models and the planner

**Files:**
- Create: `alazkar/lib/src/features/reminders/data/models/reminder.dart`
- Create: `alazkar/lib/src/features/reminders/domain/reminder_planner.dart`
- Test: `alazkar/test/reminder_planner_test.dart`

**Interfaces:**
- Produces:
  - `enum ReminderSlot { morning, evening, sleep }` with `int titleId` and `int defaultMinuteOfDay`.
  - `class ReminderSetting { bool enabled; int minuteOfDay; copyWith(...) }`.
  - `class PlannedReminder { DateTime at; int titleId; String title; String body; Map<String, Object> toMap() }`. `toMap()` keys are `year, month, day, minuteOfDay, titleId, title, body`.
  - `List<PlannedReminder> planReminders({required Map<ReminderSlot, ReminderSetting> settings, required Map<int, String> titles, required DateTime now, int days = kReminderDays})`.
  - Constants `kReminderDays = 90`, `kRenewHintDays = 7`, `kRenewHint = 'افتح التطبيق لتجديد التذكير'`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const titles = {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'};
  const off = ReminderSetting(enabled: false, minuteOfDay: 0);

  Map<ReminderSlot, ReminderSetting> only(
    ReminderSlot slot,
    int minuteOfDay,
  ) =>
      {
        for (final s in ReminderSlot.values)
          s: s == slot
              ? ReminderSetting(enabled: true, minuteOfDay: minuteOfDay)
              : off,
      };

  test('nothing is planned while every reminder is off', () {
    final planned = planReminders(
      settings: {for (final s in ReminderSlot.values) s: off},
      titles: titles,
      now: DateTime(2026, 10, 13, 12),
    );

    expect(planned, isEmpty);
  });

  test('a morning reminder fires daily at its time with the book title', () {
    final planned = planReminders(
      settings: only(ReminderSlot.morning, 6 * 60),
      titles: titles,
      now: DateTime(2026, 10, 13, 5),
    );

    expect(planned, hasLength(kReminderDays));
    expect(planned.first.at, DateTime(2026, 10, 13, 6));
    expect(planned[1].at, DateTime(2026, 10, 14, 6));
    expect(planned.map((r) => r.title).toSet(), {'أذكار الصباح'});
    expect(planned.map((r) => r.titleId).toSet(), {1});
    expect(planned.every((r) => r.at.hour == 6 && r.at.minute == 0), isTrue);
  });

  test('a time already past today starts tomorrow', () {
    final planned = planReminders(
      settings: only(ReminderSlot.morning, 6 * 60),
      titles: titles,
      now: DateTime(2026, 10, 13, 6, 0, 1),
    );

    expect(planned.first.at, DateTime(2026, 10, 14, 6));
    expect(planned, hasLength(kReminderDays));
  });

  test('reminders from several slots come out in time order', () {
    final planned = planReminders(
      settings: {
        ReminderSlot.morning:
            const ReminderSetting(enabled: true, minuteOfDay: 6 * 60),
        ReminderSlot.evening:
            const ReminderSetting(enabled: true, minuteOfDay: 17 * 60),
        ReminderSlot.sleep:
            const ReminderSetting(enabled: true, minuteOfDay: 22 * 60),
      },
      titles: titles,
      now: DateTime(2026, 10, 13, 12),
    );

    expect(planned.take(4).map((r) => r.titleId), [2, 18, 1, 2]);
    for (var i = 1; i < planned.length; i++) {
      expect(planned[i].at.isBefore(planned[i - 1].at), isFalse);
    }
  });

  test('only the last week of the list carries the renewal line', () {
    final planned = planReminders(
      settings: only(ReminderSlot.sleep, 22 * 60),
      titles: titles,
      now: DateTime(2026, 10, 13, 12),
    );

    final withLine = planned.where((r) => r.body == kRenewHint).toList();
    expect(withLine, hasLength(kRenewHintDays));
    expect(withLine.first.at, planned[kReminderDays - kRenewHintDays].at);
    expect(
      planned
          .take(kReminderDays - kRenewHintDays)
          .every((r) => r.body.isEmpty),
      isTrue,
    );
  });

  test('the map sent to Android holds the local date and minute', () {
    final planned = planReminders(
      settings: only(ReminderSlot.evening, 17 * 60 + 30),
      titles: titles,
      now: DateTime(2026, 10, 13, 12),
    );

    expect(planned.first.toMap(), {
      'year': 2026,
      'month': 10,
      'day': 13,
      'minuteOfDay': 17 * 60 + 30,
      'titleId': 2,
      'title': 'أذكار المساء',
      'body': '',
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd alazkar && fvm flutter test test/reminder_planner_test.dart`
Expected: FAIL, the reminders library does not exist yet.

- [ ] **Step 3: Write the models**

`alazkar/lib/src/features/reminders/data/models/reminder.dart`:

```dart
import 'package:equatable/equatable.dart';

enum ReminderSlot {
  morning(titleId: 1, defaultMinuteOfDay: 6 * 60),
  evening(titleId: 2, defaultMinuteOfDay: 17 * 60),
  sleep(titleId: 18, defaultMinuteOfDay: 22 * 60);

  const ReminderSlot({
    required this.titleId,
    required this.defaultMinuteOfDay,
  });

  final int titleId;
  final int defaultMinuteOfDay;
}

class ReminderSetting extends Equatable {
  final bool enabled;
  final int minuteOfDay;

  const ReminderSetting({required this.enabled, required this.minuteOfDay});

  ReminderSetting copyWith({bool? enabled, int? minuteOfDay}) {
    return ReminderSetting(
      enabled: enabled ?? this.enabled,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    );
  }

  @override
  List<Object> get props => [enabled, minuteOfDay];
}

class PlannedReminder extends Equatable {
  final DateTime at;
  final int titleId;
  final String title;
  final String body;

  const PlannedReminder({
    required this.at,
    required this.titleId,
    required this.title,
    required this.body,
  });

  /// Local date and minute rather than an absolute moment, so a
  /// time-zone change keeps the reminder at the same local time.
  Map<String, Object> toMap() => {
        'year': at.year,
        'month': at.month,
        'day': at.day,
        'minuteOfDay': at.hour * 60 + at.minute,
        'titleId': titleId,
        'title': title,
        'body': body,
      };

  @override
  List<Object> get props => [at, titleId, title, body];
}
```

- [ ] **Step 4: Write the planner**

`alazkar/lib/src/features/reminders/domain/reminder_planner.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';

const int kReminderDays = 90;
const int kRenewHintDays = 7;
const String kRenewHint = 'افتح التطبيق لتجديد التذكير';

/// The next [days] daily reminders for every enabled slot, in time order.
/// Entries in the list's last [kRenewHintDays] days ask the reader to open
/// the app, which plans the list again.
List<PlannedReminder> planReminders({
  required Map<ReminderSlot, ReminderSetting> settings,
  required Map<int, String> titles,
  required DateTime now,
  int days = kReminderDays,
}) {
  final planned = <PlannedReminder>[];
  for (final MapEntry(key: slot, value: setting) in settings.entries) {
    if (!setting.enabled) continue;
    var day = 0;
    var added = 0;
    while (added < days) {
      final at = DateTime(
        now.year,
        now.month,
        now.day + day,
        setting.minuteOfDay ~/ 60,
        setting.minuteOfDay % 60,
      );
      day++;
      if (!at.isAfter(now)) continue;
      planned.add(
        PlannedReminder(
          at: at,
          titleId: slot.titleId,
          title: titles[slot.titleId] ?? '',
          body: added >= days - kRenewHintDays ? kRenewHint : '',
        ),
      );
      added++;
    }
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned;
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd alazkar && fvm flutter test test/reminder_planner_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Format, analyze, commit**

```bash
cd alazkar
fvm dart format lib/src/features/reminders test/reminder_planner_test.dart
fvm flutter analyze
git add lib/src/features/reminders test/reminder_planner_test.dart
git commit -m "Reminders: plan the next 90 days of daily reminders"
```

---

### Task 2: Storage

**Files:**
- Create: `alazkar/lib/src/features/reminders/data/repository/reminder_storage.dart`
- Test: `alazkar/test/reminder_storage_test.dart`

**Interfaces:**
- Consumes: `ReminderSlot`, `ReminderSetting` (Task 1); `KVStorage`; `MemoryStorage` from `test/support/memory_storage.dart`.
- Produces: `class ReminderStorage { ReminderStorage(KVStorage); ReminderSetting read(ReminderSlot); Map<ReminderSlot, ReminderSetting> readAll(); Future<void> write(ReminderSlot, ReminderSetting); }`.

- [ ] **Step 1: Write the failing test**

```dart
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

  test('a saved reminder is read back, and the others are untouched',
      () async {
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd alazkar && fvm flutter test test/reminder_storage_test.dart`
Expected: FAIL, `reminder_storage.dart` does not exist.

- [ ] **Step 3: Write the storage**

```dart
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd alazkar && fvm flutter test test/reminder_storage_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Format, analyze, commit**

```bash
cd alazkar
fvm dart format lib/src/features/reminders test/reminder_storage_test.dart
fvm flutter analyze
git add lib/src/features/reminders test/reminder_storage_test.dart
git commit -m "Reminders: store each reminder's switch and time"
```

---

### Task 3: Platform interface and cubit

**Files:**
- Create: `alazkar/lib/src/features/reminders/data/reminder_platform.dart`
- Create: `alazkar/lib/src/features/reminders/presentation/controller/reminders_cubit.dart`
- Create: `alazkar/lib/src/features/reminders/presentation/controller/reminders_state.dart`
- Test: `alazkar/test/reminders_cubit_test.dart`

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces:
  - `abstract class ReminderPlatform { Future<void> schedule(List<PlannedReminder>); Future<bool> notificationsAllowed(); Future<bool> requestNotificationPermission(); }`
  - `class ReminderChannel implements ReminderPlatform` on `MethodChannel('reminder_channel')`, plus `static Future<int?> takeLaunchTitleId()` and `static void onOpenTitle(void Function(int titleId) open)`.
  - `class RemindersState { Map<ReminderSlot, ReminderSetting> settings; Map<int, String> titles; bool notificationsBlocked; }`
  - `class RemindersCubit { RemindersCubit(ReminderStorage, ReminderPlatform, Future<Map<int, String>> Function() loadTitles, {DateTime Function()? clock}); Future<void> start(); Future<bool> setEnabled(ReminderSlot, bool); Future<void> setMinuteOfDay(ReminderSlot, int); }`
  - Method channel contract with Android:

    | Dart → Android | Arguments | Returns |
    |---|---|---|
    | `schedule` | list of `PlannedReminder.toMap()` | null |
    | `notificationsAllowed` | — | bool |
    | `requestNotificationPermission` | — | bool |
    | `takeLaunchTitleId` | — | int or null |

    | Android → Dart | Arguments |
    |---|---|
    | `openTitle` | int title id |

- [ ] **Step 1: Write the failing test**

```dart
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

  FakeReminderPlatform({this.allowed = true, this.grants = true});

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async =>
      scheduled.add(reminders);

  @override
  Future<bool> notificationsAllowed() async => allowed;

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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd alazkar && fvm flutter test test/reminders_cubit_test.dart`
Expected: FAIL, the platform and cubit files do not exist.

- [ ] **Step 3: Write the platform interface and channel**

`alazkar/lib/src/features/reminders/data/reminder_platform.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class ReminderPlatform {
  Future<void> schedule(List<PlannedReminder> reminders);
  Future<bool> notificationsAllowed();
  Future<bool> requestNotificationPermission();
}

class ReminderChannel implements ReminderPlatform {
  static const MethodChannel channel = MethodChannel('reminder_channel');

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    if (!_isAndroid) return;
    await channel.invokeMethod<void>(
      'schedule',
      reminders.map((reminder) => reminder.toMap()).toList(),
    );
  }

  @override
  Future<bool> notificationsAllowed() async {
    if (!_isAndroid) return false;
    return await channel.invokeMethod<bool>('notificationsAllowed') ?? false;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return false;
    return await channel.invokeMethod<bool>('requestNotificationPermission') ??
        false;
  }

  /// The section a tapped notification asked for when it started the app.
  static Future<int?> takeLaunchTitleId() async {
    if (!_isAndroid) return null;
    return channel.invokeMethod<int>('takeLaunchTitleId');
  }

  /// Called when a notification is tapped while the app is already running.
  static void onOpenTitle(void Function(int titleId) open) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openTitle') open(call.arguments as int);
    });
  }
}
```

- [ ] **Step 4: Write the state and cubit**

`alazkar/lib/src/features/reminders/presentation/controller/reminders_state.dart`:

```dart
part of 'reminders_cubit.dart';

class RemindersState extends Equatable {
  final Map<ReminderSlot, ReminderSetting> settings;
  final Map<int, String> titles;
  final bool notificationsBlocked;

  const RemindersState({
    required this.settings,
    this.titles = const {},
    this.notificationsBlocked = false,
  });

  RemindersState copyWith({
    Map<ReminderSlot, ReminderSetting>? settings,
    Map<int, String>? titles,
    bool? notificationsBlocked,
  }) {
    return RemindersState(
      settings: settings ?? this.settings,
      titles: titles ?? this.titles,
      notificationsBlocked: notificationsBlocked ?? this.notificationsBlocked,
    );
  }

  @override
  List<Object> get props => [settings, titles, notificationsBlocked];
}
```

`alazkar/lib/src/features/reminders/presentation/controller/reminders_cubit.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  final ReminderStorage storage;
  final ReminderPlatform platform;
  final Future<Map<int, String>> Function() loadTitles;
  final DateTime Function() clock;

  RemindersCubit(
    this.storage,
    this.platform,
    this.loadTitles, {
    DateTime Function()? clock,
  })  : clock = clock ?? DateTime.now,
        super(RemindersState(settings: storage.readAll()));

  /// Runs on every app start: reads the titles, notices a permission
  /// revoked in the phone's settings, and plans the list again so it
  /// never runs out while the app is in use.
  Future<void> start() async {
    final titles = await loadTitles();
    final anyOn = state.settings.values.any((setting) => setting.enabled);
    final allowed = await platform.notificationsAllowed();
    emit(
      state.copyWith(titles: titles, notificationsBlocked: anyOn && !allowed),
    );
    await _reschedule();
  }

  /// Returns false when the reader refused the notification permission.
  Future<bool> setEnabled(ReminderSlot slot, bool enabled) async {
    if (enabled && !await platform.requestNotificationPermission()) {
      emit(state.copyWith(notificationsBlocked: true));
      return false;
    }
    if (enabled) emit(state.copyWith(notificationsBlocked: false));
    await _save(slot, state.settings[slot]!.copyWith(enabled: enabled));
    return true;
  }

  Future<void> setMinuteOfDay(ReminderSlot slot, int minuteOfDay) {
    return _save(
      slot,
      state.settings[slot]!.copyWith(minuteOfDay: minuteOfDay),
    );
  }

  Future<void> _save(ReminderSlot slot, ReminderSetting setting) async {
    await storage.write(slot, setting);
    emit(state.copyWith(settings: {...state.settings, slot: setting}));
    await _reschedule();
  }

  Future<void> _reschedule() {
    return platform.schedule(
      planReminders(
        settings: state.settings,
        titles: state.titles,
        now: clock(),
      ),
    );
  }
}
```

`_reschedule` reads `state.titles`, which `start()` fills. `setEnabled` and `setMinuteOfDay` are reachable only from the screen, after `start()` has run at app launch.

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd alazkar && fvm flutter test test/reminders_cubit_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Format, analyze, commit**

```bash
cd alazkar
fvm dart format lib/src/features/reminders test/reminders_cubit_test.dart
fvm flutter analyze
git add lib/src/features/reminders test/reminders_cubit_test.dart
git commit -m "Reminders: cubit and the channel contract with Android"
```

---

### Task 4: Android side

**Files:**
- Create: `alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/reminders/ReminderStore.kt`
- Create: `.../reminders/ReminderScheduler.kt`
- Create: `.../reminders/ReminderReceiver.kt`
- Create: `.../reminders/BootReceiver.kt`
- Create: `.../reminders/ReminderNotifier.kt`
- Modify: `alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/MainActivity.kt`
- Modify: `alazkar/android/app/src/main/AndroidManifest.xml`
- Modify: `alazkar/android/app/src/main/res/values/strings.xml`

**Interfaces:**
- Consumes: the channel contract from Task 3. Each list entry is a map with `year, month, day, minuteOfDay, titleId, title, body`.
- Produces: alarms and notifications. A tapped notification starts `MainActivity` with the extra `reminder_title_id`.

There are no Kotlin unit tests in this project, so this task is verified on the emulator in Step 9.

- [ ] **Step 1: `ReminderStore.kt`**

```kotlin
package com.menemlabs.zaadalthakir.reminders

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

data class PlannedReminder(
    val year: Int,
    val month: Int,
    val day: Int,
    val minuteOfDay: Int,
    val titleId: Int,
    val title: String,
    val body: String,
) {
    /** The moment in the phone's current time zone. */
    fun atMillis(): Long = Calendar.getInstance().apply {
        clear()
        set(year, month - 1, day, minuteOfDay / 60, minuteOfDay % 60, 0)
    }.timeInMillis
}

object ReminderStore {
    private const val PREFS = "reminders"
    private const val KEY = "planned"

    fun fromMaps(maps: List<Map<String, Any?>>): List<PlannedReminder> = maps.map {
        PlannedReminder(
            year = (it["year"] as Number).toInt(),
            month = (it["month"] as Number).toInt(),
            day = (it["day"] as Number).toInt(),
            minuteOfDay = (it["minuteOfDay"] as Number).toInt(),
            titleId = (it["titleId"] as Number).toInt(),
            title = it["title"] as String,
            body = it["body"] as String,
        )
    }

    fun save(context: Context, reminders: List<PlannedReminder>) {
        val array = JSONArray()
        reminders.forEach {
            array.put(
                JSONObject()
                    .put("year", it.year).put("month", it.month).put("day", it.day)
                    .put("minuteOfDay", it.minuteOfDay).put("titleId", it.titleId)
                    .put("title", it.title).put("body", it.body)
            )
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, array.toString()).commit()
    }

    fun load(context: Context): List<PlannedReminder> {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return emptyList()
        val array = JSONArray(json)
        return (0 until array.length()).map { index ->
            val item = array.getJSONObject(index)
            PlannedReminder(
                year = item.getInt("year"),
                month = item.getInt("month"),
                day = item.getInt("day"),
                minuteOfDay = item.getInt("minuteOfDay"),
                titleId = item.getInt("titleId"),
                title = item.getString("title"),
                body = item.getString("body"),
            )
        }
    }
}
```

- [ ] **Step 2: `ReminderScheduler.kt`**

```kotlin
package com.menemlabs.zaadalthakir.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object ReminderScheduler {
    private const val WINDOW_MS = 15 * 60 * 1000L

    /** Drops what has passed and keeps one alarm for the earliest entry. */
    fun scheduleNext(context: Context) {
        val now = System.currentTimeMillis()
        val upcoming = ReminderStore.load(context)
            .filter { it.atMillis() > now }
            .sortedBy { it.atMillis() }
        ReminderStore.save(context, upcoming)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val alarm = alarmIntent(context)
        alarmManager.cancel(alarm)
        val next = upcoming.firstOrNull() ?: return
        alarmManager.setWindow(AlarmManager.RTC_WAKEUP, next.atMillis(), WINDOW_MS, alarm)
    }

    private fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
```

- [ ] **Step 3: `ReminderReceiver.kt` and `BootReceiver.kt`**

```kotlin
package com.menemlabs.zaadalthakir.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val now = System.currentTimeMillis()
        ReminderStore.load(context)
            .filter { it.atMillis() <= now && it.atMillis() > now - STALE_MS }
            .forEach { ReminderNotifier.show(context, it) }
        ReminderScheduler.scheduleNext(context)
    }

    companion object {
        /** A reminder more than an hour late (the phone was off) is skipped. */
        private const val STALE_MS = 60 * 60 * 1000L
    }
}
```

```kotlin
package com.menemlabs.zaadalthakir.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Alarms do not survive a reboot, and a clock change moves local times. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReminderScheduler.scheduleNext(context)
    }
}
```

- [ ] **Step 4: `ReminderNotifier.kt`**

```kotlin
package com.menemlabs.zaadalthakir.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.menemlabs.zaadalthakir.MainActivity
import com.menemlabs.zaadalthakir.R

object ReminderNotifier {
    private const val CHANNEL_ID = "daily_reminders"
    const val EXTRA_TITLE_ID = "reminder_title_id"

    fun show(context: Context, reminder: PlannedReminder) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.reminder_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
            )
        }
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_TITLE_ID, reminder.titleId)
        }
        val content = PendingIntent.getActivity(
            context,
            reminder.titleId,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        builder.setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(reminder.title)
            .setContentIntent(content)
            .setAutoCancel(true)
        if (reminder.body.isNotEmpty()) builder.setContentText(reminder.body)
        manager.notify(reminder.titleId, builder.build())
    }
}
```

- [ ] **Step 5: `strings.xml`**

Add inside `<resources>`:

```xml
<string name="reminder_channel_name">التذكير</string>
```

- [ ] **Step 6: `AndroidManifest.xml`**

Add after the existing `VIBRATE` permission:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Add inside `<application>`, after `</activity>`:

```xml
<receiver
    android:name=".reminders.ReminderReceiver"
    android:exported="false" />
<receiver
    android:name=".reminders.BootReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.TIME_SET" />
        <action android:name="android.intent.action.TIMEZONE_CHANGED" />
    </intent-filter>
</receiver>
```

`BootReceiver` is exported because these are system broadcasts; only the system can send these protected actions.

- [ ] **Step 7: `MainActivity.kt`**

Add imports:

```kotlin
import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import com.menemlabs.zaadalthakir.reminders.ReminderNotifier
import com.menemlabs.zaadalthakir.reminders.ReminderScheduler
import com.menemlabs.zaadalthakir.reminders.ReminderStore
```

Add fields to the class:

```kotlin
private var reminderChannel: MethodChannel? = null
private var pendingPermissionResult: MethodChannel.Result? = null
private var launchTitleId: Int? = null
```

At the end of `configureFlutterEngine`:

```kotlin
launchTitleId = titleIdFrom(intent)
reminderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "reminder_channel").also {
    it.setMethodCallHandler { call, result ->
        when (call.method) {
            "schedule" -> {
                @Suppress("UNCHECKED_CAST")
                val maps = call.arguments as List<Map<String, Any?>>
                ReminderStore.save(this, ReminderStore.fromMaps(maps))
                ReminderScheduler.scheduleNext(this)
                result.success(null)
            }
            "notificationsAllowed" -> result.success(notificationsAllowed())
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "takeLaunchTitleId" -> {
                result.success(launchTitleId)
                launchTitleId = null
            }
            else -> result.notImplemented()
        }
    }
}
```

New methods in the class:

```kotlin
private fun notificationsAllowed(): Boolean =
    (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()

private fun requestNotificationPermission(result: MethodChannel.Result) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    ) {
        result.success(notificationsAllowed())
        return
    }
    pendingPermissionResult = result
    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
}

override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode != REQUEST_NOTIFICATIONS) return
    pendingPermissionResult?.success(
        grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
    )
    pendingPermissionResult = null
}

override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    titleIdFrom(intent)?.let { reminderChannel?.invokeMethod("openTitle", it) }
}

private fun titleIdFrom(intent: Intent?): Int? =
    intent?.getIntExtra(ReminderNotifier.EXTRA_TITLE_ID, -1)?.takeIf { it > 0 }

companion object {
    private const val REQUEST_NOTIFICATIONS = 4101
}
```

- [ ] **Step 8: Build**

Run: `cd alazkar && fvm flutter build apk --flavor prod --release`
Expected: `✓ Built build/app/outputs/flutter-apk/app-prod-release.apk`.
Then check that neither exact-alarm permission is declared:
`~/Android/Sdk/build-tools/36.0.0/aapt dump permissions build/app/outputs/flutter-apk/app-prod-release.apk | grep -i -E "alarm|NOTIFICATIONS|BOOT"`
Expected: `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`, and no `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`.

- [ ] **Step 9: Verify on the emulator, through a throwaway call from Dart**

The screen comes in Task 5. Until then, check the Android side by sending a list straight to the channel through a throwaway integration test, which is not committed. Write `integration_test/zz_native_check_test.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native scheduling', (tester) async {
    final soon = DateTime.now().add(const Duration(minutes: 2));
    final at = DateTime(soon.year, soon.month, soon.day, soon.hour, soon.minute);
    await ReminderChannel().schedule([
      PlannedReminder(at: at, titleId: 1, title: 'أذكار الصباح', body: ''),
      PlannedReminder(at: at, titleId: 2, title: 'أذكار المساء', body: ''),
      PlannedReminder(
        at: at.add(const Duration(days: 1)),
        titleId: 1,
        title: 'أذكار الصباح',
        body: '',
      ),
    ]);
  });
}
```

Boot the emulator (pixel_7 AVD, Android 14), then:

1. `adb uninstall com.menemlabs.zaadalthakir; fvm flutter test integration_test/zz_native_check_test.dart --flavor prod -d emulator-5554`
2. `adb shell pm grant com.menemlabs.zaadalthakir android.permission.POST_NOTIFICATIONS`
3. `adb shell dumpsys alarm | grep -B2 -A6 zaadalthakir`. Expect one alarm with a 15-minute window, about two minutes away.
4. Wait for the window. Then `adb shell dumpsys notification --noredact | grep -A3 "pkg=com.menemlabs.zaadalthakir"`. Expect two notifications with the titles «أذكار الصباح» and «أذكار المساء» (Review Focus 3).
5. `adb shell dumpsys alarm | grep -A6 zaadalthakir`. Expect the next alarm, tomorrow.
6. Time-zone check (Review Focus 1): `adb shell cmd alarm set-timezone Asia/Riyadh`, then `dumpsys alarm`. The alarm should move so that it still fires at the same local wall time. Restore with `adb shell cmd alarm set-timezone Africa/Cairo`.
7. Reboot check (Review Focus 2): `adb reboot`, wait for boot, then `dumpsys alarm`. Expect the alarm set again, and no notification for any entry over an hour overdue.
8. Delete `integration_test/zz_native_check_test.dart`. Record the outputs of steps 3 to 7 in the pull request.

- [ ] **Step 10: Commit**

```bash
cd alazkar
git add android/app/src/main
git commit -m "Reminders: Android alarm, notification and reboot handling"
```

---

### Task 5: Screen, settings entry, app launch, journey

**Files:**
- Create: `alazkar/lib/src/features/reminders/presentation/screens/reminders_screen.dart`
- Create: `alazkar/lib/src/features/reminders/presentation/components/reminder_launch_listener.dart`
- Modify: `alazkar/lib/src/core/di/dependency_injection.dart`
- Modify: `alazkar/lib/app.dart` (`home:`)
- Modify: `alazkar/lib/src/features/settings/presentation/screens/settings_screen.dart`
- Modify: `alazkar/integration_test/app_journeys_test.dart`
- Modify: `privacy.md`

**Interfaces:**
- Consumes: `RemindersCubit` (Task 3); `ReminderChannel.takeLaunchTitleId`, `ReminderChannel.onOpenTitle` (Task 3); `AzkarDBHelper.getTitlesById(int)`; `ZikrContentViewerScreen.route(zikrTitleId:)`; `MyApp.navigatorKey`; `showToast(String)`.
- Produces: `RemindersScreen`, `ReminderLaunchListener({required Widget child})`, `Future<Map<int, String>> loadReminderTitles(AzkarDBHelper db)`.

- [ ] **Step 1: Write the failing journey step**

In `integration_test/app_journeys_test.dart`, add the import:

```dart
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
```

Then add at the end of the `core reading journeys` test body, after the last existing expectation:

```dart
    // Reminders: the screen lists the three sections by their book titles,
    // turning one on hands Android its daily times, and a refused permission
    // leaves the switch off with an explanation. Only the native side of
    // the reminder channel is replaced.
    await backHome(tester);
    var grant = true;
    final scheduled = <List<Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      ReminderChannel.channel,
      (call) async {
        switch (call.method) {
          case 'schedule':
            scheduled.add(call.arguments as List<Object?>);
            return null;
          case 'requestNotificationPermission':
            return grant;
          case 'notificationsAllowed':
            return grant;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(ReminderChannel.channel, null),
    );
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التذكير'));
    await tester.pumpAndSettle();
    for (final title in ['أذكار الصباح', 'أذكار المساء', 'أذكار النوم']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();
    final morning = scheduled.last.cast<Map<Object?, Object?>>();
    expect(morning.map((e) => e['titleId']).toSet(), {1});
    expect(morning.map((e) => e['minuteOfDay']).toSet(), {6 * 60});
    expect(morning.first['title'], 'أذكار الصباح');

    grant = false;
    await tester.tap(find.byKey(const ValueKey('reminder-switch-evening')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('reminder-switch-evening')),
          )
          .value,
      isFalse,
    );
    expect(
      find.text(
        'الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف',
      ),
      findsWidgets,
    );
```

- [ ] **Step 2: Run the journey to verify it fails**

Boot the emulator, then run: `adb uninstall com.menemlabs.zaadalthakir; cd alazkar && fvm flutter test integration_test --flavor prod -d emulator-5554`
Expected: FAIL, no «التذكير» entry in Settings.

- [ ] **Step 3: Write the launch listener and title loader**

`alazkar/lib/src/features/reminders/presentation/components/reminder_launch_listener.dart`:

```dart
import 'package:alazkar/app.dart';
import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/helpers/azkar_helper.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/zikr_content_viewer/presentation/screens/zikr_content_viewer_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The section titles exactly as the database holds them.
Future<Map<int, String>> loadReminderTitles(AzkarDBHelper db) async {
  return {
    for (final slot in ReminderSlot.values)
      slot.titleId: (await db.getTitlesById(slot.titleId)).name,
  };
}

/// Opens the section of a tapped reminder, and plans the reminders again
/// on every app start so the list never runs out while the app is used.
class ReminderLaunchListener extends StatefulWidget {
  final Widget child;

  const ReminderLaunchListener({super.key, required this.child});

  @override
  State<ReminderLaunchListener> createState() =>
      _ReminderLaunchListenerState();
}

class _ReminderLaunchListenerState extends State<ReminderLaunchListener> {
  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.android) return;
    ReminderChannel.onOpenTitle(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final titleId = await ReminderChannel.takeLaunchTitleId();
      if (titleId != null) _open(titleId);
      await sl<RemindersCubit>().start();
    });
  }

  void _open(int titleId) {
    MyApp.navigatorKey.currentState?.push(
      ZikrContentViewerScreen.route(zikrTitleId: titleId),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

In `app.dart`, add the import for `reminder_launch_listener.dart`, and change `home: const HomePageScreen(),` to:

```dart
            home: const ReminderLaunchListener(child: HomePageScreen()),
```

- [ ] **Step 4: Register in DI**

In `dependency_injection.dart`, add imports for `reminder_storage.dart`, `reminder_platform.dart`, `reminders_cubit.dart` and `reminder_launch_listener.dart`. Under `///MARK: Init storages` add:

```dart
  sl.registerLazySingleton(() => ReminderStorage(sl()));
```

Under `///MARK: Init Manager` add:

```dart
  sl.registerLazySingleton<ReminderPlatform>(() => ReminderChannel());
```

Under `/// Singleton BLoC` add:

```dart
  sl.registerLazySingleton(
    () => RemindersCubit(sl(), sl(), () => loadReminderTitles(sl())),
  );
```

- [ ] **Step 5: Write the screen**

`alazkar/lib/src/features/reminders/presentation/screens/reminders_screen.dart`:

```dart
import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kNotificationsBlocked =
    'الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<RemindersCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('التذكير'), centerTitle: true),
        body: BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                for (final slot in ReminderSlot.values)
                  _ReminderCard(
                    slot: slot,
                    title: state.titles[slot.titleId] ?? '',
                    setting: state.settings[slot]!,
                  ),
                if (state.notificationsBlocked)
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      kNotificationsBlocked,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderSlot slot;
  final String title;
  final ReminderSetting setting;

  const _ReminderCard({
    required this.slot,
    required this.title,
    required this.setting,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final time = TimeOfDay(
      hour: setting.minuteOfDay ~/ 60,
      minute: setting.minuteOfDay % 60,
    );
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: ValueKey('reminder-switch-${slot.name}'),
            title: Text(title),
            value: setting.enabled,
            onChanged: (value) async {
              final ok = await cubit.setEnabled(slot, value);
              if (!ok) showToast(kNotificationsBlocked);
            },
          ),
          ListTile(
            enabled: setting.enabled,
            leading: const Icon(Icons.schedule),
            title: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(time),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked == null) return;
              await cubit.setMinuteOfDay(
                slot,
                picked.hour * 60 + picked.minute,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Add the Settings entry**

In `settings_screen.dart`, add imports for `reminders_screen.dart` and `package:flutter/foundation.dart`. After `const VibrateOnCountDoneSwitch(),` add:

```dart
          if (defaultTargetPlatform == TargetPlatform.android)
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('التذكير'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RemindersScreen(),
                  ),
                );
              },
            ),
```

- [ ] **Step 7: Run the unit tests and the journey**

Run: `cd alazkar && fvm flutter analyze && fvm flutter test`
Expected: no issues; all tests pass.
Run: `adb uninstall com.menemlabs.zaadalthakir; fvm flutter test integration_test --flavor prod -d emulator-5554`
Expected: `All tests passed!`

- [ ] **Step 8: Tapping a notification, by hand (AC-004, Review Focus 5)**

Install the release APK on the emulator. Then:
1. `adb shell pm grant com.menemlabs.zaadalthakir android.permission.POST_NOTIFICATIONS`
2. In the app, set «أذكار النوم» to two minutes from now and turn it on.
3. Close the app (swipe it away). When the notification arrives, tap it. Expect «أذكار النوم» to open; back returns home.
4. Repeat with the app open on «أذكار الصباح». Expect «أذكار النوم» to open on top; back returns to «أذكار الصباح».
5. Screenshot both, and the reminders screen in day and night mode, for the pull request.

- [ ] **Step 9: Privacy note**

In `privacy.md`, add a paragraph to both the Arabic and English sections stating:
- the app schedules local notifications only for reminders the reader turns on;
- it sends nothing anywhere;
- it needs the notification permission only for this.

- [ ] **Step 10: Format, commit**

```bash
cd alazkar
fvm dart format lib/src/features/reminders lib/src/core/di/dependency_injection.dart lib/app.dart lib/src/features/settings/presentation/screens/settings_screen.dart integration_test/app_journeys_test.dart
git add lib integration_test ../privacy.md
git commit -m "Reminders: settings screen, opening a section from a notification"
```

---

### Task 6: Size, real phone, pull request

- [ ] **Step 1: Size before and after**

On `main`, run `fvm flutter build apk --flavor prod --release --split-per-abi` and note the arm64 APK size. Repeat on the branch, and record both in the pull request (AC-007).

- [ ] **Step 2: Real phone**

Put the arm64 release APK in `~/Downloads` for the owner, and ask them to:
- turn on all three reminders;
- confirm a day later that each one arrived within 15 minutes of its time;
- confirm that tapping each one opened its section.

- [ ] **Step 3: Mark the intent's verification plan**

In `docs/features/daily-reminders/intent.md`, set AC-001 to AC-007 to `Verified`. Give each its evidence: the test name, or the pull request comment holding the `dumpsys` output.

- [ ] **Step 4: Pull request**

Push the branch, and open a pull request against `main` titled «Daily reminders, phase 1: fixed times». Its body holds:
- the AC table;
- the emulator outputs;
- the screenshots;
- the size difference;
- a note that the renewal line «افتح التطبيق لتجديد التذكير» is app text awaiting the owner's approval.

Merge after the owner confirms the real-phone check.
