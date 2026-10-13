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
