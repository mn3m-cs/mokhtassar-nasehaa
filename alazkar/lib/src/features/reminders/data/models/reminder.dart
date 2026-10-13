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
