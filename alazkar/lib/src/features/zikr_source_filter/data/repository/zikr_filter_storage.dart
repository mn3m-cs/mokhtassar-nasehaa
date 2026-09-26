import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter.dart';
import 'package:alazkar/src/features/zikr_source_filter/data/models/zikr_filter_enum.dart';

class ZikrFilterStorage {
  final KVStorage box;

  ZikrFilterStorage(this.box);

  List<Filter> getAllFilters() {
    return ZikrFilter.values
        .map((e) => Filter(filter: e, isActivated: getFilterStatus(e)))
        .toList();
  }

  static const String _filterPrefixNameKey = "ZikrFilterStorage";

  static const String _enableFiltersKey =
      "${_filterPrefixNameKey}enableFilters";

  /// Filters for zikr source
  bool getEnableFiltersStatus() {
    final bool? data = box.read(_enableFiltersKey);
    return data ?? false;
  }

  /// Filters for zikr source
  Future setEnableFiltersStatus(bool activateFilters) {
    return box.write(_enableFiltersKey, activateFilters);
  }

  static const String _enableHokmFiltersKey =
      "${_filterPrefixNameKey}enableHokmFilters";

  /// Filters for zikr Hokm
  bool getEnableHokmFiltersStatus() {
    final bool? data = box.read(_enableHokmFiltersKey);
    return data ?? false;
  }

  /// Filters for zikr Hokm
  Future setEnableHokmFiltersStatus(bool activateFilters) {
    return box.write(_enableHokmFiltersKey, activateFilters);
  }

  static const String _showOnlyWithFadlKey =
      "${_filterPrefixNameKey}showOnlyWithFadl";

  /// Filters for zikr Fadl
  bool getShowOnlyWithFadlStatus() {
    final bool? data = box.read(_showOnlyWithFadlKey);
    return data ?? false;
  }

  /// Filters for zikr Fadl
  Future setShowOnlyWithFadlStatus(bool activateFilters) {
    return box.write(_showOnlyWithFadlKey, activateFilters);
  }

  bool getFilterStatus(ZikrFilter zikrFilter) {
    final bool? data = box.read(_getZikrFilterKey(zikrFilter));
    return data ?? true;
  }

  Future setFilterStatus(Filter filter) {
    return box.write(_getZikrFilterKey(filter.filter), filter.isActivated);
  }

  static String _getZikrFilterKey(ZikrFilter filter) {
    return "$_filterPrefixNameKey${filter.name}";
  }
}
