import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_enum.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_list_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Quranic judgment filter includes Quran records only', () {
    const filters = [
      Filter(filter: ZikrFilter.hokmQuran, isActivated: true),
    ];

    expect(filters.validateHokm('قرآني'), isTrue);
    expect(filters.validateHokm('صحيح'), isFalse);
  });
}
