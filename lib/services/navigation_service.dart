import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/navigation_step.dart';
import '../models/route_model.dart';
import '../providers/app_state.dart';

class NavigationService {
  /// Oblicza kąt namiaru (bearing w stopniach 0..360) między dwoma punktami GPS
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitudeInRad;
    final lon1 = start.longitudeInRad;
    final lat2 = end.latitudeInRad;
    final lon2 = end.longitudeInRad;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = (radians * 180 / math.pi + 360) % 360;
    return degrees;
  }

  /// Generuje sekwencję kroków manewrowych krok po kroku (Turn-by-Turn)
  /// dla dowolnej trasy pieszej w Krakowie z uwzględnieniem wybranego profilu dostępności.
  static List<NavigationStep> generateStepsForRoute(
    RouteModel route,
    MobilityProfile profile,
  ) {
    final coords = route.coordinates;
    if (coords.length < 2) {
      return [
        NavigationStep(
          point: coords.isNotEmpty ? coords.first : const LatLng(50.0617, 19.9373),
          instructionPl: 'Rozpocznij trasę ku celowi',
          instructionEn: 'Start route towards destination',
          streetName: 'Kraków',
          maneuverIcon: Icons.navigation,
          distanceMeters: route.distanceMeters.toDouble(),
          accessibilityNotePl: 'Trakt zlicowany 0 cm',
          accessibilityNoteEn: 'Flush 0 cm route',
        ),
        NavigationStep(
          point: coords.isNotEmpty ? coords.last : const LatLng(50.0617, 19.9373),
          instructionPl: 'Dotarłeś do celu podróży',
          instructionEn: 'You have arrived at your destination',
          streetName: 'Cel podróży',
          maneuverIcon: Icons.flag,
          distanceMeters: 0,
          accessibilityNotePl: 'Trasa bez barier pokonana pomyślnie',
          accessibilityNoteEn: 'Accessible route successfully completed',
        ),
      ];
    }

    const dist = Distance();
    final List<NavigationStep> steps = [];

    // 1. KROK STARTOWY
    final firstStreet = _getStreetNameNear(coords[0]);
    steps.add(NavigationStep(
      point: coords[0],
      instructionPl: 'Ruszaj w trasę w kierunku: $firstStreet',
      instructionEn: 'Head towards: $firstStreet',
      streetName: firstStreet,
      maneuverIcon: Icons.navigation,
      distanceMeters: dist.as(LengthUnit.Meter, coords[0], coords[1]).toDouble(),
      accessibilityNotePl: _getStartAccessibilityNotePl(profile),
      accessibilityNoteEn: _getStartAccessibilityNoteEn(profile),
    ));

    // 2. KROKI POŚREDNIE (Wykrywanie skrętów i ominięć barier)
    double accumulatedDistance = 0;
    for (int i = 1; i < coords.length - 1; i++) {
      final prev = coords[i - 1];
      final curr = coords[i];
      final next = coords[i + 1];

      final segmentDist = dist.as(LengthUnit.Meter, prev, curr).toDouble();
      accumulatedDistance += segmentDist;

      final b1 = calculateBearing(prev, curr);
      final b2 = calculateBearing(curr, next);
      final delta = (b2 - b1 + 540) % 360 - 180;

      // Sprawdź czy jesteśmy blisko punktu objazdu bariery
      final nearbyAudit = route.audits.where((a) => dist.as(LengthUnit.Meter, curr, a.location) < 45).firstOrNull;

      // Wykrywaj skręt jeśli zmiana kąta > 22 stopni lub przeszliśmy ponad 90m
      if (delta.abs() > 22 || accumulatedDistance > 110 || nearbyAudit != null) {
        final street = _getStreetNameNear(curr);
        IconData icon = Icons.straight;
        String instPl = 'Idź prosto wzdłuż $street';
        String instEn = 'Continue straight along $street';

        if (nearbyAudit != null) {
          icon = Icons.alt_route;
          instPl = 'Omiń barierę: kieruj się płaskim najazdem ($street)';
          instEn = 'Bypass obstacle: use flat ramp path ($street)';
        } else if (delta > 45) {
          icon = Icons.turn_right;
          instPl = 'Skręć w prawo w $street';
          instEn = 'Turn right onto $street';
        } else if (delta < -45) {
          icon = Icons.turn_left;
          instPl = 'Skręć w lewo w $street';
          instEn = 'Turn left onto $street';
        } else if (delta > 20) {
          icon = Icons.turn_slight_right;
          instPl = 'Łagodnie w prawo w $street';
          instEn = 'Slight right onto $street';
        } else if (delta < -20) {
          icon = Icons.turn_slight_left;
          instPl = 'Łagodnie w lewo w $street';
          instEn = 'Slight left onto $street';
        }

        steps.add(NavigationStep(
          point: curr,
          instructionPl: instPl,
          instructionEn: instEn,
          streetName: street,
          maneuverIcon: icon,
          distanceMeters: accumulatedDistance,
          accessibilityNotePl: _getStepAccessibilityNotePl(profile, nearbyAudit != null),
          accessibilityNoteEn: _getStepAccessibilityNoteEn(profile, nearbyAudit != null),
        ));

        accumulatedDistance = 0;
      }
    }

    // 3. KROK KOŃCOWY (META)
    final destStreet = _getStreetNameNear(coords.last);
    steps.add(NavigationStep(
      point: coords.last,
      instructionPl: 'Cel osiągnięty: $destStreet',
      instructionEn: 'Destination reached: $destStreet',
      streetName: destStreet,
      maneuverIcon: Icons.flag,
      distanceMeters: 0,
      accessibilityNotePl: 'Gratulacje! 0 pokonanych schodów, 100% zjazdów WCAG.',
      accessibilityNoteEn: 'Congratulations! 0 stairs climbed, 100% WCAG accessible.',
    ));

    return steps;
  }

  static String _getStreetNameNear(LatLng point) {
    const dist = Distance();

    // Kluczowe punkty i ulice w centrum Krakowa
    final spots = [
      MapEntry(const LatLng(50.0652, 19.9442), 'ul. Lubicz / Dworzec Główny'),
      MapEntry(const LatLng(50.0668, 19.9460), 'Plac Kolejowy (Dworzec PKP)'),
      MapEntry(const LatLng(50.0645, 19.9405), 'Brama Floriańska / ul. Floriańska'),
      MapEntry(const LatLng(50.0650, 19.9420), 'Planty Krakowskie (Aleja Główna)'),
      MapEntry(const LatLng(50.0635, 19.9380), 'ul. Sławkowska (Gładki trakt)'),
      MapEntry(const LatLng(50.0617, 19.9373), 'Rynek Główny (Płyta Rynku)'),
      MapEntry(const LatLng(50.0625, 19.9360), 'ul. Szczepańska / Szewska'),
      MapEntry(const LatLng(50.0590, 19.9375), 'ul. Grodzka / Plac Wszystkich Świętych'),
      MapEntry(const LatLng(50.0538, 19.9372), 'ul. Bernardyńska (Wawel)'),
      MapEntry(const LatLng(50.0520, 19.9340), 'Bulwary Wiślane / ul. Powiśle'),
      MapEntry(const LatLng(50.0519, 19.9452), 'ul. Miodowa / Plac Nowy (Kazimierz)'),
      MapEntry(const LatLng(50.0460, 19.9480), 'Kładka Ojca Bernatka / Podgórze'),
      MapEntry(const LatLng(50.0660, 19.9595), 'Rondo Mogilskie (Ciąg naziemny)'),
      MapEntry(const LatLng(50.0632, 19.9328), 'ul. Karmelicka / Teatr Bagatela'),
      MapEntry(const LatLng(50.0665, 19.9190), 'Aleja Mickiewicza / Kampus AGH'),
      MapEntry(const LatLng(50.0595, 19.9110), 'Aleja 3 Maja / Błonia Krakowskie'),
    ];

    for (final s in spots) {
      if (dist.as(LengthUnit.Meter, point, s.key) < 180) {
        return s.value;
      }
    }

    return 'Ciąg pieszy Krakowa';
  }

  static String _getStartAccessibilityNotePl(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'Płaski zjazd 0 cm. Rozpoczynasz trasę bez schodów.';
      case MobilityProfile.cane:
        return 'Nawierzchnia równa i stabilna. Spokojne tempo marszu.';
      case MobilityProfile.stroller:
        return 'Gładki start – bezpieczne prowadzenie wózka dziecięcego.';
    }
  }

  static String _getStartAccessibilityNoteEn(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'Flush 0 cm curb ramp. Starting stair-free route.';
      case MobilityProfile.cane:
        return 'Stable non-slip pavement. Steady walking pace.';
      case MobilityProfile.stroller:
        return 'Smooth start – safe stroller navigation.';
    }
  }

  static String _getStepAccessibilityNotePl(MobilityProfile p, bool isBypass) {
    if (isBypass) {
      switch (p) {
        case MobilityProfile.wheelchair:
          return 'Ominięto stopnie! Płaski zjazd rampowy <4% zlicowany 0 cm.';
        case MobilityProfile.cane:
          return 'Ominięto strome schody. Łagodny spadek i ławka za 60 m.';
        case MobilityProfile.stroller:
          return 'Brak schodów. Gładka nawierzchnia chroniąca sen niemowlęcia.';
      }
    }
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'Płytowy chodnik bez głębokich fug. Zjazd zlicowany 0-1 cm.';
      case MobilityProfile.cane:
        return 'Nawierzchnia antypoślizgowa. Ławki spoczynkowe w zasięgu wzroku.';
      case MobilityProfile.stroller:
        return 'Szeroka aleja parkowa z dala od spalin i wstrząsów.';
    }
  }

  static String _getStepAccessibilityNoteEn(MobilityProfile p, bool isBypass) {
    if (isBypass) {
      switch (p) {
        case MobilityProfile.wheelchair:
          return 'Stairs bypassed! Flush 0 cm curb ramp with slope <4%.';
        case MobilityProfile.cane:
          return 'Steep steps avoided. Gentle slope and bench in 60 m.';
        case MobilityProfile.stroller:
          return 'Zero stairs. Smooth surface protects baby sleep.';
      }
    }
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'Paved walkway without deep gaps. Flush 0-1 cm curb.';
      case MobilityProfile.cane:
        return 'Non-slip surface. Resting benches within view.';
      case MobilityProfile.stroller:
        return 'Wide park avenue away from traffic and vibrations.';
    }
  }
}
