import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Modal z przewodnikiem po dostępności cyfrowej (WCAG 2.2 AA)
/// oraz listą wszystkich skrótów klawiszowych.
void showWcagHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const WcagHelpDialog(),
  );
}

class WcagHelpDialog extends StatelessWidget {
  const WcagHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPl = state.language == 'pl';
    final isUk = state.language == 'uk';
    final isHighContrast = state.isHighContrastMode;

    final bgColor = isHighContrast ? const Color(0xFF000000) : Colors.white;
    final cardColor = isHighContrast ? const Color(0xFF141414) : const Color(0xFFF8FAFC);
    final textColor = isHighContrast ? Colors.white : const Color(0xFF0F172A);
    final accentColor = isHighContrast ? const Color(0xFFFACC15) : const Color(0xFF0048FF);
    final borderColor = isHighContrast ? const Color(0xFFFACC15) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: isHighContrast ? 2.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nagłówek modala
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Icon(Icons.accessibility_new, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPl
                              ? 'Dostępność Cyfrowa (WCAG 2.2 AA)'
                              : (isUk ? 'Цифрова доступність (WCAG 2.2 AA)' : 'Digital Accessibility (WCAG 2.2 AA)'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isPl
                              ? 'Standardy dostępności, skróty klawiszy i czytnik ekranu'
                              : (isUk
                                  ? 'Стандарти доступності, клавіші та зчитувач екрана'
                                  : 'Accessibility standards, keyboard shortcuts & screen readers'),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: isPl ? 'Zamknij okno pomocy' : 'Close help modal',
                    child: IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: isPl ? 'Zamknij [Esc]' : 'Close [Esc]',
                    ),
                  ),
                ],
              ),
            ),

            // Treść przewijana
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Filar 1: Skróty klawiszowe
                  _buildSectionHeader(
                    icon: Icons.keyboard,
                    title: isPl ? '1. Obsługa za pomocą klawiatury' : '1. Keyboard Navigation',
                    accentColor: accentColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPl
                        ? 'Cała aplikacja może być w 100% obsługiwana za pomocą samej klawiatury bez konieczności używania myszy lub ekranu dotykowego (zgodnie z WCAG 2.1.1 i 2.4.7 Focus Visible).'
                        : 'The entire application is 100% operable via keyboard alone (WCAG 2.1.1 & 2.4.7 Focus Visible).',
                    style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow('Alt + M  /  M', isPl ? 'Przełącz tekstową alternatywę dla mapy' : 'Toggle map text alternative', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + C  /  C', isPl ? 'Przełącz tryb wysokiego kontrastu (WCAG AA/AAA)' : 'Toggle high-contrast mode', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + T  /  T', isPl ? 'Zmień rozmiar tekstu (100% / 118% / 135%)' : 'Cycle text size magnification', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + S', isPl ? 'Przejdź do wyszukiwania punktu docelowego' : 'Jump focus to search destination', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + F', isPl ? 'Otwórz filtry profilu mobilności (wózek, laska)' : 'Open mobility profile filters', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + L', isPl ? 'Przełącz język (PL / EN / UK)' : 'Toggle language', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + R', isPl ? 'Wycentruj na pozycji GPS' : 'Recenter map on current GPS', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + A', isPl ? 'Odczytaj podsumowanie na głos (Audiodeskrypcja)' : 'Read screen summary aloud', cardColor, textColor, borderColor),
                  _buildShortcutRow('Alt + I  /  I', isPl ? 'Źródła i aktualność danych (Street View, Live)' : 'Data sources & freshness (Street View, Live)', cardColor, textColor, borderColor),
                  _buildShortcutRow('Tab / Shift+Tab', isPl ? 'Przechodzenie między aktywnymi elementami' : 'Navigate between focusable elements', cardColor, textColor, borderColor),
                  _buildShortcutRow('Enter / Spacja', isPl ? 'Aktywuj zaznaczony przycisk lub pole' : 'Activate focused control', cardColor, textColor, borderColor),
                  _buildShortcutRow('Escape', isPl ? 'Zamknij modal lub wróć do mapy' : 'Close modal or return to map', cardColor, textColor, borderColor),

                  const SizedBox(height: 20),

                  // Filar 2: Tekstowa alternatywa dla mapy
                  _buildSectionHeader(
                    icon: Icons.article,
                    title: isPl ? '2. Tekstowa alternatywa dla mapy (WCAG 1.1.1)' : '2. Text Alternative for Map (WCAG 1.1.1)',
                    accentColor: accentColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPl
                        ? 'Zgodnie z kryterium sukcesu WCAG 1.1.1 (Treść nietekstowa), graficzna mapa posiada pełnowartościową alternatywę tekstową. Udostępnia ona precyzyjne opisy manewrów krok po kroku, wskaźniki nachylenia terenu, stopnie (0 schodów), listę dostępnych obiektów bez barier oraz miejsc postojowych dla osób z niepełnosprawnościami.'
                        : 'Under WCAG 1.1.1, the visual map has a complete text equivalent providing turn-by-turn steps, slope percentages, step counts, accessible places, and parking bays.',
                    style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                  ),

                  const SizedBox(height: 20),

                  // Filar 3: Kontrast WCAG 2.2 AA
                  _buildSectionHeader(
                    icon: Icons.contrast,
                    title: isPl ? '3. Odpowiedni kontrast (WCAG 1.4.3 & 1.4.11)' : '3. Contrast Compliance (WCAG 1.4.3 & 1.4.11)',
                    accentColor: accentColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPl
                        ? 'Wszystkie teksty spełniają minimalny współczynnik kontrastu 4.5:1 (a duży tekst 3:1). Ponadto aplikacja wyposażona jest w dedykowany Tryb Wysokiego Kontrastu (kontrast tekstu 21:1 na czarnym tle oraz jaskrawożółte obramowania >16:1).'
                        : 'All texts satisfy at least 4.5:1 contrast. High Contrast mode features a 21:1 ratio on true black with 16:1 safety yellow borders.',
                    style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                  ),

                  const SizedBox(height: 20),

                  // Filar 4: Obsługa czytnika ekranu
                  _buildSectionHeader(
                    icon: Icons.record_voice_over,
                    title: isPl ? '4. Obsługa czytnika ekranu (TalkBack, VoiceOver, NVDA)' : '4. Screen Reader Support',
                    accentColor: accentColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPl
                        ? 'Aplikacja posiada pełne drzewo semantyczne (Semantics), etykiety przycisków, wskazówki kontekstowe (hints) oraz dynamiczne powiadomienia na żywo (Live Announcements) odczytywane automatycznie przez czytniki mowy.'
                        : 'Full semantic tree with accessible labels, hints, and dynamic live status announcements for screen readers.',
                    style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),

            // Przyciski na dole
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: borderColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(
                        state.isHighContrastMode ? Icons.contrast : Icons.invert_colors,
                        size: 18,
                        color: accentColor,
                      ),
                      label: Text(
                        state.isHighContrastMode ? (isPl ? 'Jasny/Standard' : 'Standard') : (isPl ? 'Wysoki kontrast' : 'High contrast'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        state.toggleHighContrast();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isHighContrast ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isPl ? 'Rozumiem' : 'Got it',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutRow(
    String keys,
    String description,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: textColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              keys,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
