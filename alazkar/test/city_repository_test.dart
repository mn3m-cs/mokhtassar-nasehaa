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

  test('a device location keeps its own coordinates and the city name',
      () async {
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
