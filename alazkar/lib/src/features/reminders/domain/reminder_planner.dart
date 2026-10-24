import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_quotes.dart';

const int kReminderDays = 90;
const int kRenewHintDays = 7;
const String kRenewHint = 'افتح التطبيق لتجديد التذكير';

/// The next [days] daily reminders for every enabled slot, in time order.
/// Prayer-relative reminders need [prayerDayOf], and are left out until
/// there is a place to compute it for. Entries in the list's last
/// [kRenewHintDays] days ask the reader to open the app, which plans the
/// list again.
List<PlannedReminder> planReminders({
  required Map<ReminderSlot, ReminderSetting> settings,
  required Map<int, String> titles,
  required DateTime now,
  PrayerDay Function(DateTime day)? prayerDayOf,
  int days = kReminderDays,
}) {
  final planned = <PlannedReminder>[];
  for (final MapEntry(key: slot, value: setting) in settings.entries) {
    if (!setting.enabled) continue;
    if (setting.kind.needsPrayerTimes && prayerDayOf == null) continue;
    var day = 0;
    var added = 0;
    while (added < days) {
      final date = DateTime(now.year, now.month, now.day + day);
      day++;
      final minute = reminderMinute(
        setting,
        setting.kind.needsPrayerTimes ? prayerDayOf!(date) : null,
      )!;
      final at = DateTime(
        date.year,
        date.month,
        date.day,
        minute ~/ 60,
        minute % 60,
      );
      if (!at.isAfter(now)) continue;
      planned.add(
        PlannedReminder(
          at: at,
          titleId: slot.titleId,
          title: titles[slot.titleId] ?? '',
          body: reminderBody(
            quoteFor(slot.titleId, date),
            renewHint: added >= days - kRenewHintDays ? kRenewHint : null,
          ),
        ),
      );
      added++;
    }
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned;
}

/// The minute after local midnight a reminder fires on a day, or null for
/// a prayer-relative reminder when [day] is unknown.
int? reminderMinute(ReminderSetting setting, PrayerDay? day) {
  return switch (setting.kind) {
    ReminderKind.fixed => setting.minuteOfDay,
    ReminderKind.afterFajr =>
      day == null ? null : day.fajr + setting.offsetMinutes,
    ReminderKind.afterAsr =>
      day == null ? null : day.asr + setting.offsetMinutes,
    ReminderKind.beforeMaghrib =>
      day == null ? null : day.maghrib - setting.offsetMinutes,
  };
}
