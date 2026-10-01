part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final Color color;
  final Brightness brightness;
  final bool useMaterial3;
  final double fontSize;
  final ZikrFont zikrFont;
  const ThemeState({
    required this.color,
    required this.brightness,
    required this.useMaterial3,
    required this.fontSize,
    required this.zikrFont,
  });

  @override
  List<Object> get props =>
      [color, brightness, useMaterial3, fontSize, zikrFont];

  ThemeState copyWith({
    Color? color,
    Brightness? brightness,
    bool? useMaterial3,
    double? fontSize,
    ZikrFont? zikrFont,
  }) {
    return ThemeState(
      color: color ?? this.color,
      brightness: brightness ?? this.brightness,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      fontSize: fontSize ?? this.fontSize,
      zikrFont: zikrFont ?? this.zikrFont,
    );
  }
}
