import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorSchemeSeed: const Color(0xFF2196F3),
      useMaterial3: true,
      brightness: Brightness.light,
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorSchemeSeed: const Color(0xFF2196F3),
      useMaterial3: true,
      brightness: Brightness.dark,
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
    );
  }
}
