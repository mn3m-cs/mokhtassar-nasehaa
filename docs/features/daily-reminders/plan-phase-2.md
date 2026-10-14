# Daily Reminders, Phase 2 (prayer-relative times): Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The morning reminder fires N minutes after Fajr and the evening reminder N minutes after Asr or before Maghrib (N from 5 to 60, default 30). Prayer times are computed on the phone from the approximate device location, or from a city the reader picks. Sleep keeps its clock time.

**Architecture:** A pure Dart calculator (the `adhan` library) turns a place, a calculation method and an Asr madhab into each day's Fajr, Asr and Maghrib, as minutes after local midnight. The phase 1 planner asks it for each of the 90 days and still hands Android a list of local date + minute entries, so the Kotlin scheduling, boot and notification code is unchanged. The location is read once, on request, through `LocationManager` on the existing `reminder_channel`. A bundled city list names the place, picks the country's calculation method, and is the fallback when the location is refused.

**Tech Stack:** Flutter 3.47.2 via `fvm`, `flutter_bloc` cubits, `get_it` DI, Hive `KVStorage`, `adhan` 2.0.0+1, Kotlin `LocationManager`, Python 3 standard library for the city-list generator.

**Spec:** [design.md](design.md), [intent.md](intent.md) revision 3 (AC-008 to AC-010; AC-001 to AC-007 were verified in phase 1 and must stay true).

## Global Constraints

- Flutter commands only through `fvm` (`fvm flutter …`, `fvm dart format <files>`); the bare `dart` on PATH is a different SDK.
- Never run two Flutter commands in this checkout at once.
- One new pub dependency: `adhan: 2.0.0+1`, pinned exactly. No new Gradle dependency.
- Do not declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`. The only new permission is `ACCESS_COARSE_LOCATION`.
- Alarm window, plan length and renewal line are unchanged: 15 minutes, 90 days, «افتح التطبيق لتجديد التذكير» on the last 7 days.
- Sections: morning = title 1, evening = title 2, sleep = title 18. All reminders off by default.
- Morning options: after Fajr by N minutes only (no clock time).
- Evening options: after Asr by N minutes, or before Maghrib by N minutes (no clock time).
- Sleep options: a clock time only, default 22:00.
- Minutes N: 5 to 60 in steps of 5, default 30. Defaults on first turn-on: morning after Fajr + 30 min, evening after Asr + 30 min.
- Default calculation method by country, changeable by the reader; once the reader picks a method it stays even if the country changes:
  Egypt, Sudan, Libya → Egyptian General Authority of Survey; Saudi Arabia, Yemen → Umm al-Qura; UAE, Qatar, Kuwait → each country's own method; Pakistan, India, Bangladesh → University of Islamic Sciences, Karachi; Turkey → Diyanet; North America → ISNA; anywhere else → Muslim World League.
- Asr madhab: «الجمهور» (default) or «الحنفي».
- Times are computed in the phone's local time zone, so summer time follows automatically.
- The location is read once on request, stored on the phone, never sent anywhere and never read in the background.
- Notification title: the section's title read from the database, never typed by hand (unchanged).
- City list: open city data whose licence requires attribution, which goes on the About screen.
- UI strings added by this phase (app text, not book text): «بعد الفجر», «بعد العصر», «قبل المغرب», «بـ٥ دقائق» … «بـ٦٠ دقيقة», «اليوم: …», «الموقع», «لم يحدد الموقع», «تحديث موقعي», «اختيار مدينة», «ابحث عن مدينة», «لا توجد نتائج», «طريقة الحساب», «مذهب العصر», «الجمهور», «الحنفي», the nine method names in Task 1, «يلزم تحديد الموقع لحساب أوقات الصلاة، فاختر مدينة», «بيانات المدن» and its attribution line.
- Android only: every new UI path sits behind the existing Android-only Settings entry.
- Work on branch `feat/daily-reminders` (pull request #135); never rewrite pushed history.
- Commit messages in English, with no AI attribution of any kind.

## Review Focus

1. **Location services off, or no fix available:** the permission is granted but the phone has no location. The reader expects the city list to open, not a screen that waits forever. Task 5 tests that a missing location asks for a city; Task 6 shows progress while the phone looks; Task 7 checks it on the emulator with location turned off.
2. **The summer-time change day:** the reminder must follow the new clock (Fajr jumps by an hour in Egypt on the last Friday of April). Task 3 tests the planner across 26 April 2024 in Cairo.
3. **High latitudes in summer:** Fajr, Asr and Maghrib must still come out in order and inside the day, not crash or overflow. Task 1 tests Oslo on 21 June.
4. **Changing the city, method or madhab after reminders are on:** the alarms must be re-planned at once, with no old times left. Task 5 tests it for the madhab and the place.
5. **Arabic spelling variants in the city search:** «مكه» must find «مكة المكرمة» and «الاسكندريه» must find «الإسكندرية»; no match shows «لا توجد نتائج». Tasks 2 and 6 test it.

---

## File Structure

```
alazkar/pubspec.yaml                                    + adhan, + assets/data/
alazkar/assets/data/cities.json                         generated city list
data_pipeline/build_cities.py                           city-list generator
data_pipeline/test_build_cities.py
alazkar/lib/src/features/reminders/
  data/models/prayer_method.dart       PrayerMethod, AsrMadhab, methodForCountry()
  data/models/place.dart               Place (a city, or the device location named after one)
  data/models/reminder.dart            + ReminderKind, kinds per slot, offset
  data/repository/city_repository.dart CityRepository, normalizeArabic()
  data/repository/reminder_storage.dart + kind, offset, place, method, madhab
  data/reminder_platform.dart          + requestLocation()
  domain/prayer_times_calculator.dart  PrayerDay, PrayerTimesCalculator
  domain/reminder_planner.dart         + prayerDayOf, reminderMinute()
  presentation/controller/reminders_cubit.dart  + place, method, madhab, kind, offset
  presentation/controller/reminders_state.dart
  presentation/screens/reminders_screen.dart    prayer rows, place card
  presentation/screens/city_picker_screen.dart
alazkar/lib/src/features/about/presentation/screens/about_screen.dart  + attribution
alazkar/lib/src/core/di/dependency_injection.dart                      + CityRepository
alazkar/android/app/src/main/AndroidManifest.xml                       + ACCESS_COARSE_LOCATION
alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/
  reminders/DeviceLocation.kt          one-shot approximate location
  MainActivity.kt                      + requestLocation on reminder_channel
alazkar/test/prayer_times_calculator_test.dart
alazkar/test/city_repository_test.dart
alazkar/test/support/test_cities.dart
alazkar/test/reminder_channel_test.dart
alazkar/test/about_screen_test.dart
alazkar/test/reminder_planner_test.dart     extended
alazkar/test/reminder_storage_test.dart     extended
alazkar/test/reminders_cubit_test.dart      extended
alazkar/test/reminders_screen_test.dart     extended
alazkar/integration_test/app_journeys_test.dart  reminders journey updated
privacy.md, docs/features/daily-reminders/{design.md,intent.md}
```

All paths below are relative to the repository root `/home/mn3m/workspace/azkar-apps/alazkar_naseeha`; Flutter commands run from `alazkar/`.

---

### Task 1: Prayer times on the phone

**Files:**
- Modify: `alazkar/pubspec.yaml` (dependencies)
- Create: `alazkar/lib/src/features/reminders/data/models/prayer_method.dart`
- Create: `alazkar/lib/src/features/reminders/domain/prayer_times_calculator.dart`
- Test: `alazkar/test/prayer_times_calculator_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces:
  - `enum PrayerMethod { egyptian, ummAlQura, dubai, qatar, kuwait, karachi, turkey, northAmerica, muslimWorldLeague }` with `String label` and `CalculationMethod calculation`.
  - `PrayerMethod methodForCountry(String countryCode)`.
  - `enum AsrMadhab { majority, hanafi }` with `String label` and `Madhab adhan`.
  - `class PrayerDay { int fajr; int asr; int maghrib; }`, minutes after local midnight, `Equatable`.
  - `PrayerTimesCalculator({required double latitude, required double longitude, required PrayerMethod method, required AsrMadhab madhab, Duration Function(DateTime day)? utcOffsetOf})` with `PrayerDay dayOf(DateTime day)`. Without `utcOffsetOf` it uses the phone's offset at local noon of that day.

The reference times below are the official ones: Cairo from the Egyptian General Authority of Survey's daily statement as printed in the press (20 January 2024; 7 June 2024, summer time), Makkah from ummulqura.org.sa as recorded in the `adhan` package's own test data (5 January and 4 June 2016). The library was run against all four before this plan was written: every value is within 2 minutes.

- [ ] **Step 1: Add the dependency**

In `alazkar/pubspec.yaml`, under `dependencies:`, in alphabetical order (before `auto_size_text`):

```yaml
  adhan: 2.0.0+1
```

Run: `cd alazkar && fvm flutter pub get`
Expected: `Changed 1 dependency!` (or `Got dependencies!`), no version solving error.

- [ ] **Step 2: Write the failing test**

Create `alazkar/test/prayer_times_calculator_test.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

int hm(int hour, int minute) => hour * 60 + minute;

Matcher near(int minute) => inInclusiveRange(minute - 2, minute + 2);

PrayerTimesCalculator cairo({int hours = 2, AsrMadhab madhab = AsrMadhab.majority}) =>
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd alazkar && fvm flutter test test/prayer_times_calculator_test.dart`
Expected: FAIL to compile: `prayer_method.dart` and `prayer_times_calculator.dart` do not exist.

- [ ] **Step 4: Write the method and madhab choices**

Create `alazkar/lib/src/features/reminders/data/models/prayer_method.dart`:

```dart
import 'package:adhan/adhan.dart';

enum PrayerMethod {
  egyptian('الهيئة المصرية العامة للمساحة', CalculationMethod.egyptian),
  ummAlQura('تقويم أم القرى', CalculationMethod.umm_al_qura),
  dubai('الإمارات', CalculationMethod.dubai),
  qatar('قطر', CalculationMethod.qatar),
  kuwait('الكويت', CalculationMethod.kuwait),
  karachi('جامعة العلوم الإسلامية بكراتشي', CalculationMethod.karachi),
  turkey('رئاسة الشؤون الدينية التركية', CalculationMethod.turkey),
  northAmerica(
    'الجمعية الإسلامية لأمريكا الشمالية',
    CalculationMethod.north_america,
  ),
  muslimWorldLeague(
    'رابطة العالم الإسلامي',
    CalculationMethod.muslim_world_league,
  );

  const PrayerMethod(this.label, this.calculation);

  final String label;
  final CalculationMethod calculation;
}

/// The method a country's own authority uses, as decided with the owner.
PrayerMethod methodForCountry(String countryCode) => switch (countryCode) {
      'EG' || 'SD' || 'LY' => PrayerMethod.egyptian,
      'SA' || 'YE' => PrayerMethod.ummAlQura,
      'AE' => PrayerMethod.dubai,
      'QA' => PrayerMethod.qatar,
      'KW' => PrayerMethod.kuwait,
      'PK' || 'IN' || 'BD' => PrayerMethod.karachi,
      'TR' => PrayerMethod.turkey,
      'US' || 'CA' => PrayerMethod.northAmerica,
      _ => PrayerMethod.muslimWorldLeague,
    };

enum AsrMadhab {
  majority('الجمهور', Madhab.shafi),
  hanafi('الحنفي', Madhab.hanafi);

  const AsrMadhab(this.label, this.adhan);

  final String label;
  final Madhab adhan;
}
```

- [ ] **Step 5: Write the calculator**

Create `alazkar/lib/src/features/reminders/domain/prayer_times_calculator.dart`:

```dart
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
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd alazkar && fvm flutter test test/prayer_times_calculator_test.dart`
Expected: `All tests passed!` (6 tests).

- [ ] **Step 7: Analyze and commit**

```bash
cd alazkar && fvm dart format lib/src/features/reminders/data/models/prayer_method.dart lib/src/features/reminders/domain/prayer_times_calculator.dart test/prayer_times_calculator_test.dart && fvm flutter analyze
cd .. && git add alazkar/pubspec.yaml alazkar/pubspec.lock alazkar/lib/src/features/reminders/data/models/prayer_method.dart alazkar/lib/src/features/reminders/domain/prayer_times_calculator.dart alazkar/test/prayer_times_calculator_test.dart
git commit -m "Reminders: prayer times computed on the phone"
```

Expected: `No issues found!` before the commit.

---

### Task 2: The city list

**Files:**
- Create: `data_pipeline/build_cities.py`
- Create: `data_pipeline/test_build_cities.py`
- Create (generated): `alazkar/assets/data/cities.json`
- Modify: `alazkar/pubspec.yaml` (assets)
- Create: `alazkar/lib/src/features/reminders/data/models/place.dart`
- Create: `alazkar/lib/src/features/reminders/data/repository/city_repository.dart`
- Modify: `alazkar/lib/src/features/about/presentation/screens/about_screen.dart` (after the «المصدر» tile)
- Create: `alazkar/test/support/test_cities.dart`
- Test: `alazkar/test/city_repository_test.dart`, `alazkar/test/about_screen_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces:
  - `class Place { String name; String countryName; String countryCode; double latitude; double longitude; Place withCoordinates(double latitude, double longitude); }`, `Equatable`.
  - `const String kCitiesAsset = 'assets/data/cities.json'`.
  - `CityRepository({Future<String> Function()? read})` with `Future<List<Place>> all()`, `Future<Place> nearest(double latitude, double longitude)`, `Future<List<Place>> search(String query)`.
  - `String normalizeArabic(String text)`.
  - `const String kTestCitiesJson` (tests only): القاهرة, الإسكندرية, الرياض, مكة المكرمة.

**Data sources:** places, coordinates, population and country from GeoNames `cities15000` (CC BY 4.0, attribution required); Arabic city and country names from Wikidata labels, matched by GeoNames ID (property P1566) and ISO country code (P297) (CC0). Selection: every capital (feature code `PPLC`), plus cities of at least 150,000 people in the Arab countries, at least 700,000 in the other Muslim-majority countries, and at least 2,000,000 elsewhere. On 2026-10-14 that rule selected 704 places before dropping those with no Arabic label. The file is a JSON list of `[name, countryName, countryCode, latitude, longitude]`, one place per line, sorted by country name then city name.

- [ ] **Step 1: Write the failing generator test**

Create `data_pipeline/test_build_cities.py`:

```python
import unittest

import build_cities


def row(geonames_id, name, code, population, feature="PPL", lat="30.0", lng="31.0"):
    columns = [""] * 19
    columns[0] = geonames_id
    columns[1] = name
    columns[4] = lat
    columns[5] = lng
    columns[7] = feature
    columns[8] = code
    columns[14] = str(population)
    return columns


class SelectionTest(unittest.TestCase):
    def test_capitals_are_always_kept(self):
        self.assertTrue(build_cities.selected(row("1", "Vaduz", "LI", 5000, "PPLC")))

    def test_thresholds_follow_the_country_group(self):
        self.assertTrue(build_cities.selected(row("1", "Tanta", "EG", 150_000)))
        self.assertFalse(build_cities.selected(row("1", "Small", "EG", 149_999)))
        self.assertTrue(build_cities.selected(row("1", "Konya", "TR", 700_000)))
        self.assertFalse(build_cities.selected(row("1", "Small", "TR", 699_999)))
        self.assertTrue(build_cities.selected(row("1", "Lyon", "FR", 2_000_000)))
        self.assertFalse(build_cities.selected(row("1", "Lyon", "FR", 1_999_999)))


class EntriesTest(unittest.TestCase):
    def test_places_without_an_arabic_name_are_dropped_and_the_rest_sorted(self):
        rows = [
            row("3", "Riyadh", "SA", 1, lat="24.68772", lng="46.72185"),
            row("1", "Cairo", "EG", 1, lat="30.06263", lng="31.24967"),
            row("2", "Nowhere", "EG", 1),
            row("4", "Alexandria", "EG", 1, lat="31.20176", lng="29.91582"),
        ]
        cities = {"1": "القاهرة", "3": "الرياض", "4": "الإسكندرية"}
        countries = {"EG": "مصر", "SA": "السعودية"}

        self.assertEqual(
            build_cities.entries(rows, cities, countries),
            [
                ["الرياض", "السعودية", "SA", 24.6877, 46.7219],
                ["الإسكندرية", "مصر", "EG", 31.2018, 29.9158],
                ["القاهرة", "مصر", "EG", 30.0626, 31.2497],
            ],
        )

    def test_the_same_name_twice_in_one_country_is_kept_once(self):
        rows = [row("1", "A", "EG", 1), row("2", "B", "EG", 1)]
        cities = {"1": "القاهرة", "2": "القاهرة"}

        self.assertEqual(len(build_cities.entries(rows, cities, {"EG": "مصر"})), 1)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python3 -m unittest discover -s data_pipeline -p 'test_build_cities.py'`
Expected: `ModuleNotFoundError: No module named 'build_cities'`.

- [ ] **Step 3: Write the generator**

Create `data_pipeline/build_cities.py`:

```python
"""Builds alazkar/assets/data/cities.json, the city list the reminders use
to name the device location, choose the calculation method, and stand in
when the location is refused.

Places, coordinates and countries: GeoNames cities15000 (CC BY 4.0).
Arabic names: Wikidata labels, matched by GeoNames ID and ISO country code (CC0).

Run from the repository root: python3 data_pipeline/build_cities.py
"""

import csv
import io
import json
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

GEONAMES = "https://download.geonames.org/export/dump/cities15000.zip"
SPARQL = "https://query.wikidata.org/sparql"
AGENT = "zaad-al-dhakir-cities/1.0 (support@menemlabs.tech)"
OUT = Path(__file__).resolve().parent.parent / "alazkar" / "assets" / "data" / "cities.json"

ARAB = {
    "EG", "SA", "YE", "AE", "QA", "KW", "BH", "OM", "JO", "PS", "LB", "SY",
    "IQ", "SD", "LY", "TN", "DZ", "MA", "MR", "SO", "DJ", "KM",
}
MUSLIM = {
    "TR", "IR", "PK", "AF", "BD", "ID", "MY", "BN", "MV", "AZ", "KZ", "UZ",
    "TM", "KG", "TJ", "AL", "XK", "BA", "SN", "ML", "NE", "TD", "GM", "GN",
    "SL", "BF", "NG",
}
ARAB_MIN = 150_000
MUSLIM_MIN = 700_000
OTHER_MIN = 2_000_000


def selected(row):
    code, feature, population = row[8], row[7], int(row[14] or 0)
    if feature == "PPLC":
        return True
    if code in ARAB:
        return population >= ARAB_MIN
    if code in MUSLIM:
        return population >= MUSLIM_MIN
    return population >= OTHER_MIN


def entries(rows, city_names, country_names):
    out, seen = [], set()
    for row in rows:
        name, country = city_names.get(row[0]), country_names.get(row[8])
        if not name or not country or (name, row[8]) in seen:
            continue
        seen.add((name, row[8]))
        out.append([name, country, row[8], round(float(row[4]), 4), round(float(row[5]), 4)])
    out.sort(key=lambda entry: (entry[1], entry[0]))
    return out


def sparql(query):
    request = urllib.request.Request(
        SPARQL,
        data=urllib.parse.urlencode({"query": query}).encode(),
        headers={"Accept": "application/sparql-results+json", "User-Agent": AGENT},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.load(response)["results"]["bindings"]


def arabic_labels(prefix, prop, values):
    labels = {}
    for start in range(0, len(values), 200):
        chunk = " ".join(f'"{value}"' for value in values[start:start + 200])
        query = (
            f"SELECT ?v ?l WHERE {{ VALUES ?v {{ {chunk} }} "
            f'?i wdt:{prop} ?v . ?i rdfs:label ?l FILTER(lang(?l) = "ar") }}'
        )
        for binding in sparql(query):
            labels.setdefault(binding["v"]["value"], binding["l"]["value"])
        time.sleep(1)
    print(f"{prefix}: {len(labels)} of {len(values)} have an Arabic name")
    return labels


def main():
    with urllib.request.urlopen(GEONAMES, timeout=120) as response:
        archive = zipfile.ZipFile(io.BytesIO(response.read()))
    text = archive.read("cities15000.txt").decode("utf-8")
    rows = [r for r in csv.reader(io.StringIO(text), delimiter="\t", quoting=csv.QUOTE_NONE) if selected(r)]
    print(f"selected {len(rows)} places")
    cities = arabic_labels("cities", "P1566", sorted({r[0] for r in rows}))
    countries = arabic_labels("countries", "P297", sorted({r[8] for r in rows}))
    result = entries(rows, cities, countries)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = ",\n".join(json.dumps(entry, ensure_ascii=False) for entry in result)
    OUT.write_text(f"[\n{lines}\n]\n", encoding="utf-8")
    print(f"wrote {len(result)} places to {OUT}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the generator test to verify it passes**

Run: `python3 -m unittest discover -s data_pipeline -p 'test_build_cities.py'`
Expected: `Ran 4 tests` … `OK`.

- [ ] **Step 5: Generate the list**

Run: `python3 data_pipeline/build_cities.py`
Expected: `selected 7xx places`, two `… have an Arabic name` lines, and `wrote N places` with N between 500 and 720. Open the file and read the first 30 lines: names are Arabic, countries are Arabic, coordinates are plausible. If a country has no Arabic name its places are missing; name that in the commit message.

- [ ] **Step 6: Write the failing Dart tests**

Create `alazkar/test/support/test_cities.dart`:

```dart
const String kTestCitiesJson = '''
[
["الإسكندرية", "مصر", "EG", 31.2018, 29.9158],
["القاهرة", "مصر", "EG", 30.0626, 31.2497],
["الرياض", "السعودية", "SA", 24.6877, 46.7219],
["مكة المكرمة", "السعودية", "SA", 21.4267, 39.8261]
]
''';
```

Create `alazkar/test/city_repository_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_cities.dart';

void main() {
  final cities = CityRepository(read: () async => kTestCitiesJson);

  test('the nearest city names the device location', () async {
    final giza = await cities.nearest(30.01, 31.21);
    final jeddahRoad = await cities.nearest(21.5, 39.6);

    expect(giza.name, 'القاهرة');
    expect(giza.countryCode, 'EG');
    expect(jeddahRoad.name, 'مكة المكرمة');
  });

  test('the search ignores hamza, taa marbuta and alif maqsura spellings',
      () async {
    expect((await cities.search('مكه')).map((c) => c.name), ['مكة المكرمة']);
    expect(
      (await cities.search('الاسكندريه')).map((c) => c.name),
      ['الإسكندرية'],
    );
  });

  test('the search also matches the country name', () async {
    expect(
      (await cities.search('السعودية')).map((c) => c.name),
      ['الرياض', 'مكة المكرمة'],
    );
  });

  test('an empty search lists every city, and no match lists none', () async {
    expect(await cities.search('  '), hasLength(4));
    expect(await cities.search('لندن'), isEmpty);
  });

  test('a device location keeps its own coordinates and the city name', () async {
    final cairo = await cities.nearest(30.01, 31.21);

    final here = cairo.withCoordinates(30.01, 31.21);

    expect(here.name, 'القاهرة');
    expect(here.latitude, 30.01);
    expect(here.longitude, 31.21);
  });

  test('the bundled list is well formed', () async {
    final text = await File('assets/data/cities.json').readAsString();
    final rows = (jsonDecode(text) as List).cast<List<dynamic>>();
    final arabic = RegExp(r'^[؀-ۿ\s\-()]+$');

    expect(rows.length, inInclusiveRange(500, 720));
    for (final row in rows) {
      expect(row[0] as String, matches(arabic), reason: '$row');
      expect(row[1] as String, matches(arabic), reason: '$row');
      expect(row[2] as String, matches(RegExp(r'^[A-Z]{2}$')), reason: '$row');
      expect((row[3] as num).abs(), lessThanOrEqualTo(90), reason: '$row');
      expect((row[4] as num).abs(), lessThanOrEqualTo(180), reason: '$row');
    }
    final names = rows.map((row) => row[0]).toSet();
    expect(names, containsAll(['القاهرة', 'مكة المكرمة', 'الرياض']));
  });
}
```

If the well-formed test reports a name with characters outside the pattern (a Latin letter, a digit, a comma), fix it in the generator, never by hand-editing the JSON, and regenerate.

Create `alazkar/test/about_screen_test.dart`:

```dart
import 'package:alazkar/src/features/about/presentation/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the About screen credits the city data', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    await tester.scrollUntilVisible(find.text('بيانات المدن'), 200);

    expect(find.text('بيانات المدن'), findsOneWidget);
    expect(find.textContaining('geonames.org'), findsOneWidget);
  });
}
```

- [ ] **Step 7: Run them to verify they fail**

Run: `cd alazkar && fvm flutter test test/city_repository_test.dart test/about_screen_test.dart`
Expected: FAIL to compile (`city_repository.dart` missing); the About test fails to find «بيانات المدن».

- [ ] **Step 8: Write the place model**

Create `alazkar/lib/src/features/reminders/data/models/place.dart`:

```dart
import 'package:equatable/equatable.dart';

/// A city from the bundled list, or the device location named after the
/// nearest one.
class Place extends Equatable {
  final String name;
  final String countryName;
  final String countryCode;
  final double latitude;
  final double longitude;

  const Place({
    required this.name,
    required this.countryName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  Place withCoordinates(double latitude, double longitude) => Place(
        name: name,
        countryName: countryName,
        countryCode: countryCode,
        latitude: latitude,
        longitude: longitude,
      );

  @override
  List<Object> get props =>
      [name, countryName, countryCode, latitude, longitude];
}
```

- [ ] **Step 9: Write the city repository**

Create `alazkar/lib/src/features/reminders/data/repository/city_repository.dart`:

```dart
import 'dart:convert';
import 'dart:math';

import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:flutter/services.dart';

const String kCitiesAsset = 'assets/data/cities.json';

class CityRepository {
  final Future<String> Function() _read;
  List<Place>? _cities;

  CityRepository({Future<String> Function()? read})
      : _read = read ?? (() => rootBundle.loadString(kCitiesAsset));

  Future<List<Place>> all() async {
    return _cities ??= [
      for (final row in (jsonDecode(await _read()) as List).cast<List<dynamic>>())
        Place(
          name: row[0] as String,
          countryName: row[1] as String,
          countryCode: row[2] as String,
          latitude: (row[3] as num).toDouble(),
          longitude: (row[4] as num).toDouble(),
        ),
    ];
  }

  Future<Place> nearest(double latitude, double longitude) async {
    final cities = await all();
    return cities.reduce(
      (a, b) => _angle(a, latitude, longitude) <= _angle(b, latitude, longitude)
          ? a
          : b,
    );
  }

  Future<List<Place>> search(String query) async {
    final cities = await all();
    final wanted = normalizeArabic(query.trim());
    if (wanted.isEmpty) return cities;
    return cities
        .where(
          (city) =>
              normalizeArabic(city.name).contains(wanted) ||
              normalizeArabic(city.countryName).contains(wanted),
        )
        .toList();
  }
}

/// The great-circle angle between a place and a point, enough to compare
/// distances.
double _angle(Place place, double latitude, double longitude) {
  double radians(double degrees) => degrees * pi / 180;
  final halfLat = sin(radians(place.latitude - latitude) / 2);
  final halfLng = sin(radians(place.longitude - longitude) / 2);
  final a = halfLat * halfLat +
      cos(radians(latitude)) * cos(radians(place.latitude)) * halfLng * halfLng;
  return asin(sqrt(a));
}

/// Folds the spellings readers mix up, so «مكه» finds «مكة».
String normalizeArabic(String text) => text
    .replaceAll(RegExp('[ً-ْـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي');
```

- [ ] **Step 10: Bundle the list and credit it**

In `alazkar/pubspec.yaml`, under `flutter: assets:`, after `- assets/db/`:

```yaml
    - assets/data/
```

In `alazkar/lib/src/features/about/presentation/screens/about_screen.dart`, after the «المصدر» `ListTile` and its following `const Divider(),`, insert:

```dart
          const ListTile(
            leading: Icon(Icons.location_city_outlined),
            title: Text("بيانات المدن"),
            isThreeLine: true,
            subtitle: Text(
              "المواقع من جيونيمز (geonames.org) برخصة المشاع الإبداعي، النسبة ٤٫٠\n"
              "والأسماء العربية من ويكي بيانات",
            ),
          ),
          const Divider(),
```

- [ ] **Step 11: Run the tests to verify they pass**

Run: `cd alazkar && fvm flutter test test/city_repository_test.dart test/about_screen_test.dart`
Expected: `All tests passed!` (7 tests).

- [ ] **Step 12: Analyze and commit**

```bash
cd alazkar && fvm dart format lib/src/features/reminders/data/models/place.dart lib/src/features/reminders/data/repository/city_repository.dart lib/src/features/about/presentation/screens/about_screen.dart test/city_repository_test.dart test/about_screen_test.dart test/support/test_cities.dart && fvm flutter analyze
cd .. && git add data_pipeline/build_cities.py data_pipeline/test_build_cities.py alazkar/assets/data/cities.json alazkar/pubspec.yaml alazkar/lib/src/features/reminders/data/models/place.dart alazkar/lib/src/features/reminders/data/repository/city_repository.dart alazkar/lib/src/features/about/presentation/screens/about_screen.dart alazkar/test/city_repository_test.dart alazkar/test/about_screen_test.dart alazkar/test/support/test_cities.dart
git commit -m "Reminders: bundled city list with Arabic names, credited on About"
```

---

### Task 3: Prayer-relative settings and the 90-day plan

**Files:**
- Modify: `alazkar/lib/src/features/reminders/data/models/reminder.dart`
- Modify: `alazkar/lib/src/features/reminders/data/repository/reminder_storage.dart`
- Modify: `alazkar/lib/src/features/reminders/domain/reminder_planner.dart`
- Test: `alazkar/test/reminder_planner_test.dart`, `alazkar/test/reminder_storage_test.dart`
- Modify (keep green): `alazkar/test/reminders_cubit_test.dart`

**Interfaces:**
- Consumes: `PrayerDay`, `PrayerTimesCalculator`, `PrayerMethod`, `AsrMadhab` (Task 1); `Place` (Task 2).
- Produces:
  - `const int kDefaultSleepMinute = 22 * 60; const int kDefaultOffsetMinutes = 30; const List<int> kOffsetChoices` (5 … 60).
  - `enum ReminderKind { fixed, afterFajr, afterAsr, beforeMaghrib }` with `String label` and `bool needsPrayerTimes`.
  - `enum ReminderSlot` with `int titleId`, `List<ReminderKind> kinds`, `ReminderKind defaultKind`, `bool needsPlace`. (`defaultMinuteOfDay` is removed.)
  - `ReminderSetting({required bool enabled, ReminderKind kind = ReminderKind.fixed, int minuteOfDay = kDefaultSleepMinute, int offsetMinutes = kDefaultOffsetMinutes})` with `copyWith({enabled, kind, minuteOfDay, offsetMinutes})`.
  - `ReminderStorage`: `read`, `readAll`, `write` (now also kind and offset); `Place? readPlace()`, `Future<void> writePlace(Place)`, `PrayerMethod? readMethod()` (null = follow the country), `Future<void> writeMethod(PrayerMethod)`, `AsrMadhab readMadhab()`, `Future<void> writeMadhab(AsrMadhab)`.
  - `planReminders({settings, titles, now, PrayerDay Function(DateTime day)? prayerDayOf, days})`; a prayer-relative setting is skipped when `prayerDayOf` is null.
  - `int? reminderMinute(ReminderSetting setting, PrayerDay? day)`.

- [ ] **Step 1: Write the failing storage tests**

Replace the first test in `alazkar/test/reminder_storage_test.dart` and add the new ones, so the file reads:

```dart
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/data/repository/reminder_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_storage.dart';

void main() {
  const cairo = Place(
    name: 'القاهرة',
    countryName: 'مصر',
    countryCode: 'EG',
    latitude: 30.05,
    longitude: 31.24,
  );

  test('every reminder starts off, morning after Fajr, evening after Asr, '
      'sleep at 22:00, by 30 minutes', () {
    final settings = ReminderStorage(MemoryStorage()).readAll();

    expect(settings, {
      ReminderSlot.morning: const ReminderSetting(
        enabled: false,
        kind: ReminderKind.afterFajr,
      ),
      ReminderSlot.evening: const ReminderSetting(
        enabled: false,
        kind: ReminderKind.afterAsr,
      ),
      ReminderSlot.sleep: const ReminderSetting(enabled: false),
    });
    expect(settings[ReminderSlot.morning]!.offsetMinutes, 30);
    expect(settings[ReminderSlot.sleep]!.minuteOfDay, 22 * 60);
  });

  test('a saved reminder is read back, and the others are untouched', () async {
    final storage = ReminderStorage(MemoryStorage());
    const evening = ReminderSetting(
      enabled: true,
      kind: ReminderKind.beforeMaghrib,
      offsetMinutes: 15,
    );

    await storage.write(ReminderSlot.evening, evening);

    expect(storage.read(ReminderSlot.evening), evening);
    expect(storage.read(ReminderSlot.morning).enabled, isFalse);
  });

  test('a phase 1 clock time saved for the morning reads as after Fajr',
      () async {
    final box = MemoryStorage();
    await box.write('reminder_morning_enabled', true);
    await box.write('reminder_morning_minute', 6 * 60);

    final morning = ReminderStorage(box).read(ReminderSlot.morning);

    expect(morning.enabled, isTrue);
    expect(morning.kind, ReminderKind.afterFajr);
  });

  test('a kind the slot does not offer falls back to its default', () async {
    final storage = ReminderStorage(MemoryStorage());

    await storage.write(
      ReminderSlot.sleep,
      const ReminderSetting(enabled: true, kind: ReminderKind.afterAsr),
    );

    expect(storage.read(ReminderSlot.sleep).kind, ReminderKind.fixed);
  });

  test('the place, method and madhab are kept', () async {
    final storage = ReminderStorage(MemoryStorage());
    expect(storage.readPlace(), isNull);
    expect(storage.readMethod(), isNull);
    expect(storage.readMadhab(), AsrMadhab.majority);

    await storage.writePlace(cairo);
    await storage.writeMethod(PrayerMethod.muslimWorldLeague);
    await storage.writeMadhab(AsrMadhab.hanafi);

    expect(storage.readPlace(), cairo);
    expect(storage.readMethod(), PrayerMethod.muslimWorldLeague);
    expect(storage.readMadhab(), AsrMadhab.hanafi);
  });
}
```

- [ ] **Step 2: Write the failing planner tests**

Append to `alazkar/test/reminder_planner_test.dart`, inside `main()` after the last test, and add the two imports at the top:

```dart
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
```

```dart
  PrayerTimesCalculator cairoAt(Duration Function(DateTime day) offset) =>
      PrayerTimesCalculator(
        latitude: 30.0444,
        longitude: 31.2357,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.majority,
        utcOffsetOf: offset,
      );

  Map<ReminderSlot, ReminderSetting> morningAfterFajr(int minutes) => {
        ReminderSlot.morning: ReminderSetting(
          enabled: true,
          kind: ReminderKind.afterFajr,
          offsetMinutes: minutes,
        ),
        ReminderSlot.evening: off,
        ReminderSlot.sleep: off,
      };

  int minuteOf(PlannedReminder reminder) =>
      reminder.at.hour * 60 + reminder.at.minute;

  test('AC-008: the morning follows each day\'s Fajr in Cairo plus 30 minutes',
      () {
    final calculator = cairoAt((_) => const Duration(hours: 2));

    final planned = planReminders(
      settings: morningAfterFajr(30),
      titles: titles,
      now: DateTime(2024, 1, 20),
      prayerDayOf: calculator.dayOf,
    );

    expect(planned, hasLength(kReminderDays));
    // 05:20 in the authority's statement for 20 January 2024.
    expect(minuteOf(planned.first), inInclusiveRange(5 * 60 + 48, 5 * 60 + 52));
    for (final reminder in planned) {
      expect(
        minuteOf(reminder),
        calculator.dayOf(reminder.at).fajr + 30,
        reason: '${reminder.at}',
      );
    }
    expect(planned.map(minuteOf).toSet().length, greaterThan(10));
  });

  test('before Maghrib subtracts the minutes, in Makkah', () {
    final planned = planReminders(
      settings: {
        ReminderSlot.morning: off,
        ReminderSlot.evening: const ReminderSetting(
          enabled: true,
          kind: ReminderKind.beforeMaghrib,
          offsetMinutes: 15,
        ),
        ReminderSlot.sleep: off,
      },
      titles: titles,
      now: DateTime(2016, 6, 4),
      prayerDayOf: PrayerTimesCalculator(
        latitude: 21.427009,
        longitude: 39.828685,
        method: PrayerMethod.ummAlQura,
        madhab: AsrMadhab.majority,
        utcOffsetOf: (_) => const Duration(hours: 3),
      ).dayOf,
    );

    // Maghrib 19:01 in the Umm al-Qura calendar for 4 June 2016.
    expect(minuteOf(planned.first), inInclusiveRange(18 * 60 + 44, 18 * 60 + 48));
    expect(planned.first.titleId, 2);
  });

  test('on the summer-time change day the reminder moves with the clock', () {
    final summer = DateTime(2024, 4, 26);
    final calculator = cairoAt(
      (day) => Duration(hours: day.isBefore(summer) ? 2 : 3),
    );

    final planned = planReminders(
      settings: morningAfterFajr(30),
      titles: titles,
      now: DateTime(2024, 4, 24),
      prayerDayOf: calculator.dayOf,
    );

    final minutes = planned.take(4).map(minuteOf).toList();
    expect(minutes[1] - minutes[0], inInclusiveRange(-3, 3));
    expect(minutes[2] - minutes[1], inInclusiveRange(55, 65));
    expect(minutes[3] - minutes[2], inInclusiveRange(-3, 3));
  });

  test('without a place, prayer-relative reminders wait and sleep still fires',
      () {
    final planned = planReminders(
      settings: {
        ReminderSlot.morning: const ReminderSetting(
          enabled: true,
          kind: ReminderKind.afterFajr,
        ),
        ReminderSlot.evening: off,
        ReminderSlot.sleep: const ReminderSetting(enabled: true),
      },
      titles: titles,
      now: DateTime(2026, 10, 13, 12),
    );

    expect(planned.map((r) => r.titleId).toSet(), {18});
  });

  test('reminderMinute reads the right prayer for each kind', () {
    const day = PrayerDay(fajr: 300, asr: 900, maghrib: 1050);

    expect(
      reminderMinute(
        const ReminderSetting(enabled: true, kind: ReminderKind.afterFajr),
        day,
      ),
      330,
    );
    expect(
      reminderMinute(
        const ReminderSetting(
          enabled: true,
          kind: ReminderKind.afterAsr,
          offsetMinutes: 5,
        ),
        day,
      ),
      905,
    );
    expect(
      reminderMinute(
        const ReminderSetting(
          enabled: true,
          kind: ReminderKind.beforeMaghrib,
          offsetMinutes: 60,
        ),
        day,
      ),
      990,
    );
    expect(
      reminderMinute(const ReminderSetting(enabled: true, minuteOfDay: 1320), null),
      1320,
    );
    expect(
      reminderMinute(
        const ReminderSetting(enabled: true, kind: ReminderKind.afterFajr),
        null,
      ),
      isNull,
    );
  });
```

- [ ] **Step 3: Run them to verify they fail**

Run: `cd alazkar && fvm flutter test test/reminder_planner_test.dart test/reminder_storage_test.dart`
Expected: FAIL to compile: `ReminderKind`, `kind:`, `offsetMinutes:`, `prayerDayOf:`, `reminderMinute`, `readPlace` are not defined.

- [ ] **Step 4: Rewrite the model**

Replace the first 32 lines of `alazkar/lib/src/features/reminders/data/models/reminder.dart` (the import, `ReminderSlot` and `ReminderSetting`; `PlannedReminder` stays as it is) with:

```dart
import 'package:equatable/equatable.dart';

const int kDefaultSleepMinute = 22 * 60;
const int kDefaultOffsetMinutes = 30;
const List<int> kOffsetChoices = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];

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
```

- [ ] **Step 5: Rewrite the storage**

Replace `alazkar/lib/src/features/reminders/data/repository/reminder_storage.dart` with:

```dart
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';

class ReminderStorage {
  final KVStorage _box;

  ReminderStorage(this._box);

  static String _enabledKey(ReminderSlot slot) =>
      'reminder_${slot.name}_enabled';
  static String _minuteKey(ReminderSlot slot) => 'reminder_${slot.name}_minute';
  static String _kindKey(ReminderSlot slot) => 'reminder_${slot.name}_kind';
  static String _offsetKey(ReminderSlot slot) => 'reminder_${slot.name}_offset';

  static const String _placeName = 'reminder_place_name';
  static const String _placeCountryName = 'reminder_place_country_name';
  static const String _placeCountryCode = 'reminder_place_country_code';
  static const String _placeLatitude = 'reminder_place_latitude';
  static const String _placeLongitude = 'reminder_place_longitude';
  static const String _method = 'reminder_method';
  static const String _madhab = 'reminder_madhab';

  ReminderSetting read(ReminderSlot slot) {
    final kind =
        ReminderKind.values.asNameMap()[_box.read<String>(_kindKey(slot))];
    return ReminderSetting(
      enabled: _box.read<bool>(_enabledKey(slot)) ?? false,
      kind: slot.kinds.contains(kind) ? kind! : slot.defaultKind,
      minuteOfDay: _box.read<int>(_minuteKey(slot)) ?? kDefaultSleepMinute,
      offsetMinutes:
          _box.read<int>(_offsetKey(slot)) ?? kDefaultOffsetMinutes,
    );
  }

  Map<ReminderSlot, ReminderSetting> readAll() {
    return {for (final slot in ReminderSlot.values) slot: read(slot)};
  }

  Future<void> write(ReminderSlot slot, ReminderSetting setting) async {
    await _box.write(_enabledKey(slot), setting.enabled);
    await _box.write(_kindKey(slot), setting.kind.name);
    await _box.write(_minuteKey(slot), setting.minuteOfDay);
    await _box.write(_offsetKey(slot), setting.offsetMinutes);
  }

  Place? readPlace() {
    final name = _box.read<String>(_placeName);
    if (name == null) return null;
    return Place(
      name: name,
      countryName: _box.read<String>(_placeCountryName) ?? '',
      countryCode: _box.read<String>(_placeCountryCode) ?? '',
      latitude: _box.read<double>(_placeLatitude) ?? 0,
      longitude: _box.read<double>(_placeLongitude) ?? 0,
    );
  }

  Future<void> writePlace(Place place) async {
    await _box.write(_placeCountryName, place.countryName);
    await _box.write(_placeCountryCode, place.countryCode);
    await _box.write(_placeLatitude, place.latitude);
    await _box.write(_placeLongitude, place.longitude);
    await _box.write(_placeName, place.name);
  }

  /// The method the reader picked by hand; null follows the country.
  PrayerMethod? readMethod() =>
      PrayerMethod.values.asNameMap()[_box.read<String>(_method)];

  Future<void> writeMethod(PrayerMethod method) =>
      _box.write(_method, method.name);

  AsrMadhab readMadhab() =>
      AsrMadhab.values.asNameMap()[_box.read<String>(_madhab)] ??
      AsrMadhab.majority;

  Future<void> writeMadhab(AsrMadhab madhab) =>
      _box.write(_madhab, madhab.name);
}
```

`writePlace` writes the name last, because `readPlace` treats a missing name as no place.

- [ ] **Step 6: Rewrite the planner**

Replace `alazkar/lib/src/features/reminders/domain/reminder_planner.dart` with:

```dart
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';

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
          body: added >= days - kRenewHintDays ? kRenewHint : '',
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
```

- [ ] **Step 7: Keep the phase 1 cubit tests honest**

The morning and evening no longer plan without a place, so two cubit tests that relied on the evening's old 17:00 clock time move to the sleep reminder. In `alazkar/test/reminders_cubit_test.dart`:

In `'turning a reminder on with permission schedules it and saves it'`, replace `ReminderSlot.evening` with `ReminderSlot.sleep` (three places) and the three expectations at the end with:

```dart
    expect(platform.scheduled.last.first.at, DateTime(2026, 10, 13, 22));
    expect(platform.scheduled.last.first.title, 'أذكار النوم');
    expect(platform.scheduled.last.map((r) => r.titleId).toSet(), {18});
```

In `'changing the time replaces the old times'`, replace both `ReminderSlot.evening` with `ReminderSlot.sleep`.

In `'a permission revoked in the phone settings shows as blocked on start'`, replace the written setting with `const ReminderSetting(enabled: true)` and the slot with `ReminderSlot.sleep`.

- [ ] **Step 8: Run the reminder tests to verify they pass**

Run: `cd alazkar && fvm flutter test test/reminder_planner_test.dart test/reminder_storage_test.dart test/reminders_cubit_test.dart test/reminders_screen_test.dart`
Expected: `All tests passed!`. The screen still shows a clock tile for every slot until Task 6; its two tests use the sleep reminder and the settings link, so they should pass. Any failure here is a bug in this task.

- [ ] **Step 9: Analyze and commit**

```bash
cd alazkar && grep -rn defaultMinuteOfDay lib test integration_test; fvm dart format lib/src/features/reminders test/reminder_planner_test.dart test/reminder_storage_test.dart test/reminders_cubit_test.dart && fvm flutter analyze
cd .. && git add alazkar/lib/src/features/reminders alazkar/test/reminder_planner_test.dart alazkar/test/reminder_storage_test.dart alazkar/test/reminders_cubit_test.dart
git commit -m "Reminders: morning and evening planned from prayer times"
```

Expected: the `grep` prints nothing, then `No issues found!`.

---

### Task 4: The approximate device location on Android

**Files:**
- Modify: `alazkar/android/app/src/main/AndroidManifest.xml`
- Create: `alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/reminders/DeviceLocation.kt`
- Modify: `alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/MainActivity.kt`
- Modify: `alazkar/lib/src/features/reminders/data/reminder_platform.dart`
- Modify (keep compiling): `alazkar/test/reminders_cubit_test.dart`, `alazkar/test/reminders_screen_test.dart` (fakes)
- Test: `alazkar/test/reminder_channel_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `typedef LatLng = ({double latitude, double longitude});`
  - `ReminderPlatform.requestLocation() → Future<LatLng?>`: asks for `ACCESS_COARSE_LOCATION` if needed, then returns the location, or null when refused or unavailable.
  - Channel method `requestLocation` → `{"latitude": double, "longitude": double}` or `null`.

- [ ] **Step 1: Write the failing channel test**

Create `alazkar/test/reminder_channel_test.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/reminder_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void answer(Object? location) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      ReminderChannel.channel,
      (call) async => call.method == 'requestLocation' ? location : null,
    );
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(ReminderChannel.channel, null);
    });
  }

  test('the device location arrives as latitude and longitude', () async {
    answer({'latitude': 30.05, 'longitude': 31.24});

    expect(
      await ReminderChannel().requestLocation(),
      (latitude: 30.05, longitude: 31.24),
    );
  });

  test('a refused or missing location arrives as null', () async {
    answer(null);

    expect(await ReminderChannel().requestLocation(), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd alazkar && fvm flutter test test/reminder_channel_test.dart`
Expected: FAIL to compile: `requestLocation` is not defined.

- [ ] **Step 3: Add the Dart side**

In `alazkar/lib/src/features/reminders/data/reminder_platform.dart`, after the imports add:

```dart
typedef LatLng = ({double latitude, double longitude});
```

In `abstract class ReminderPlatform`, after `openAppSettings`, add:

```dart

  /// The approximate device location, read once. Asks for the permission
  /// first; null when it is refused or the phone has no location.
  Future<LatLng?> requestLocation();
```

In `class ReminderChannel`, after `openAppSettings`, add:

```dart

  @override
  Future<LatLng?> requestLocation() async {
    if (!_isAndroid) return null;
    final location =
        await channel.invokeMapMethod<String, double>('requestLocation');
    if (location == null) return null;
    return (
      latitude: location['latitude']!,
      longitude: location['longitude']!,
    );
  }
```

Add the same member to both test fakes so they still compile. In `alazkar/test/reminders_cubit_test.dart`, in `FakeReminderPlatform` add a field and the override:

```dart
  LatLng? location;
  int locationRequests = 0;
```

```dart
  @override
  Future<LatLng?> requestLocation() async {
    locationRequests++;
    return location;
  }
```

and give its constructor the parameter: `FakeReminderPlatform({this.allowed = true, this.grants = true, this.location});`.

In `alazkar/test/reminders_screen_test.dart`, in `_GrantingPlatform` add:

```dart
  LatLng? location;

  @override
  Future<LatLng?> requestLocation() async => location;
```

- [ ] **Step 4: Run the channel test to verify it passes**

Run: `cd alazkar && fvm flutter test test/reminder_channel_test.dart test/reminders_cubit_test.dart test/reminders_screen_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Add the permission**

In `alazkar/android/app/src/main/AndroidManifest.xml`, after the `RECEIVE_BOOT_COMPLETED` line:

```xml
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

- [ ] **Step 6: Write the one-shot location reader**

Create `alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/reminders/DeviceLocation.kt`:

```kotlin
package com.menemlabs.zaadalthakir.reminders

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal

/** The approximate location, read once when the reader asks for it. */
object DeviceLocation {
    @SuppressLint("MissingPermission")
    fun read(context: Context, onResult: (Location?) -> Unit) {
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            add(LocationManager.PASSIVE_PROVIDER)
        }.filter { it in manager.allProviders && manager.isProviderEnabled(it) }
        val last = providers
            .mapNotNull { runCatching { manager.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }
        if (last != null) {
            onResult(last)
            return
        }
        val live = providers.firstOrNull { it != LocationManager.PASSIVE_PROVIDER }
        if (live == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            onResult(null)
            return
        }
        try {
            manager.getCurrentLocation(live, CancellationSignal(), context.mainExecutor) { onResult(it) }
        } catch (e: SecurityException) {
            onResult(null)
        }
    }
}
```

A phone with no last-known location on Android 10 or older gets null, and the reader picks a city.

- [ ] **Step 7: Wire it into the channel**

In `alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/MainActivity.kt`:

Add the import after the `ReminderStore` import:

```kotlin
import com.menemlabs.zaadalthakir.reminders.DeviceLocation
```

Add a field after `pendingPermissionResult`:

```kotlin
    private var pendingLocationResult: MethodChannel.Result? = null
```

In the `reminder_channel` `when`, before `"takeLaunchTitleId"`:

```kotlin
                    "requestLocation" -> requestLocation(result)
```

After `requestNotificationPermission(...)`, add:

```kotlin
    private fun requestLocation(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            readLocation(result)
            return
        }
        pendingLocationResult = result
        requestPermissions(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), REQUEST_LOCATION)
    }

    private fun readLocation(result: MethodChannel.Result) {
        DeviceLocation.read(this) { location ->
            result.success(location?.let { mapOf("latitude" to it.latitude, "longitude" to it.longitude) })
        }
    }
```

Replace the body of `onRequestPermissionsResult` after `super.onRequestPermissionsResult(...)` with:

```kotlin
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        when (requestCode) {
            REQUEST_NOTIFICATIONS -> {
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
            }
            REQUEST_LOCATION -> {
                val result = pendingLocationResult ?: return
                pendingLocationResult = null
                if (granted) readLocation(result) else result.success(null)
            }
        }
```

In the `companion object`, after `REQUEST_NOTIFICATIONS`:

```kotlin
        private const val REQUEST_LOCATION = 4102
```

- [ ] **Step 8: Compile and check on the emulator**

Run: `cd alazkar && fvm flutter build apk --debug --flavor prod`
Expected: `✓ Built build/app/outputs/flutter-apk/app-prod-debug.apk`.

Then on the emulator (start it as in phase 1 if it is not running; never kill qemu):

```bash
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-prod-debug.apk
adb -s emulator-5554 emu geo fix 31.2357 30.0444
adb -s emulator-5554 shell dumpsys package com.menemlabs.zaadalthakir | grep -A1 ACCESS_COARSE_LOCATION
```

Expected: the permission is listed as requested, `granted=false`. The end-to-end location check happens in Task 7, after the screen exists.

- [ ] **Step 9: Analyze and commit**

```bash
cd alazkar && fvm dart format lib/src/features/reminders/data/reminder_platform.dart test/reminder_channel_test.dart test/reminders_cubit_test.dart test/reminders_screen_test.dart && fvm flutter analyze && (cd android && ./gradlew -q :app:testProdDebugUnitTest)
cd .. && git add alazkar/android/app/src/main/AndroidManifest.xml alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/reminders/DeviceLocation.kt alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/MainActivity.kt alazkar/lib/src/features/reminders/data/reminder_platform.dart alazkar/test/reminder_channel_test.dart alazkar/test/reminders_cubit_test.dart alazkar/test/reminders_screen_test.dart
git commit -m "Reminders: read the approximate device location once, on request"
```

Expected: `No issues found!` and the five Kotlin tests still pass.

---

### Task 5: The settings logic

**Files:**
- Modify: `alazkar/lib/src/features/reminders/presentation/controller/reminders_cubit.dart`
- Modify: `alazkar/lib/src/features/reminders/presentation/controller/reminders_state.dart`
- Modify: `alazkar/lib/src/features/reminders/presentation/screens/reminders_screen.dart` (one call site)
- Modify: `alazkar/lib/src/core/di/dependency_injection.dart`
- Test: `alazkar/test/reminders_cubit_test.dart`
- Modify (keep compiling): `alazkar/test/reminders_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces:
  - `enum ReminderToggle { done, notificationsRefused, locationNeeded }`.
  - `RemindersCubit(ReminderStorage storage, ReminderPlatform platform, Future<Map<int, String>> Function() loadTitles, CityRepository cities, {DateTime Function()? clock, Duration Function(DateTime day)? utcOffsetOf})`.
  - Methods: `start()`, `refreshPermission()`, `Future<ReminderToggle> setEnabled(slot, enabled)`, `Future<bool> updateLocation()`, `setPlace(Place)`, `setMethod(PrayerMethod)`, `setMadhab(AsrMadhab)`, `setKind(slot, ReminderKind)`, `setOffset(slot, int)`, `setMinuteOfDay(slot, int)`.
  - `RemindersState` adds `Place? place`, `PrayerMethod? chosenMethod`, `AsrMadhab madhab`, `PrayerDay? today`, `bool locationNeeded`, `bool locating`, and the getter `PrayerMethod? method` (the chosen one, else the country's).

- [ ] **Step 1: Write the failing tests**

In `alazkar/test/reminders_cubit_test.dart`, add imports:

```dart
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';

import 'support/test_cities.dart';
```

Replace the `cubit(...)` helper with:

```dart
  RemindersCubit cubit(
    FakeReminderPlatform platform, {
    ReminderStorage? storage,
  }) =>
      RemindersCubit(
        storage ?? ReminderStorage(MemoryStorage()),
        platform,
        () async => titles,
        CityRepository(read: () async => kTestCitiesJson),
        clock: () => DateTime(2026, 10, 13, 12),
        utcOffsetOf: (_) => const Duration(hours: 3),
      );

  const makkah = Place(
    name: 'مكة المكرمة',
    countryName: 'السعودية',
    countryCode: 'SA',
    latitude: 21.4267,
    longitude: 39.8261,
  );
  const riyadh = Place(
    name: 'الرياض',
    countryName: 'السعودية',
    countryCode: 'SA',
    latitude: 24.6877,
    longitude: 46.7219,
  );
  const cairo = Place(
    name: 'القاهرة',
    countryName: 'مصر',
    countryCode: 'EG',
    latitude: 30.0626,
    longitude: 31.2497,
  );

  int minuteOf(PlannedReminder reminder) =>
      reminder.at.hour * 60 + reminder.at.minute;

  List<PlannedReminder> forTitle(FakeReminderPlatform platform, int titleId) =>
      platform.scheduled.last.where((r) => r.titleId == titleId).toList();
```

Change the two existing expectations on the return value: `expect(ok, isTrue);` becomes `expect(ok, ReminderToggle.done);` and `expect(ok, isFalse);` becomes `expect(ok, ReminderToggle.notificationsRefused);`.

Append these tests inside `main()`:

```dart
  test('AC-009: turning the morning on reads the device location once and '
      'names the nearest city', () async {
    final platform = FakeReminderPlatform(
      location: (latitude: 30.01, longitude: 31.21),
    );
    final storage = ReminderStorage(MemoryStorage());
    final c = cubit(platform, storage: storage);
    await c.start();

    final result = await c.setEnabled(ReminderSlot.morning, true);

    expect(result, ReminderToggle.done);
    expect(c.state.place!.name, 'القاهرة');
    expect(c.state.place!.latitude, 30.01);
    expect(storage.readPlace(), c.state.place);
    expect(c.state.method, PrayerMethod.egyptian);
    final morning = forTitle(platform, 1);
    expect(morning, hasLength(90));
    final fajr = PrayerTimesCalculator(
      latitude: 30.01,
      longitude: 31.21,
      method: PrayerMethod.egyptian,
      madhab: AsrMadhab.majority,
      utcOffsetOf: (_) => const Duration(hours: 3),
    ).dayOf(morning.first.at).fajr;
    expect(minuteOf(morning.first), fajr + 30);

    await c.setEnabled(ReminderSlot.evening, true);
    expect(platform.locationRequests, 1);
  });

  test('AC-009: a refused location leaves the morning off and asks for a city',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();

    final result = await c.setEnabled(ReminderSlot.morning, true);

    expect(result, ReminderToggle.locationNeeded);
    expect(c.state.settings[ReminderSlot.morning]!.enabled, isFalse);
    expect(c.state.locationNeeded, isTrue);
    expect(platform.scheduled.last.where((r) => r.titleId == 1), isEmpty);
    expect(c.state.locating, isFalse);
  });

  test('a chosen city then lets the morning turn on', () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setEnabled(ReminderSlot.morning, true);

    await c.setPlace(makkah);
    final result = await c.setEnabled(ReminderSlot.morning, true);

    expect(result, ReminderToggle.done);
    expect(c.state.locationNeeded, isFalse);
    expect(forTitle(platform, 1), hasLength(90));
    expect(platform.locationRequests, 1);
  });

  test('AC-010: the method follows the country unless the reader picked one',
      () async {
    final c = cubit(FakeReminderPlatform());
    await c.start();

    await c.setPlace(cairo);
    expect(c.state.method, PrayerMethod.egyptian);
    await c.setPlace(riyadh);
    expect(c.state.method, PrayerMethod.ummAlQura);

    await c.setMethod(PrayerMethod.muslimWorldLeague);
    await c.setPlace(cairo);
    expect(c.state.method, PrayerMethod.muslimWorldLeague);
  });

  test('changing the madhab or the place plans the reminders again at once',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setPlace(cairo);
    await c.setEnabled(ReminderSlot.evening, true);
    final majority = minuteOf(forTitle(platform, 2).first);

    await c.setMadhab(AsrMadhab.hanafi);
    final hanafi = minuteOf(forTitle(platform, 2).first);
    expect(hanafi, greaterThan(majority + 20));

    await c.setPlace(makkah);
    expect(minuteOf(forTitle(platform, 2).first), isNot(hanafi));
    expect(forTitle(platform, 2), hasLength(90));
  });

  test('the evening can move to before Maghrib, by any 5-minute step',
      () async {
    final platform = FakeReminderPlatform();
    final c = cubit(platform);
    await c.start();
    await c.setPlace(cairo);
    await c.setEnabled(ReminderSlot.evening, true);

    await c.setKind(ReminderSlot.evening, ReminderKind.beforeMaghrib);
    await c.setOffset(ReminderSlot.evening, 10);

    final evening = forTitle(platform, 2);
    expect(minuteOf(evening.first), c.state.today!.maghrib - 10);
    expect(
      c.state.settings[ReminderSlot.evening],
      const ReminderSetting(
        enabled: true,
        kind: ReminderKind.beforeMaghrib,
        offsetMinutes: 10,
      ),
    );
  });

  test('today\'s prayer times are shown once there is a place', () async {
    final c = cubit(FakeReminderPlatform());
    await c.start();
    expect(c.state.today, isNull);

    await c.setPlace(cairo);

    expect(
      c.state.today,
      PrayerTimesCalculator(
        latitude: cairo.latitude,
        longitude: cairo.longitude,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.majority,
        utcOffsetOf: (_) => const Duration(hours: 3),
      ).dayOf(DateTime(2026, 10, 13)),
    );
  });

  test('a morning reminder saved by phase 1, with no place, asks for one',
      () async {
    final box = MemoryStorage();
    await box.write('reminder_morning_enabled', true);
    await box.write('reminder_morning_minute', 6 * 60);
    final platform = FakeReminderPlatform();
    final c = cubit(platform, storage: ReminderStorage(box));

    await c.start();

    expect(c.state.locationNeeded, isTrue);
    expect(platform.scheduled.last, isEmpty);
  });
```

In `alazkar/test/reminders_screen_test.dart`, add the `CityRepository` argument to the cubit so it compiles:

```dart
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';

import 'support/test_cities.dart';
```

```dart
    final cubit = RemindersCubit(
      ReminderStorage(MemoryStorage()),
      platform,
      () async => {1: 'أذكار الصباح', 2: 'أذكار المساء', 18: 'أذكار النوم'},
      CityRepository(read: () async => kTestCitiesJson),
    );
```

- [ ] **Step 2: Run them to verify they fail**

Run: `cd alazkar && fvm flutter test test/reminders_cubit_test.dart`
Expected: FAIL to compile: `ReminderToggle`, the fourth constructor argument, `setPlace`, `state.place` are not defined.

- [ ] **Step 3: Rewrite the state**

Replace `alazkar/lib/src/features/reminders/presentation/controller/reminders_state.dart` with:

```dart
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
      chosenMethod ?? (place == null ? null : methodForCountry(place!.countryCode));

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
```

- [ ] **Step 4: Rewrite the cubit**

Replace `alazkar/lib/src/features/reminders/presentation/controller/reminders_cubit.dart` with:

```dart
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
```

- [ ] **Step 5: Register the city list and fix the one screen call site**

In `alazkar/lib/src/core/di/dependency_injection.dart`, add the import:

```dart
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
```

After `sl.registerLazySingleton(() => ReminderStorage(sl()));` add:

```dart
  sl.registerLazySingleton(() => CityRepository());
```

and change the cubit registration to:

```dart
    () => RemindersCubit(sl(), sl(), () => loadReminderTitles(sl()), sl()),
```

In `alazkar/lib/src/features/reminders/presentation/screens/reminders_screen.dart`, `setEnabled` no longer returns a bool. In `_ReminderCard`, replace `final ok = await cubit.setEnabled(slot, value); if (!ok) showToast(kNotificationsBlocked);` with the smallest change (Task 6 rewrites this screen):

```dart
              final result = await cubit.setEnabled(slot, value);
              if (result == ReminderToggle.notificationsRefused) {
                showToast(kNotificationsBlocked);
              }
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd alazkar && fvm flutter test test/reminders_cubit_test.dart test/reminders_screen_test.dart`
Expected: `All tests passed!` (cubit: 8 old + 8 new; screen: 2).

- [ ] **Step 7: Analyze and commit**

```bash
cd alazkar && fvm dart format lib/src/features/reminders lib/src/core/di/dependency_injection.dart test/reminders_cubit_test.dart test/reminders_screen_test.dart && fvm flutter analyze && fvm flutter test
cd .. && git add alazkar/lib alazkar/test
git commit -m "Reminders: place, calculation method and madhab in the settings logic"
```

Expected: `No issues found!` and the whole suite passes.

---

### Task 6: The settings screen and the city list screen

**Files:**
- Modify: `alazkar/lib/src/features/reminders/presentation/screens/reminders_screen.dart`
- Create: `alazkar/lib/src/features/reminders/presentation/screens/city_picker_screen.dart`
- Test: `alazkar/test/reminders_screen_test.dart`

**Interfaces:**
- Consumes: Task 5's cubit and state; `kOffsetChoices`, `ReminderKind.label` (Task 3); `reminderMinute` (Task 3); `PrayerMethod.label`, `AsrMadhab.label` (Task 1); `CityRepository.search` (Task 2).
- Produces:
  - `CityPickerScreen({required CityRepository cities})`, `static Route<Place> route(CityRepository cities)`; pops with the tapped `Place`.
  - Keys used by tests and the journey: `reminder-switch-<slot>`, `reminder-offset-<slot>`, `reminder-kind-evening`, `reminder-today-<slot>`, `reminder-place`, `reminder-update-location`, `reminder-pick-city`, `reminder-method`, `reminder-madhab`, `city-search`.
  - Strings: `kLocationNeeded`, `kNoPlace`; `String offsetLabel(int minutes)`.

- [ ] **Step 1: Write the failing widget tests**

In `alazkar/test/reminders_screen_test.dart`, add imports:

```dart
import 'package:alazkar/src/features/reminders/presentation/screens/city_picker_screen.dart';
```

(`reminder.dart` is already imported.) Move the `MaterialApp` into a helper inside `main()` and use it in both existing tests (`await tester.pumpWidget(app());`):

```dart
  Widget app() => const MaterialApp(
        locale: Locale('ar', 'EG'),
        supportedLocales: [Locale('ar', 'EG')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RemindersScreen(),
      );
```

Append:

```dart
  testWidgets(
      'the morning is set in minutes after Fajr, 5 to 60, and shows '
      'today\'s time; only sleep has a clock time', (tester) async {
    platform.location = (latitude: 30.01, longitude: 31.21);
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();

    final offset = tester.widget<DropdownButton<int>>(
      find.byKey(const ValueKey('reminder-offset-morning')),
    );
    expect(offset.value, 30);
    expect(offset.items!.map((item) => item.value), kOffsetChoices);
    expect(find.text('بعد الفجر'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-today-morning')), findsOneWidget);
    expect(find.textContaining('القاهرة'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('the evening offers after Asr or before Maghrib', (tester) async {
    platform.location = (latitude: 30.01, longitude: 31.21);
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const ValueKey('reminder-switch-evening')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('قبل المغرب'));
    await tester.pumpAndSettle();

    expect(
      sl<RemindersCubit>().state.settings[ReminderSlot.evening]!.kind,
      ReminderKind.beforeMaghrib,
    );
  });

  testWidgets(
      'a refused location opens the city list, and a picked city turns '
      'the morning on', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();
    expect(find.byType(CityPickerScreen), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('city-search')), 'مكه');
    await tester.pumpAndSettle();
    expect(find.text('القاهرة'), findsNothing);
    await tester.tap(find.text('مكة المكرمة'));
    await tester.pumpAndSettle();

    expect(find.byType(CityPickerScreen), findsNothing);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('reminder-switch-morning')),
          )
          .value,
      isTrue,
    );
    expect(find.text('مكة المكرمة، السعودية'), findsOneWidget);
  });

  testWidgets(
      'leaving the city list without a choice keeps the morning off and '
      'says a location is needed', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const ValueKey('reminder-switch-morning')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('city-search')), 'لندن');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('reminder-switch-morning')),
          )
          .value,
      isFalse,
    );
    expect(find.text(kLocationNeeded), findsOneWidget);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `cd alazkar && fvm flutter test test/reminders_screen_test.dart`
Expected: FAIL to compile: `city_picker_screen.dart` and `kLocationNeeded` do not exist.

- [ ] **Step 3: Write the city list screen**

Create `alazkar/lib/src/features/reminders/presentation/screens/city_picker_screen.dart`:

```dart
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/repository/city_repository.dart';
import 'package:flutter/material.dart';

class CityPickerScreen extends StatefulWidget {
  final CityRepository cities;

  const CityPickerScreen({super.key, required this.cities});

  static Route<Place> route(CityRepository cities) {
    return MaterialPageRoute(builder: (_) => CityPickerScreen(cities: cities));
  }

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  List<Place>? _shown;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    final found = await widget.cities.search(query);
    if (mounted) setState(() => _shown = found);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار مدينة'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              key: const ValueKey('city-search'),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ابحث عن مدينة',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: shown == null
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final city = shown[index];
                          return ListTile(
                            title: Text(city.name),
                            subtitle: Text(city.countryName),
                            onTap: () => Navigator.of(context).pop(city),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rewrite the settings screen**

Replace `alazkar/lib/src/features/reminders/presentation/screens/reminders_screen.dart` with:

```dart
import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/utils/arabic_number.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/reminders/presentation/screens/city_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kNotificationsBlocked =
    'الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف';

const String kAppSettingsHint =
    'إن لم تصلك التذكيرات في وقتها، فاسمح للتطبيق بالعمل في الخلفية من إعدادات الهاتف';

const String kLocationNeeded =
    'يلزم تحديد الموقع لحساب أوقات الصلاة، فاختر مدينة';

const String kNoPlace = 'لم يحدد الموقع';

/// «بـ٥ دقائق» … «بـ١٥ دقيقة»: Arabic counts 3 to 10 take the plural.
String offsetLabel(int minutes) =>
    'بـ${ArabicNumbers.convert('$minutes')} ${minutes <= 10 ? 'دقائق' : 'دقيقة'}';

/// Opens the city list; true when the reader picked a city.
Future<bool> pickCity(BuildContext context) async {
  final cubit = context.read<RemindersCubit>();
  final place =
      await Navigator.of(context).push<Place>(CityPickerScreen.route(cubit.cities));
  if (place == null) return false;
  await cubit.setPlace(place);
  return true;
}

Future<void> toggleReminder(
  BuildContext context,
  ReminderSlot slot,
  bool enabled,
) async {
  final cubit = context.read<RemindersCubit>();
  final result = await cubit.setEnabled(slot, enabled);
  if (result == ReminderToggle.notificationsRefused) {
    showToast(kNotificationsBlocked);
  }
  if (result != ReminderToggle.locationNeeded || !context.mounted) return;
  if (await pickCity(context)) await cubit.setEnabled(slot, true);
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sl<RemindersCubit>().refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The reader may have just allowed notifications in the phone settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<RemindersCubit>().refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<RemindersCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('التذكير'), centerTitle: true),
        body: BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, state) {
            final placeShown = state.locationNeeded ||
                state.settings.entries.any(
                  (entry) => entry.value.enabled && entry.key.needsPlace,
                );
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                for (final slot in ReminderSlot.values)
                  _ReminderCard(
                    slot: slot,
                    title: state.titles[slot.titleId] ?? '',
                    setting: state.settings[slot]!,
                    today: state.today,
                  ),
                if (placeShown) _PlaceCard(state: state),
                if (state.locationNeeded)
                  const _Warning(text: kLocationNeeded),
                if (state.notificationsBlocked)
                  const _Warning(text: kNotificationsBlocked),
                ListTile(
                  key: const ValueKey('reminder-app-settings'),
                  leading: const Icon(Icons.battery_saver),
                  title: const Text(kAppSettingsHint),
                  onTap: () =>
                      context.read<RemindersCubit>().platform.openAppSettings(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String text;

  const _Warning({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderSlot slot;
  final String title;
  final ReminderSetting setting;
  final PrayerDay? today;

  const _ReminderCard({
    required this.slot,
    required this.title,
    required this.setting,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: ValueKey('reminder-switch-${slot.name}'),
            title: Text(title),
            value: setting.enabled,
            onChanged: (value) => toggleReminder(context, slot, value),
          ),
          if (setting.kind.needsPrayerTimes)
            _prayerTile(context)
          else
            _clockTile(context),
        ],
      ),
    );
  }

  Widget _prayerTile(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final minute = reminderMinute(setting, today);
    return ListTile(
      enabled: setting.enabled,
      leading: const Icon(Icons.mosque_outlined),
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (slot.kinds.length > 1)
            SegmentedButton<ReminderKind>(
              key: ValueKey('reminder-kind-${slot.name}'),
              showSelectedIcon: false,
              segments: [
                for (final kind in slot.kinds)
                  ButtonSegment(value: kind, label: Text(kind.label)),
              ],
              selected: {setting.kind},
              onSelectionChanged: setting.enabled
                  ? (kinds) => cubit.setKind(slot, kinds.first)
                  : null,
            )
          else
            Text(setting.kind.label),
          DropdownButton<int>(
            key: ValueKey('reminder-offset-${slot.name}'),
            value: setting.offsetMinutes,
            items: [
              for (final minutes in kOffsetChoices)
                DropdownMenuItem(value: minutes, child: Text(offsetLabel(minutes))),
            ],
            onChanged: setting.enabled
                ? (minutes) {
                    if (minutes != null) cubit.setOffset(slot, minutes);
                  }
                : null,
          ),
        ],
      ),
      subtitle: minute == null
          ? null
          : Text(
              'اليوم: ${MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
              )}',
              key: ValueKey('reminder-today-${slot.name}'),
            ),
    );
  }

  Widget _clockTile(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final time = TimeOfDay(
      hour: setting.minuteOfDay ~/ 60,
      minute: setting.minuteOfDay % 60,
    );
    return ListTile(
      enabled: setting.enabled,
      leading: const Icon(Icons.schedule),
      title: Text(MaterialLocalizations.of(context).formatTimeOfDay(time)),
      onTap: () async {
        // Typing is off: in Arabic the picker shows the hour in
        // Arabic-Indic digits and then rejects them as invalid.
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          initialEntryMode: TimePickerEntryMode.dialOnly,
        );
        if (picked == null) return;
        await cubit.setMinuteOfDay(slot, picked.hour * 60 + picked.minute);
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final RemindersState state;

  const _PlaceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final place = state.place;
    final method = state.method;
    return Card(
      child: Column(
        children: [
          ListTile(
            key: const ValueKey('reminder-place'),
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('الموقع'),
            subtitle: Text(
              place == null ? kNoPlace : '${place.name}، ${place.countryName}',
            ),
          ),
          if (state.locating) const LinearProgressIndicator(),
          OverflowBar(
            alignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                key: const ValueKey('reminder-update-location'),
                icon: const Icon(Icons.my_location),
                label: const Text('تحديث موقعي'),
                onPressed: state.locating
                    ? null
                    : () async {
                        if (!await cubit.updateLocation() && context.mounted) {
                          await pickCity(context);
                        }
                      },
              ),
              TextButton.icon(
                key: const ValueKey('reminder-pick-city'),
                icon: const Icon(Icons.location_city),
                label: const Text('اختيار مدينة'),
                onPressed: () => pickCity(context),
              ),
            ],
          ),
          if (method != null)
            ListTile(
              title: const Text('طريقة الحساب'),
              subtitle: DropdownButton<PrayerMethod>(
                key: const ValueKey('reminder-method'),
                isExpanded: true,
                value: method,
                items: [
                  for (final choice in PrayerMethod.values)
                    DropdownMenuItem(value: choice, child: Text(choice.label)),
                ],
                onChanged: (choice) {
                  if (choice != null) cubit.setMethod(choice);
                },
              ),
            ),
          ListTile(
            title: const Text('مذهب العصر'),
            trailing: SegmentedButton<AsrMadhab>(
              key: const ValueKey('reminder-madhab'),
              showSelectedIcon: false,
              segments: [
                for (final madhab in AsrMadhab.values)
                  ButtonSegment(value: madhab, label: Text(madhab.label)),
              ],
              selected: {state.madhab},
              onSelectionChanged: (madhabs) => cubit.setMadhab(madhabs.first),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd alazkar && fvm flutter test test/reminders_screen_test.dart`
Expected: `All tests passed!` (6 tests).

- [ ] **Step 6: Look at it**

Build and open the screen on the emulator in both themes at phone width. With morning and evening on: the morning row reads «بعد الفجر  بـ٣٠ دقيقة» with «اليوم: …» under it; the evening row wraps the two segments and the minutes without overflow stripes; the place card shows the city, the two buttons, the method and the madhab. Fix any overflow before committing.

```bash
cd alazkar && fvm flutter build apk --debug --flavor prod && adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-prod-debug.apk
```

- [ ] **Step 7: Analyze and commit**

```bash
cd alazkar && fvm dart format lib/src/features/reminders/presentation test/reminders_screen_test.dart && fvm flutter analyze && fvm flutter test
cd .. && git add alazkar/lib/src/features/reminders/presentation alazkar/test/reminders_screen_test.dart
git commit -m "Reminders: minutes after the prayer, today's time, place card and city list"
```

Expected: `No issues found!` and the whole suite passes.

---

### Task 7: Journey, privacy, device checks and the record

**Files:**
- Modify: `alazkar/integration_test/app_journeys_test.dart` (reminders part)
- Modify: `privacy.md`
- Modify: `docs/features/daily-reminders/design.md`, `docs/features/daily-reminders/intent.md`

**Interfaces:**
- Consumes: everything above.
- Produces: the verified feature, recorded.

- [ ] **Step 1: Update the journey**

In `alazkar/integration_test/app_journeys_test.dart`, add the imports:

```dart
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
```

In the mock handler's `switch`, add:

```dart
          case 'requestLocation':
            return {'latitude': 30.0444, 'longitude': 31.2357};
```

Replace the three morning expectations (from `final morning = …` to `expect(morning.first['title'], 'أذكار الصباح');`) with:

```dart
    final morning = scheduled.last.cast<Map<Object?, Object?>>();
    expect(morning.map((e) => e['titleId']).toSet(), {1});
    expect(morning.first['title'], 'أذكار الصباح');
    expect(morning.map((e) => e['minuteOfDay']).toSet().length, greaterThan(1));
    final first = morning.first;
    final fajr = PrayerTimesCalculator(
      latitude: 30.0444,
      longitude: 31.2357,
      method: PrayerMethod.egyptian,
      madhab: AsrMadhab.majority,
    ).dayOf(
      DateTime(first['year']! as int, first['month']! as int, first['day']! as int),
    ).fajr;
    expect(first['minuteOfDay'], fajr + 30);
    expect(find.textContaining('القاهرة'), findsOneWidget);
```

Run on a fresh install (the journey needs one):

```bash
adb -s emulator-5554 uninstall com.menemlabs.zaadalthakir
cd alazkar && timeout 900 fvm flutter test integration_test --flavor prod -d emulator-5554
```

Expected: `All tests passed!`.

- [ ] **Step 2: Check the real permission flows on the emulator (AC-009, Review Focus 1)**

Install a fresh debug build, set a location, and walk it by hand:

```bash
adb -s emulator-5554 uninstall com.menemlabs.zaadalthakir
cd alazkar && fvm flutter build apk --debug --flavor prod && adb -s emulator-5554 install build/app/outputs/flutter-apk/app-prod-debug.apk
adb -s emulator-5554 emu geo fix 31.2357 30.0444
```

1. Settings → «التذكير» → morning switch → allow notifications → allow approximate location. Expected: the place card shows «القاهرة، مصر», the morning row shows today's time, and `adb -s emulator-5554 shell dumpsys alarm | grep -B2 -A6 zaadalthakir` shows one pending alarm.
2. Uninstall, reinstall, turn the morning on, allow notifications, **deny** location. Expected: the city list opens. Go back without choosing: the switch is off and «يلزم تحديد الموقع لحساب أوقات الصلاة، فاختر مدينة» shows. Turn it on again, deny, search «مكه», pick «مكة المكرمة»: the switch is on and the card names Makkah with «تقويم أم القرى».
3. Location off: `adb -s emulator-5554 shell cmd location set-location-enabled false`, then «تحديث موقعي». Expected: within 30 seconds either the last known place stays or the city list opens; the progress bar never stays forever. Turn it back on with `set-location-enabled true`.
4. No network use: `grep -rn -E "http|Socket|Uri\.parse" alazkar/lib/src/features/reminders alazkar/android/app/src/main/kotlin/com/menemlabs/zaadalthakir/reminders` prints nothing.

Take one screenshot per step with the phase 1 helper `scratchpad/h.sh shot`; they go in the pull request comment, not in the repository.

- [ ] **Step 3: Measure the size (AC-007)**

```bash
cd alazkar && fvm flutter build apk --release --flavor prod --split-per-abi && ls -l build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk
```

Record the arm64 size against phase 1 (23,039,974 bytes) and main (22,711,350 bytes). Check that no exact-alarm permission crept in:

```bash
~/Android/Sdk/build-tools/*/aapt dump permissions build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk | grep -E "EXACT|LOCATION"
```

Expected: only `ACCESS_COARSE_LOCATION`.

- [ ] **Step 4: Privacy**

In `privacy.md`, replace the Arabic reminders paragraph (under `## التذكير`) with:

```markdown
إذا فعّلت تذكيرًا لأذكار الصباح أو المساء أو النوم، يضبط التطبيق إشعارًا محليًا في جهازك. يُطلب إذن الإشعارات لهذا فقط، ولا يُرسل شيء خارج الجهاز. وإيقاف التذكير يلغي إشعاراته.

تذكير الصباح والمساء مرتبط بأوقات الصلاة، فيطلب التطبيق موقعك التقريبي مرة واحدة حين تفعّل أحدهما أو تضغط «تحديث موقعي»، ليحسب أوقات الصلاة في جهازك. يُحفظ الموقع في جهازك فقط، ولا يُرسل إلى أي جهة، ولا يُقرأ في الخلفية. ويمكنك رفض الإذن واختيار مدينتك من القائمة بدلًا منه.
```

and the English paragraph (`**Reminders:** …`) with:

```markdown
**Reminders:** if you turn on a reminder for the morning, evening or sleep azkar, the app schedules a local notification on your device. The notification permission is requested only for this, and nothing leaves the device. Turning a reminder off cancels its notifications. The morning and evening reminders follow the prayer times, so the app asks for your approximate location once, when you turn one on or tap «تحديث موقعي», to compute the prayer times on your device. The location is stored on your device only, never sent anywhere, and never read in the background. You can refuse the permission and pick your city from the list instead.
```

Update the date line at the top of both language sections to the day of this step.

- [ ] **Step 5: Record the result in the spec**

In `docs/features/daily-reminders/intent.md`, set the AC-008, AC-009 and AC-010 rows of the Verification Plan to what Steps 1–3 and the unit tests showed (test names, emulator steps, size), and mark them Verified or say what is missing. In `docs/features/daily-reminders/design.md`, replace «about 500 entries» with the real count and the selection rule from Task 2, name the two data sources (GeoNames, CC BY 4.0; Wikidata, CC0), and set the Status line to say phase 2 is built.

- [ ] **Step 6: Full check and commit**

```bash
cd alazkar && fvm flutter analyze && fvm flutter test && (cd android && ./gradlew -q :app:testProdDebugUnitTest) && cd .. && python3 -m unittest discover -s data_pipeline -p 'test_*.py'
git add alazkar/integration_test/app_journeys_test.dart privacy.md docs/features/daily-reminders/design.md docs/features/daily-reminders/intent.md
git commit -m "Reminders: journey, privacy and verification for prayer-relative times"
git push
```

Expected: every command passes before the commit.

- [ ] **Step 7: Update the pull request**

Retitle pull request #135 to "Daily reminders: morning and evening after the prayer, sleep at a clock time" and add a comment with: what phase 2 adds, the size before and after, the emulator steps and screenshots from Step 2, and the deferred items from the phase 1 ledger that are still open. Use `gh pr edit 135 -R mn3m-cs/mokhtassar-nasehaa --title "…"` and `gh pr comment 135 -R mn3m-cs/mokhtassar-nasehaa --body-file <file>`. No AI attribution in either.

The pull request then waits for the owner's day of real reminders on their phone before it is merged. Before the release, the Play data-safety form must declare approximate location, collected on the device only, not shared, for app functionality; that form is the owner's to submit in Play Console, so the final report hands them the exact answers.
