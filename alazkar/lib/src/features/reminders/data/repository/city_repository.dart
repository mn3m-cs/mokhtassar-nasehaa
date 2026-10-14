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
      for (final row
          in (jsonDecode(await _read()) as List).cast<List<dynamic>>())
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
