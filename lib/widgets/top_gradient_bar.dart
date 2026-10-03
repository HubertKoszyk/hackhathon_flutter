import 'package:flutter/material.dart';

class TopGradientBar extends StatelessWidget {
  const TopGradientBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Pobieramy wysokość paska stanu (status bar / notch)
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      // Wysokość paska stanu + miejsce na nagłówek i zanikanie gradientu
      height: statusBarHeight + 70.0,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 0, 0, 0), // Ciemna góra pod paskiem stanu
            Color.fromARGB(190, 1, 1, 1), // Półprzezroczysty pod tekstem
            Colors.transparent, // Płynne przejście w przezroczystość
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Image.asset("assets/images/logo-white.png", height: 24.0),
          ),
        ),
      ),
    );
  }
}
