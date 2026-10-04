import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'filters_modal.dart';
import 'wcag_help_dialog.dart';

/// Globalny menedżer obsługi klawiatury (WCAG 2.1.1, 2.1.2, 2.4.7 Focus Visible)
/// oraz powiadomień dla czytników ekranu (WCAG 4.1.3 Live Region).
class WcagKeyboardManager extends StatelessWidget {
  final Widget child;

  const WcagKeyboardManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final isAlt = HardwareKeyboard.instance.isAltPressed;
        final isControl = HardwareKeyboard.instance.isControlPressed;

        // Czy focus znajduje się wewnątrz aktywnego pola tekstowego
        final currentFocus = FocusManager.instance.primaryFocus;
        final isTypingInField = currentFocus?.context?.widget is EditableText;

        // Escape: zamknij modal, wyłącz alternatywę tekstową lub zdejmij fokus
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (state.activeAudit != null) {
            state.closeAudit();
            return KeyEventResult.handled;
          }
          if (state.isMapTextAlternativeVisible) {
            state.setMapTextAlternative(false);
            return KeyEventResult.handled;
          }
          if (state.selectedParking != null) {
            state.selectParking(null);
            return KeyEventResult.handled;
          }
          if (state.selectedAccessiblePlace != null) {
            state.selectAccessiblePlace(null);
            return KeyEventResult.handled;
          }
          if (isTypingInField) {
            currentFocus?.unfocus();
            return KeyEventResult.handled;
          }
        }

        // F1 lub Pytajnik (?) lub Alt + K: Pomoc WCAG i skróty klawiszowe
        if (event.logicalKey == LogicalKeyboardKey.f1 ||
            (isAlt && event.logicalKey == LogicalKeyboardKey.keyK) ||
            (!isTypingInField && event.character == '?')) {
          showWcagHelpDialog(context);
          return KeyEventResult.handled;
        }

        // Alt + M lub M (gdy nie piszemy w polu tekstowym): Przełącz tekstową alternatywę dla mapy
        if ((isAlt && event.logicalKey == LogicalKeyboardKey.keyM) ||
            (!isTypingInField && !isControl && event.logicalKey == LogicalKeyboardKey.keyM)) {
          state.toggleMapTextAlternative();
          return KeyEventResult.handled;
        }

        // Alt + C lub C (gdy nie piszemy): Przełącz wysoki kontrast (WCAG 2.2)
        if ((isAlt && event.logicalKey == LogicalKeyboardKey.keyC) ||
            (!isTypingInField && !isControl && event.logicalKey == LogicalKeyboardKey.keyC)) {
          state.toggleHighContrast();
          return KeyEventResult.handled;
        }

        // Alt + T lub T (gdy nie piszemy): Zmień rozmiar tekstu
        if ((isAlt && event.logicalKey == LogicalKeyboardKey.keyT) ||
            (!isTypingInField && !isControl && event.logicalKey == LogicalKeyboardKey.keyT)) {
          state.cycleTextScale();
          return KeyEventResult.handled;
        }

        // Alt + A lub A (gdy nie piszemy): Odczytaj podsumowanie na głos (Audiodeskrypcja)
        if ((isAlt && event.logicalKey == LogicalKeyboardKey.keyA) ||
            (!isTypingInField && !isControl && event.logicalKey == LogicalKeyboardKey.keyA)) {
          state.readCurrentSummaryAloud();
          return KeyEventResult.handled;
        }

        // Alt + F: Otwórz filtry profilu mobilności
        if (isAlt && event.logicalKey == LogicalKeyboardKey.keyF) {
          showAccessibilityFiltersModal(context);
          return KeyEventResult.handled;
        }

        // Alt + L: Przełącz język
        if (isAlt && event.logicalKey == LogicalKeyboardKey.keyL) {
          state.toggleLanguage();
          return KeyEventResult.handled;
        }

        // Alt + R: Wycentruj GPS
        if (isAlt && event.logicalKey == LogicalKeyboardKey.keyR) {
          state.useCurrentLocationAsStart();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          child,

          // Pasek powiadomień dostępności na żywo (WCAG 4.1.3 Live Region)
          if (state.accessibilityAnnouncement != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Semantics(
                liveRegion: true,
                focused: true,
                label: 'Komunikat dostępności: ${state.accessibilityAnnouncement}',
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: state.isHighContrastMode
                      ? const Color(0xFFFACC15)
                      : const Color(0xFF0F172A),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: state.isHighContrastMode
                            ? Colors.black
                            : const Color(0xFF38BDF8),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.accessibility,
                          color: state.isHighContrastMode
                              ? Colors.black
                              : const Color(0xFF38BDF8),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.accessibilityAnnouncement!,
                            style: TextStyle(
                              color: state.isHighContrastMode
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
