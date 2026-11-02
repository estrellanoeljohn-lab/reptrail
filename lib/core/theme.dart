import 'package:flutter/material.dart';

const kBg = Color(0xFF0F1218);
const kCard = Color(0xFF181C26);
const kLine = Color(0xFF2A3040);
const kText = Color(0xFFF1F4FA);
const kMuted = Color(0xFFA3ACBD);
const kLime = Color(0xFFB8F24B);
const kLimeTint = Color(0xFF242E12);
const kError = Color(0xFFFF8A80);

ThemeData buildTheme() {
  final scheme = ColorScheme.dark(
    primary: kLime,
    onPrimary: kBg,
    secondary: kLime,
    onSecondary: kBg,
    surface: kCard,
    onSurface: kText,
    error: kError,
  );

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kText,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      labelStyle: const TextStyle(color: kMuted),
      helperStyle: const TextStyle(color: kMuted),
      border: border(kLine),
      enabledBorder: border(kLine),
      focusedBorder: border(kLime, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kLime,
        foregroundColor: kBg,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        side: const BorderSide(color: kLine),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kLime),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: kCard,
      selectedColor: kLimeTint,
      side: BorderSide(color: kLine),
      checkmarkColor: kLime,
      labelStyle: TextStyle(color: kText),
      shape: StadiumBorder(),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kLime),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF141822),
      indicatorColor: Color(0xFF262D3B),
    ),
  );
}