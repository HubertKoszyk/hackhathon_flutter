import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopGradientBar extends StatelessWidget {
  const TopGradientBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // Android: białe ikony (zegar, bateria, wifi)
        statusBarBrightness:
            Brightness.dark, // iOS: biały tekst i ikony na ciemnym tle
      ),
      child: Container(
        width: double.infinity,
        height: statusBarHeight + 70.0,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 0, 0, 0), // Ciemna góra pod paskiem stanu
              Color.fromARGB(190, 1, 1, 1), // Półprzezroczysty pod logo
              Colors.transparent, // Płynne przejście w przezroczystość
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Image.asset("assets/images/logo-white.png", height: 24.0),
            ),
          ),
        ),
      ),
    );
  }
}
