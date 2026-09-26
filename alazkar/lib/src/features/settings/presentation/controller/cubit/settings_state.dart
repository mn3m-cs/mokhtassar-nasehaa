// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool showTextInBrackets;
  final bool praiseWithVolumeKeys;
  final bool continuousReading;
  const SettingsState({
    required this.showTextInBrackets,
    required this.praiseWithVolumeKeys,
    this.continuousReading = false,
  });

  @override
  List<Object> get props => [
        showTextInBrackets,
        praiseWithVolumeKeys,
        continuousReading,
      ];

  SettingsState copyWith({
    bool? showTextInBrackets,
    bool? praiseWithVolumeKeys,
    bool? continuousReading,
  }) {
    return SettingsState(
      showTextInBrackets: showTextInBrackets ?? this.showTextInBrackets,
      praiseWithVolumeKeys: praiseWithVolumeKeys ?? this.praiseWithVolumeKeys,
      continuousReading: continuousReading ?? this.continuousReading,
    );
  }
}
