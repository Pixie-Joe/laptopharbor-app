import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0096C7),
      primary: const Color(0xFF0077B6),
      secondary: const Color(0xFF00B4D8),
    ),
    scaffoldBackgroundColor: Colors.white,
    useMaterial3: true,
  );
}
