// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'zikr_source_filter_cubit.dart';

class ZikrSourceFilterState extends Equatable {
  final List<Filter> filters;
  final bool enableFilters;
  final bool enableHokmFilters;
  final bool showOnlyWithFadl;

  const ZikrSourceFilterState({
    required this.filters,
    required this.enableFilters,
    required this.enableHokmFilters,
    required this.showOnlyWithFadl,
  });

  @override
  List<Object> get props =>
      [filters, enableFilters, enableHokmFilters, showOnlyWithFadl];

  ZikrSourceFilterState copyWith({
    List<Filter>? filters,
    bool? enableFilters,
    bool? enableHokmFilters,
    bool? showOnlyWithFadl,
  }) {
    return ZikrSourceFilterState(
      filters: filters ?? this.filters,
      enableFilters: enableFilters ?? this.enableFilters,
      enableHokmFilters: enableHokmFilters ?? this.enableHokmFilters,
      showOnlyWithFadl: showOnlyWithFadl ?? this.showOnlyWithFadl,
    );
  }
}
