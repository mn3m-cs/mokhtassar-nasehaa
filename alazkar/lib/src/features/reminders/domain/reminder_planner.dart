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
