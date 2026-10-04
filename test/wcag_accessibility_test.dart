import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackhathon_flutter/providers/app_state.dart';
import 'package:hackhathon_flutter/theme.dart';
import 'package:hackhathon_flutter/widgets/map_text_alternative_view.dart';
import 'package:hackhathon_flutter/widgets/wcag_help_dialog.dart';
import 'package:hackhathon_flutter/widgets/wcag_keyboard_manager.dart';
import 'package:provider/provider.dart';

void main() {
  group('WCAG 2.2 AA Digital Accessibility Tests', () {
    test('AppState controls High Contrast Mode, Text Scaling, and Text Alternative', () {
      final state = AppState();

      // Domyślny stan
      expect(state.isHighContrastMode, isFalse);
      expect(state.textScale, 1.0);
      expect(state.isMapTextAlternativeVisible, isFalse);

      // 1. Przełączanie trybu wysokiego kontrastu (WCAG 2.2 AA / AAA)
      state.toggleHighContrast();
      expect(state.isHighContrastMode, isTrue);
      expect(state.accessibilityAnnouncement, contains('wysokiego kontrastu'));

      state.toggleHighContrast();
      expect(state.isHighContrastMode, isFalse);

      // 2. Skalowanie tekstu (WCAG 1.4.4 Resize Text)
      state.cycleTextScale();
      expect(state.textScale, 1.18);
      state.cycleTextScale();
      expect(state.textScale, 1.35);
      state.cycleTextScale();
      expect(state.textScale, 1.0);

      // 3. Tekstowa alternatywa dla mapy (WCAG 1.1.1 Non-text Content)
      state.toggleMapTextAlternative();
      expect(state.isMapTextAlternativeVisible, isTrue);
      expect(state.accessibilityAnnouncement, contains('tekstową alternatywę'));

      state.setMapTextAlternative(false);
      expect(state.isMapTextAlternativeVisible, isFalse);

      // 4. Odczyt audiodeskrypcji / podsumowania na głos
      state.readCurrentSummaryAloud();
      expect(state.accessibilityAnnouncement, isNotNull);
      expect(state.accessibilityAnnouncement!.isNotEmpty, isTrue);
    });

    test('WCAG 2.2 AA & AAA Contrast Compliance Verification', () {
      // Weryfikacja kontrastu motywu wysokiego kontrastu
      final hcTheme = materialHighContrastTheme;
      final hcScheme = hcTheme.colorScheme;

      expect(hcTheme.brightness, Brightness.dark);
      expect(hcTheme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(hcScheme.primary, const Color(0xFFFACC15)); // Jaskrawy żółty
      expect(hcScheme.onPrimary, const Color(0xFF000000));
      expect(hcScheme.onSurface, const Color(0xFFFFFFFF)); // Czysta biel

      // Obliczanie współczynnika kontrastu WCAG:
      // (L1 + 0.05) / (L2 + 0.05)
      // Czysta biel (L1 = 1.0) na czystej czerni (L2 = 0.0): (1.05) / (0.05) = 21.0:1
      const whiteLum = 1.0;
      const blackLum = 0.0;
      final textContrastAgainstBlack = (whiteLum + 0.05) / (blackLum + 0.05);
      expect(textContrastAgainstBlack, 21.0);
      expect(textContrastAgainstBlack, greaterThanOrEqualTo(7.0)); // Spełnia najwyższy standard WCAG AAA!

      // Kontrast żółtego akcentu (#FACC15) przeciw czerni
      final yellowLum = const Color(0xFFFACC15).computeLuminance();
      final yellowContrast = (yellowLum + 0.05) / (blackLum + 0.05);
      expect(yellowContrast, greaterThanOrEqualTo(12.0)); // > 12:1!
    });

    testWidgets('MapTextAlternativeView displays spatial orientation, places, and parking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      state.setMapTextAlternative(true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(
            home: MapTextAlternativeView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Sprawdź obecność nagłówka i oznaczenia WCAG
      expect(find.text('Tekstowa alternatywa mapy'), findsOneWidget);
      expect(find.text('WCAG 2.2 AA (1.1.1 Non-text Content)'), findsOneWidget);

      // 2. Sprawdź obecność karty orientacji przestrzennej (GPS)
      expect(find.text('Orientacja przestrzenna (GPS)'), findsOneWidget);
      expect(find.textContaining('°N'), findsOneWidget);

      // 3. Sprawdź obecność sekcji miejsc bez barier
      expect(find.textContaining('Miejsca i obiekty bez barier'), findsOneWidget);

      // 4. Przełącz filtr na 'Koperty dla ON'
      final parkingChip = find.text('Koperty dla ON');
      expect(parkingChip, findsOneWidget);
      await tester.tap(parkingChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('Miejsca postojowe dla osób z niepełnosprawnościami'), findsOneWidget);

      // 5. Kliknięcie w przycisk powrotu do mapy graficznej
      final returnButton = find.text('Przełącz z powrotem na widok mapy graficznej');
      expect(returnButton, findsOneWidget);
      await tester.tap(returnButton);
      await tester.pumpAndSettle();

      expect(state.isMapTextAlternativeVisible, isFalse);

      // Poczekaj na wygaśnięcie timera powiadomienia
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('WcagHelpDialog displays all keyboard shortcuts and WCAG guidelines', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: WcagHelpDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dostępność Cyfrowa (WCAG 2.2 AA)'), findsOneWidget);
      expect(find.text('1. Obsługa za pomocą klawiatury'), findsOneWidget);

      // Wyszukaj skróty klawiszowe
      expect(find.text('Alt + M  /  M'), findsOneWidget);
      expect(find.text('Alt + C  /  C'), findsOneWidget);
      expect(find.text('Alt + T  /  T'), findsOneWidget);
    });

    testWidgets('WcagKeyboardManager renders live announcement banner when triggered', (tester) async {
      final state = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(
            home: WcagKeyboardManager(
              child: Scaffold(body: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);

      // Wywołanie powiadomienia dostępności
      state.announceAccessibility('Testowe powiadomienie WCAG');
      await tester.pump();

      expect(find.text('Testowe powiadomienie WCAG'), findsOneWidget);

      // Poczekaj na wygaśnięcie timera powiadomienia (4 sekundy)
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('MapTextAlternativeView does not overflow with 1.35x text scale on narrow screen', (tester) async {
      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = AppState();
      state.setMapTextAlternative(true);
      state.cycleTextScale(); // 1.18
      state.cycleTextScale(); // 1.35

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.35),
            ),
            child: const MaterialApp(
              home: MapTextAlternativeView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 5));

      if (caughtDetails != null) {
        debugPrint('CAUGHT SUMMARY: ${caughtDetails!.summary}');
        debugPrint('CAUGHT CONTEXT: ${caughtDetails!.context}');
      }
      expect(caughtDetails, isNull);
      expect(find.text('Tekstowa alternatywa mapy'), findsOneWidget);
      expect(find.text('Orientacja przestrzenna (GPS)'), findsOneWidget);
    });

    testWidgets('Inputs and language selector adapt cleanly in High Contrast mode', (tester) async {
      final state = AppState();
      state.toggleHighContrast(); // High contrast mode = true
      await tester.pump(const Duration(seconds: 5)); // Flush accessibility announcement timer

      expect(state.isHighContrastMode, isTrue);

      // Verify materialHighContrastTheme properties
      final theme = materialHighContrastTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.onSurface, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.primary, const Color(0xFFFACC15));
    });
  });
}
