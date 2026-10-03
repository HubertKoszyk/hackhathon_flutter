import 'package:flutter/material.dart';

var kColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0048FF),
  onPrimary: Color.fromARGB(255, 255, 255, 255),
  secondary: Color(0xFF336DFF),
  onSecondary: Color.fromARGB(255, 255, 254, 254),
  tertiary: Color(0xFF003ACC),
  onTertiary: Color.fromARGB(255, 255, 255, 255),
  error: Color(0xFFEC1F00),
  onError: Color.fromARGB(255, 255, 255, 255),
  inverseSurface: Color(0xFF37DD00),
  surface: Color.fromARGB(255, 255, 255, 255),
  onSurface: Color.fromARGB(255, 25, 25, 25),
);

var kColorGrayScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFF5F5F5),
  onPrimary: Color.fromARGB(255, 0, 0, 0),
  secondary: Color(0xFFE7E7E7),
  onSecondary: Color.fromARGB(255, 0, 0, 0),
  tertiary: Color(0xFFC7C7C7),
  onTertiary: Color.fromARGB(255, 0, 0, 0),
  error: Color.fromARGB(255, 255, 234, 234),
  onError: Color.fromARGB(255, 255, 255, 255),
  inverseSurface: Color.fromRGBO(212, 255, 233, 1),
  surface: Color.fromARGB(255, 248, 248, 248),
  onSurface: Color.fromARGB(255, 0, 0, 0),
);

ThemeData materialLightTheme = ThemeData(
  //Set default colors
  colorScheme: kColorScheme,
  unselectedWidgetColor: const Color.fromARGB(255, 0, 0, 0),
  scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
  //Set text styling
  fontFamily: 'InclusiveSans',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 32.0,
      height: 40.0,
      fontWeight: FontWeight.w700,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 28.0,
      height: 32.0,
      fontWeight: FontWeight.w700,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    displaySmall: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 20.0,
      height: 24.0,
      fontWeight: FontWeight.w700,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    bodyLarge: TextStyle(
      fontFamily: 'InclusiveSans',
      fontSize: 20.0,
      height: 24.0,
      fontWeight: FontWeight.w500,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    bodyMedium: TextStyle(
      fontFamily: 'InclusiveSans',
      fontSize: 16.0,
      height: 20.0,
      fontWeight: FontWeight.w500,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    bodySmall: TextStyle(
      fontFamily: 'InclusiveSans',
      fontSize: 14.0,
      height: 16.0,
      fontWeight: FontWeight.w500,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    labelMedium: TextStyle(
      fontFamily: 'InclusiveSans',
      fontSize: 12.0,
      height: 12.0,
      fontWeight: FontWeight.w500,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
  ),
  //Set widgets default styling
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w700,
      fontSize: 20.0,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kColorScheme.primary,
      foregroundColor: kColorScheme.onPrimary,
      disabledBackgroundColor: kColorGrayScheme.tertiary,
      disabledForegroundColor: kColorGrayScheme.onTertiary,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      textStyle: TextStyle(
        fontFamily: 'InclusiveSans',
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
        color: kColorScheme.onPrimary,
      ),
      side: BorderSide(color: kColorScheme.tertiary, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'InclusiveSans',
          fontSize: 20.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      foregroundColor: const WidgetStatePropertyAll(
        Color.fromARGB(255, 0, 0, 0),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
  ),
  cardTheme: const CardThemeData(shadowColor: Colors.transparent),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    titleTextStyle: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
      color: Color.fromARGB(255, 25, 25, 25),
    ),
  ),
  useMaterial3: true,
);
