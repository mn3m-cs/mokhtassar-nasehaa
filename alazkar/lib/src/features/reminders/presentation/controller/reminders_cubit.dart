import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'reminders_state.dart';

enum ReminderToggle { done, notificationsRefused, locationNeeded }

class RemindersCubit extends Cubit<RemindersState> {
  final ReminderStorage storage;
  final ReminderPlatform platform;
  final Future<Map<int, String>> Function() loadTitles;
  final CityRepository cities;
  final DateTime Function() clock;
  final Duration Function(DateTime day)? utcOffsetOf;

  /// The reader refused the permission in this session; the blocked line
  /// stays until notifications are allowed, even with every switch off.
  bool _refused = false;

  RemindersCubit(
    this.storage,
    this.platform,
    this.loadTitles,
    this.cities, {
    DateTime Function()? clock,
    this.utcOffsetOf,
  })  : clock = clock ?? DateTime.now,
        super(
          RemindersState(
            settings: storage.readAll(),
            place: storage.readPlace(),
            chosenMethod: storage.readMethod(),
            madhab: storage.readMadhab(),
          ),
        );

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

  Future<ReminderToggle> setEnabled(ReminderSlot slot, bool enabled) async {
    if (enabled && !await platform.requestNotificationPermission()) {
      _refused = true;
      emit(state.copyWith(notificationsBlocked: true));
      return ReminderToggle.notificationsRefused;
    }
    if (enabled) emit(state.copyWith(notificationsBlocked: false));
    if (enabled &&
        slot.needsPlace &&
        state.place == null &&
        !await updateLocation()) {
      return ReminderToggle.locationNeeded;
    }
    await _save(slot, state.settings[slot]!.copyWith(enabled: enabled));
    return ReminderToggle.done;
  }

  /// Reads the approximate device location once and names it after the
  /// nearest city. False when it is refused or unavailable.
  Future<bool> updateLocation() async {
    emit(state.copyWith(locating: true));
    final location = await platform.requestLocation();
    emit(state.copyWith(locating: false));
    if (location == null) {
      emit(state.copyWith(locationNeeded: true));
      return false;
    }
    final city = await cities.nearest(location.latitude, location.longitude);
    await setPlace(city.withCoordinates(location.latitude, location.longitude));
    return true;
  }

  Future<void> setPlace(Place place) async {
    await storage.writePlace(place);
    emit(state.copyWith(place: place, locationNeeded: false));
    await _reschedule();
  }

  Future<void> setMethod(PrayerMethod method) async {
    await storage.writeMethod(method);
    emit(state.copyWith(chosenMethod: method));
    await _reschedule();
  }

  Future<void> setMadhab(AsrMadhab madhab) async {
    await storage.writeMadhab(madhab);
    emit(state.copyWith(madhab: madhab));
    await _reschedule();
  }

  Future<void> setKind(ReminderSlot slot, ReminderKind kind) {
    return _save(slot, state.settings[slot]!.copyWith(kind: kind));
  }

  Future<void> setOffset(ReminderSlot slot, int offsetMinutes) {
    return _save(
      slot,
      state.settings[slot]!.copyWith(offsetMinutes: offsetMinutes),
    );
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
    final place = state.place;
    final calculator = place == null
        ? null
        : PrayerTimesCalculator(
            latitude: place.latitude,
            longitude: place.longitude,
            method: state.method!,
            madhab: state.madhab,
            utcOffsetOf: utcOffsetOf,
          );
    final now = clock();
    final waiting = place == null &&
        state.settings.entries
            .any((entry) => entry.value.enabled && entry.key.needsPlace);
    emit(
      state.copyWith(
        today: calculator?.dayOf(now),
        locationNeeded: waiting || state.locationNeeded,
      ),
    );
    return platform.schedule(
      planReminders(
        settings: state.settings,
        titles: state.titles,
        now: now,
        prayerDayOf: calculator?.dayOf,
      ),
    );
  }
}
