import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
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
        ReminderSlot.sleep: const ReminderSetting(enabled: true),
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
      planned.take(kReminderDays - kRenewHintDays).every((r) => r.body.isEmpty),
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

  PrayerTimesCalculator cairoAt(Duration Function(DateTime day) offset) =>
      PrayerTimesCalculator(
        latitude: 30.0444,
        longitude: 31.2357,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.majority,
        utcOffsetOf: offset,
      );

  Map<ReminderSlot, ReminderSetting> morningAfterFajr(int minutes) => {
        ReminderSlot.morning: ReminderSetting(
          enabled: true,
          kind: ReminderKind.afterFajr,
          offsetMinutes: minutes,
        ),
        ReminderSlot.evening: off,
        ReminderSlot.sleep: off,
      };

  int minuteOf(PlannedReminder reminder) =>
      reminder.at.hour * 60 + reminder.at.minute;

  test("AC-008: the morning follows each day's Fajr in Cairo plus 30 minutes",
      () {
    final calculator = cairoAt((_) => const Duration(hours: 2));

    final planned = planReminders(
      settings: morningAfterFajr(30),
      titles: titles,
      now: DateTime(2024, 1, 20),
      prayerDayOf: calculator.dayOf,
    );

    expect(planned, hasLength(kReminderDays));
    // 05:20 in the authority's statement for 20 January 2024.
    expect(minuteOf(planned.first), inInclusiveRange(5 * 60 + 48, 5 * 60 + 52));
    for (final reminder in planned) {
      expect(
        minuteOf(reminder),
        calculator.dayOf(reminder.at).fajr + 30,
        reason: '${reminder.at}',
      );
    }
    expect(planned.map(minuteOf).toSet().length, greaterThan(10));
  });

  test('before Maghrib subtracts the minutes, in Makkah', () {
    final planned = planReminders(
      settings: {
        ReminderSlot.morning: off,
        ReminderSlot.evening: const ReminderSetting(
          enabled: true,
          kind: ReminderKind.beforeMaghrib,
          offsetMinutes: 15,
        ),
        ReminderSlot.sleep: off,
      },
      titles: titles,
      now: DateTime(2016, 6, 4),
      prayerDayOf: PrayerTimesCalculator(
        latitude: 21.427009,
        longitude: 39.828685,
        method: PrayerMethod.ummAlQura,
        madhab: AsrMadhab.majority,
        utcOffsetOf: (_) => const Duration(hours: 3),
      ).dayOf,
    );

    // Maghrib 19:01 in the Umm al-Qura calendar for 4 June 2016.
    expect(
        minuteOf(planned.first), inInclusiveRange(18 * 60 + 44, 18 * 60 + 48));
    expect(planned.first.titleId, 2);
  });

  test('on the summer-time change day the reminder moves with the clock', () {
    final summer = DateTime(2024, 4, 26);
    final calculator = cairoAt(
      (day) => Duration(hours: day.isBefore(summer) ? 2 : 3),
    );

    final planned = planReminders(
      settings: morningAfterFajr(30),
      titles: titles,
      now: DateTime(2024, 4, 24),
      prayerDayOf: calculator.dayOf,
    );

    final minutes = planned.take(4).map(minuteOf).toList();
    expect(minutes[1] - minutes[0], inInclusiveRange(-3, 3));
    expect(minutes[2] - minutes[1], inInclusiveRange(55, 65));
    expect(minutes[3] - minutes[2], inInclusiveRange(-3, 3));
  });

  test('without a place, prayer-relative reminders wait and sleep still fires',
      () {
    final planned = planReminders(
      settings: {
        ReminderSlot.morning: const ReminderSetting(
          enabled: true,
          kind: ReminderKind.afterFajr,
        ),
        ReminderSlot.evening: off,
        ReminderSlot.sleep: const ReminderSetting(enabled: true),
      },
      titles: titles,
      now: DateTime(2026, 10, 13, 12),
    );

    expect(planned.map((r) => r.titleId).toSet(), {18});
  });

  test('reminderMinute reads the right prayer for each kind', () {
    const day = PrayerDay(fajr: 300, asr: 900, maghrib: 1050);

    expect(
      reminderMinute(
        const ReminderSetting(enabled: true, kind: ReminderKind.afterFajr),
        day,
      ),
      330,
    );
    expect(
      reminderMinute(
        const ReminderSetting(
          enabled: true,
          kind: ReminderKind.afterAsr,
          offsetMinutes: 5,
        ),
        day,
      ),
      905,
    );
    expect(
      reminderMinute(
        const ReminderSetting(
          enabled: true,
          kind: ReminderKind.beforeMaghrib,
          offsetMinutes: 60,
        ),
        day,
      ),
      990,
    );
    expect(
      reminderMinute(const ReminderSetting(enabled: true), null),
      1320,
    );
    expect(
      reminderMinute(
        const ReminderSetting(enabled: true, kind: ReminderKind.afterFajr),
        null,
      ),
      isNull,
    );
  });
}
