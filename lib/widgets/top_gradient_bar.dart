import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'wcag_help_dialog.dart';

class TopGradientBar extends StatelessWidget {
  const TopGradientBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isHighContrast = state.isHighContrastMode;
    final isPl = state.language == 'pl';
    final accentColor = isHighContrast ? const Color(0xFFFACC15) : const Color(0xFF38BDF8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : null,
          gradient: isHighContrast
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 0, 0, 0),
                    Color.fromARGB(220, 10, 15, 30),
                    Color.fromARGB(140, 15, 23, 42),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 0.78, 1.0],
                ),
          border: isHighContrast
              ? const Border(bottom: BorderSide(color: Color(0xFFFACC15), width: 2.0))
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              children: [
                // Logo aplikacji
                Semantics(
                  header: true,
                  label: 'NavAble Kraków',
                  child: Image.asset(
                    "assets/images/logo-white.png",
                    height: 22.0,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.accessible_forward,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                const Spacer(),

                // Kompaktowy pasek akcji dostępności (zabezpieczony przed overflow)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Tekstowa alternatywa dla mapy [Alt+M]
                        _buildTopBarButton(
                          icon: state.isMapTextAlternativeVisible ? Icons.map : Icons.article,
                          label: state.isMapTextAlternativeVisible ? (isPl ? 'Mapa' : 'Map') : (isPl ? 'Tekst' : 'Text'),
                          tooltip: state.isMapTextAlternativeVisible
                              ? (isPl ? 'Wróć do mapy graficznej [Alt+M]' : 'Return to graphic map [Alt+M]')
                              : (isPl ? 'Tekstowa alternatywa mapy (WCAG) [Alt+M]' : 'Map text alternative [Alt+M]'),
                          isActive: state.isMapTextAlternativeVisible,
                          accentColor: accentColor,
                          isHighContrast: isHighContrast,
                          onPressed: () => state.toggleMapTextAlternative(),
                        ),
                        const SizedBox(width: 5),

                        // 2. Kontrast WCAG [Alt+C]
                        _buildTopBarButton(
                          icon: isHighContrast ? Icons.contrast : Icons.brightness_medium,
                          label: null,
                          tooltip: isPl ? 'Wysoki kontrast (WCAG) [Alt+C]' : 'High contrast [Alt+C]',
                          isActive: isHighContrast,
                          accentColor: accentColor,
                          isHighContrast: isHighContrast,
                          onPressed: () => state.toggleHighContrast(),
                        ),
                        const SizedBox(width: 5),

                        // 3. Rozmiar tekstu [Alt+T]
                        _buildTopBarButton(
                          icon: Icons.format_size,
                          label: state.textScale > 1.0 ? '${(state.textScale * 100).toInt()}%' : null,
                          tooltip: isPl ? 'Zmień rozmiar tekstu [Alt+T]' : 'Cycle text size [Alt+T]',
                          isActive: state.textScale > 1.0,
                          accentColor: accentColor,
                          isHighContrast: isHighContrast,
                          onPressed: () => state.cycleTextScale(),
                        ),
                        const SizedBox(width: 5),

                        // 4. Pomoc WCAG i skróty klawiszowe [Alt+K]
                        _buildTopBarButton(
                          icon: Icons.accessibility_new,
                          label: null,
                          tooltip: isPl ? 'Dostępność cyfrowa i skróty [Alt+K / ?]' : 'Accessibility & shortcuts [Alt+K / ?]',
                          isActive: false,
                          accentColor: accentColor,
                          isHighContrast: isHighContrast,
                          onPressed: () => showWcagHelpDialog(context),
                        ),
                        const SizedBox(width: 5),

                        // 5. Przełącznik języka [Alt+L]
                        _buildTopBarButton(
                          icon: Icons.language,
                          label: state.language.toUpperCase(),
                          tooltip: isPl ? 'Zmień język (PL/EN/UK) [Alt+L]' : 'Change language [Alt+L]',
                          isActive: false,
                          accentColor: accentColor,
                          isHighContrast: isHighContrast,
                          onPressed: () => state.toggleLanguage(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    String? label,
    required String tooltip,
    required bool isActive,
    required Color accentColor,
    required bool isHighContrast,
    required VoidCallback onPressed,
  }) {
    final borderColor = isHighContrast
        ? (isActive ? const Color(0xFFFACC15) : const Color(0xFFFACC15).withValues(alpha: 0.6))
        : (isActive ? accentColor : Colors.white.withValues(alpha: 0.25));

    final bgColor = isActive
        ? (isHighContrast ? const Color(0xFFFACC15) : accentColor.withValues(alpha: 0.25))
        : (isHighContrast ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.35));

    final fgColor = isActive
        ? (isHighContrast ? Colors.black : Colors.white)
        : Colors.white;

    return Semantics(
      button: true,
      tooltip: tooltip,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: label != null ? 8 : 7, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: isHighContrast ? 2.0 : 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fgColor, size: 16),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
