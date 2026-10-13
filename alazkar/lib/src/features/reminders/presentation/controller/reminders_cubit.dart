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

  /// The reader refused the permission in this session; the blocked line
  /// stays until notifications are allowed, even with every switch off.
  bool _refused = false;

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
    emit(state.copyWith(titles: await loadTitles()));
    await refreshPermission();
    await _reschedule();
  }

  /// Reads the phone's notification setting again, so the blocked line
  /// appears and clears without restarting the app.
  Future<void> refreshPermission() async {
    final anyOn = state.settings.values.any((setting) => setting.enabled);
    final allowed = await platform.notificationsAllowed();
    if (allowed) _refused = false;
    emit(state.copyWith(notificationsBlocked: (anyOn || _refused) && !allowed));
  }

  /// Returns false when the reader refused the notification permission.
  Future<bool> setEnabled(ReminderSlot slot, bool enabled) async {
    if (enabled && !await platform.requestNotificationPermission()) {
      _refused = true;
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
