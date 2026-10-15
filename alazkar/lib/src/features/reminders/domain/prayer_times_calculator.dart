import 'package:adhan/adhan.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:equatable/equatable.dart';

/// The prayer times the reminders follow, in minutes after local midnight.
class PrayerDay extends Equatable {
  final int fajr;
  final int asr;
  final int maghrib;

  const PrayerDay({
    required this.fajr,
    required this.asr,
    required this.maghrib,
  });

  @override
  List<Object> get props => [fajr, asr, maghrib];
}

class PrayerTimesCalculator {
  final double latitude;
  final double longitude;
  final PrayerMethod method;
  final AsrMadhab madhab;

  /// The clock offset in force on a day. The phone's own by default, so
  /// summer time follows automatically; tests pass a fixed one.
  final Duration Function(DateTime day) utcOffsetOf;

  PrayerTimesCalculator({
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.madhab,
    Duration Function(DateTime day)? utcOffsetOf,
  }) : utcOffsetOf = utcOffsetOf ?? _phoneOffset;

  static Duration _phoneOffset(DateTime day) =>
      DateTime(day.year, day.month, day.day, 12).timeZoneOffset;

  PrayerDay dayOf(DateTime day) {
    final parameters = method.calculation.getParameters()
      ..madhab = madhab.adhan;
    final times = PrayerTimes(
      Coordinates(latitude, longitude),
      DateComponents(day.year, day.month, day.day),
      parameters,
      utcOffset: utcOffsetOf(day),
    );
    return PrayerDay(
      fajr: _minute(times.fajr),
      asr: _minute(times.asr),
      maghrib: _minute(times.maghrib),
    );
  }

  /// With an offset given, the library returns the wall-clock time in a
  /// UTC-flagged value, so its hour and minute are read as they are.
  static int _minute(DateTime time) => time.hour * 60 + time.minute;
}
