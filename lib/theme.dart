import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Pour changer la direction graphique, commence par ces trois couleurs.
const graphite = Color(0xFF191A1C);
const fond = Color(0xFFECEDEF);
const vermillon = Color(0xFFCB3E2D);

ThemeData creerTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: fond,
  colorScheme: ColorScheme.fromSeed(
    seedColor: vermillon,
    primary: vermillon,
    surface: Colors.white,
    onSurface: graphite,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, height: 1.45, color: graphite),
    bodyLarge: TextStyle(fontSize: 17, height: 1.45, color: graphite),
    titleLarge: TextStyle(
      fontSize: 23,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: graphite,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFDDDEE0)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCDDDF)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: graphite,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? Colors.white : graphite,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: vermillon,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
