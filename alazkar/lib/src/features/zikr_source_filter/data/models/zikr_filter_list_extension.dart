import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/models/zikr.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_enum.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/repository/zikr_filter_storage.dart';

extension FilterListExt on List<Filter> {
  List<Zikr> getFilteredZikr(List<Zikr> azkar) {
    final filterBySource = sl<ZikrFilterStorage>().getEnableFiltersStatus();
    final filterByHokm = sl<ZikrFilterStorage>().getEnableHokmFiltersStatus();
    final showOnlyWithFadl =
        sl<ZikrFilterStorage>().getShowOnlyWithFadlStatus();

    if (!filterBySource && !filterByHokm && !showOnlyWithFadl) {
      return azkar;
    }

    return azkar.where((zikr) {
      if (filterBySource && !validateSource(zikr.source)) {
        return false;
      }
      if (filterByHokm && !validateHokm(zikr.hokm)) {
        return false;
      }

      if (showOnlyWithFadl && zikr.fadl.isEmpty) {
        return false;
      }

      return true;
    }).toList();
  }

  bool validateSource(String source) {
    bool isValid = false;

    for (final e in this) {
      if (!e.isActivated || e.filter.isForHokm) continue;

      if (e.filter == ZikrFilter.muttaqunAlayh) {
        isValid = source.contains(ZikrFilter.sahihBukhari.nameInDatabase) &&
            source.contains(ZikrFilter.sahihMuslim.nameInDatabase);
      } else {
        isValid = source.contains(e.filter.nameInDatabase);
      }

      if (isValid) break;
    }

    return isValid;
  }

  bool validateHokm(String hokm) {
    bool isValid = false;

    for (final e in this) {
      if (!e.isActivated || !e.filter.isForHokm) continue;

      isValid = hokm == e.filter.nameInDatabase;

      if (isValid) break;
    }

    return isValid;
  }
}
