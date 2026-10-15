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
