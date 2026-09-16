import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_enum.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_list_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all database hokm values remain visible when every filter is active',
      () {
    final filters = ZikrFilter.values
        .map((filter) => Filter(filter: filter, isActivated: true))
        .toList();

    const databaseHokmValues = [
      'صحيح',
      'حسن',
      'ضعيف',
      'موضوع',
      'أثر',
      'قرآني',
      'موقوف',
      '',
    ];

    for (final hokm in databaseHokmValues) {
      expect(filters.validateHokm(hokm), isTrue, reason: 'الحكم: $hokm');
    }
  });
}
