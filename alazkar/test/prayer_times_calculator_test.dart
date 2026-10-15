import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

int hm(int hour, int minute) => hour * 60 + minute;

Matcher near(int minute) => inInclusiveRange(minute - 2, minute + 2);

PrayerTimesCalculator cairo(
        {int hours = 2, AsrMadhab madhab = AsrMadhab.majority}) =>
    PrayerTimesCalculator(
      latitude: 30.0444,
      longitude: 31.2357,
      method: PrayerMethod.egyptian,
      madhab: madhab,
      utcOffsetOf: (_) => Duration(hours: hours),
    );

PrayerTimesCalculator makkah() => PrayerTimesCalculator(
      latitude: 21.427009,
      longitude: 39.828685,
      method: PrayerMethod.ummAlQura,
      madhab: AsrMadhab.majority,
      utcOffsetOf: (_) => const Duration(hours: 3),
    );

void main() {
  test('Cairo in winter matches the Egyptian survey authority', () {
    final day = cairo().dayOf(DateTime(2024, 1, 20));

    expect(day.fajr, near(hm(5, 20)));
    expect(day.asr, near(hm(15, 0)));
    expect(day.maghrib, near(hm(17, 20)));
  });

  test('Cairo in summer time matches the Egyptian survey authority', () {
    final day = cairo(hours: 3).dayOf(DateTime(2024, 6, 7));

    expect(day.fajr, near(hm(4, 9)));
    expect(day.asr, near(hm(16, 30)));
    expect(day.maghrib, near(hm(19, 54)));
  });

  test('Makkah matches the Umm al-Qura calendar in winter and summer', () {
    final winter = makkah().dayOf(DateTime(2016, 1, 5));
    final summer = makkah().dayOf(DateTime(2016, 6, 4));

    expect(winter.fajr, near(hm(5, 39)));
    expect(winter.asr, near(hm(15, 32)));
    expect(winter.maghrib, near(hm(17, 53)));
    expect(summer.fajr, near(hm(4, 11)));
    expect(summer.asr, near(hm(15, 37)));
    expect(summer.maghrib, near(hm(19, 1)));
  });

  test('the Hanafi Asr comes well after the majority Asr', () {
    final date = DateTime(2024, 1, 20);

    final majority = cairo().dayOf(date).asr;
    final hanafi = cairo(madhab: AsrMadhab.hanafi).dayOf(date).asr;

    expect(hanafi, greaterThan(majority + 20));
  });

  test('a summer day in Oslo keeps the three times in order inside the day',
      () {
    final day = PrayerTimesCalculator(
      latitude: 59.9139,
      longitude: 10.7522,
      method: PrayerMethod.muslimWorldLeague,
      madhab: AsrMadhab.majority,
      utcOffsetOf: (_) => const Duration(hours: 2),
    ).dayOf(DateTime(2026, 6, 21));

    expect(day.fajr, greaterThanOrEqualTo(0));
    expect(day.fajr, lessThan(day.asr));
    expect(day.asr, lessThan(day.maghrib));
    expect(day.maghrib, lessThan(24 * 60));
  });

  test('the calculation method follows the country', () {
    expect(methodForCountry('EG'), PrayerMethod.egyptian);
    expect(methodForCountry('SD'), PrayerMethod.egyptian);
    expect(methodForCountry('LY'), PrayerMethod.egyptian);
    expect(methodForCountry('SA'), PrayerMethod.ummAlQura);
    expect(methodForCountry('YE'), PrayerMethod.ummAlQura);
    expect(methodForCountry('AE'), PrayerMethod.dubai);
    expect(methodForCountry('QA'), PrayerMethod.qatar);
    expect(methodForCountry('KW'), PrayerMethod.kuwait);
    expect(methodForCountry('PK'), PrayerMethod.karachi);
    expect(methodForCountry('IN'), PrayerMethod.karachi);
    expect(methodForCountry('BD'), PrayerMethod.karachi);
    expect(methodForCountry('TR'), PrayerMethod.turkey);
    expect(methodForCountry('US'), PrayerMethod.northAmerica);
    expect(methodForCountry('CA'), PrayerMethod.northAmerica);
    expect(methodForCountry('FR'), PrayerMethod.muslimWorldLeague);
    expect(methodForCountry('ID'), PrayerMethod.muslimWorldLeague);
  });
}
