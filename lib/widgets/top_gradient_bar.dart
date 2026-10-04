import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'app_tutorial_modal.dart';

class TopGradientBar extends StatelessWidget {
  const TopGradientBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';

    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lewa strona: Placeholder dla symetrii lub profil mobilności
              const SizedBox(width: 40),

              // Środek: Oficjalne logo NavAble
              Image.asset(
                "assets/images/logo-white.png",
                height: 24.0,
              ),

              // Prawa strona: Przycisk samouczka / przewodnika
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => AppTutorialModal.show(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPL ? 'Pomoc' : 'Guide',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
