import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/features/theme/presentation/controller/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';

/// The app's [ThemeData] for [state]. `MaterialApp` and the pictures the tests
/// draw both build their theme here, so the two cannot drift apart.
ThemeData buildAppTheme(ThemeState state) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: state.color,
      brightness: state.brightness,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: "Cairo",
    fontFamilyFallback: kGlyphFallback,
    useMaterial3: state.useMaterial3,
  );
}
