import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF1D7874);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    scaffoldBackgroundColor: const Color(0xFFF5F7F6),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF5F7F6),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
