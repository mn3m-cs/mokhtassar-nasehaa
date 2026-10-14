import 'package:equatable/equatable.dart';

const int kDefaultSleepMinute = 22 * 60;
const int kDefaultOffsetMinutes = 30;
const List<int> kOffsetChoices = [
  5,
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60
];

enum ReminderKind {
  fixed(''),
  afterFajr('بعد الفجر'),
  afterAsr('بعد العصر'),
  beforeMaghrib('قبل المغرب');

  const ReminderKind(this.label);

  final String label;

  bool get needsPrayerTimes => this != fixed;
}

enum ReminderSlot {
  morning(titleId: 1, kinds: [ReminderKind.afterFajr]),
  evening(
    titleId: 2,
    kinds: [ReminderKind.afterAsr, ReminderKind.beforeMaghrib],
  ),
  sleep(titleId: 18, kinds: [ReminderKind.fixed]);

  const ReminderSlot({required this.titleId, required this.kinds});

  final int titleId;

  /// The kinds the reader can choose from; the first is the default.
  final List<ReminderKind> kinds;

  ReminderKind get defaultKind => kinds.first;

  bool get needsPlace => defaultKind.needsPrayerTimes;
}

class ReminderSetting extends Equatable {
  final bool enabled;
  final ReminderKind kind;

  /// The clock time, for [ReminderKind.fixed] only.
  final int minuteOfDay;

  /// Minutes from the prayer, for the prayer-relative kinds only.
  final int offsetMinutes;

  const ReminderSetting({
    required this.enabled,
    this.kind = ReminderKind.fixed,
    this.minuteOfDay = kDefaultSleepMinute,
    this.offsetMinutes = kDefaultOffsetMinutes,
  });

  ReminderSetting copyWith({
    bool? enabled,
    ReminderKind? kind,
    int? minuteOfDay,
    int? offsetMinutes,
  }) {
    return ReminderSetting(
      enabled: enabled ?? this.enabled,
      kind: kind ?? this.kind,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    );
  }

  @override
  List<Object> get props => [enabled, kind, minuteOfDay, offsetMinutes];
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
