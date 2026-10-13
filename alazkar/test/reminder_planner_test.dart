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
}
