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
