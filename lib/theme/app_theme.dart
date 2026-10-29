import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color warnaDasar = Colors.deepPurple;

  static ThemeData get lightTheme => _buatTema(Brightness.light);

  static ThemeData get darkTheme => _buatTema(Brightness.dark);

  static ThemeData _buatTema(Brightness brightness) {
    final skemaWarna = ColorScheme.fromSeed(
      seedColor: warnaDasar,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: skemaWarna,
    );
  }
}