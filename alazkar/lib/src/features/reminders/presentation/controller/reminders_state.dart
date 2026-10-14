part of 'reminders_cubit.dart';

class RemindersState extends Equatable {
  final Map<ReminderSlot, ReminderSetting> settings;
  final Map<int, String> titles;
  final bool notificationsBlocked;
  final Place? place;

  /// The method the reader picked by hand; null follows the country.
  final PrayerMethod? chosenMethod;
  final AsrMadhab madhab;

  /// Today's prayer times at [place], for the times shown on the screen.
  final PrayerDay? today;

  /// A morning or evening reminder is waiting for a place.
  final bool locationNeeded;

  /// The phone is looking for its location.
  final bool locating;

  const RemindersState({
    required this.settings,
    this.titles = const {},
    this.notificationsBlocked = false,
    this.place,
    this.chosenMethod,
    this.madhab = AsrMadhab.majority,
    this.today,
    this.locationNeeded = false,
    this.locating = false,
  });

  PrayerMethod? get method =>
      chosenMethod ??
      (place == null ? null : methodForCountry(place!.countryCode));

  RemindersState copyWith({
    Map<ReminderSlot, ReminderSetting>? settings,
    Map<int, String>? titles,
    bool? notificationsBlocked,
    Place? place,
    PrayerMethod? chosenMethod,
    AsrMadhab? madhab,
    PrayerDay? today,
    bool? locationNeeded,
    bool? locating,
  }) {
    return RemindersState(
      settings: settings ?? this.settings,
      titles: titles ?? this.titles,
      notificationsBlocked: notificationsBlocked ?? this.notificationsBlocked,
      place: place ?? this.place,
      chosenMethod: chosenMethod ?? this.chosenMethod,
      madhab: madhab ?? this.madhab,
      today: today ?? this.today,
      locationNeeded: locationNeeded ?? this.locationNeeded,
      locating: locating ?? this.locating,
    );
  }

  @override
  List<Object?> get props => [
        settings,
        titles,
        notificationsBlocked,
        place,
        chosenMethod,
        madhab,
        today,
        locationNeeded,
        locating,
      ];
}
