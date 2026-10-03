import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/accessibility_audit.dart';
import '../models/route_model.dart';

class RoutePreset {
  final String id;
  final String titlePl;
  final String titleEn;
  final LatLng start;
  final LatLng end;
  final String startName;
  final String endName;

  const RoutePreset({
    required this.id,
    required this.titlePl,
    required this.titleEn,
    required this.start,
    required this.end,
    required this.startName,
    required this.endName,
  });
}

class RoutingService {
  static const List<RoutePreset> presets = [
    RoutePreset(
      id: 'preset_dworzec_rynek',
      titlePl: 'Dworzec Główny ➔ Sukiennice (Rynek)',
      titleEn: 'Main Station ➔ Cloth Hall (Market Sq.)',
      start: LatLng(50.0668, 19.9464), // Dworzec / Pawia
      end: LatLng(50.0617, 19.9373), // Sukiennice
      startName: 'Dworzec Główny PKP',
      endName: 'Rynek Główny / Sukiennice',
    ),
    RoutePreset(
      id: 'preset_wawel_kazimierz',
      titlePl: 'Wawel (Zamek) ➔ Plac Nowy (Kazimierz)',
      titleEn: 'Wawel Castle ➔ Plac Nowy (Kazimierz)',
      start: LatLng(50.0545, 19.9354), // Wawel Podzamcze
      end: LatLng(50.0519, 19.9452), // Plac Nowy
      startName: 'Wawel (ul. Podzamcze)',
      endName: 'Plac Nowy (Kazimierz)',
    ),
  ];

  /// Pobiera parę tras: [Trasa standardowa (z barierami), Trasa KrakAccess (bez barier)]
  static List<RouteModel> getRoutesForPreset(String presetId) {
    if (presetId == 'preset_wawel_kazimierz') {
      return _getWawelKazimierzRoutes();
    }
    return _getDworzecRynekRoutes();
  }

  static List<RouteModel> _getDworzecRynekRoutes() {
    // 1. Trasa standardowa (przejście podziemne ze schodami, Floriańska kocie łby)
    final standardAudits = [
      const AccessibilityAudit(
        id: 'aud_std_1',
        checkpointName: 'Przejście podziemne Dworzec / Planty',
        location: LatLng(50.0652, 19.9442),
        photoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
        isAccessible: false,
        score: 25,
        stairsDetected: true,
        stairsCount: 24,
        curbStatus: 'Wysoki stopień (brak rampy)',
        surfaceType: 'Śliskie kafelki / Schody betonowe',
        hazards: ['24 stopnie w dół i w górę', 'Zepsuta winda platformowa', 'Brak pochylni'],
        aiVerdictPl: 'KRYTYCZNA BARIERA: Schody bez podjazdu uniemożliwiają przejazd wózkiem inwalidzkim. Konieczna asysta 2 osób lub zawrócenie.',
        aiVerdictEn: 'CRITICAL BARRIER: Stairs without ramp make wheelchair transit impossible. Requires 2 assistants or rerouting.',
      ),
      const AccessibilityAudit(
        id: 'aud_std_2',
        checkpointName: 'Wlot ul. Floriańskiej (Brama)',
        location: LatLng(50.0645, 19.9405),
        photoUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=800&q=80',
        isAccessible: false,
        score: 45,
        stairsDetected: false,
        curbStatus: 'Krawężnik 12 cm',
        surfaceType: 'Zabytkowa kostka bazaltowa (kocie łby)',
        hazards: ['Silne drgania', 'Szczeliny >4cm', 'Ryzyko zaklinowania przednich kółek'],
        aiVerdictPl: 'Trudna nawierzchnia: Nierówny bruk historyczny powoduje niebezpieczne wstrząsy dla wózków i ryzyko upadku o kuli.',
        aiVerdictEn: 'Difficult surface: Uneven historic basalt stones cause severe vibrations and fall risk for crutches.',
      ),
    ];

    final standardRoute = RouteModel(
      id: 'route_standard_dworzec',
      titlePl: 'Trasa standardowa (Google Maps / Piesza)',
      titleEn: 'Standard Pedestrian Route',
      type: RouteType.standard,
      polylineColor: const Color(0xFFE53935), // Red
      distanceMeters: 850,
      durationMinutes: 12,
      accessibilityScore: 32,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Schody (24 stopnie), bruk zabytkowy, krawężniki 12cm',
      surfaceSummaryEn: 'Stairs (24 steps), uneven cobblestone, 12cm curbs',
      coordinates: const [
        LatLng(50.0668, 19.9464), // Start: Dworzec Główny
        LatLng(50.0660, 19.9458),
        LatLng(50.0652, 19.9442), // Bariera: przejście podziemne schody
        LatLng(50.0645, 19.9405), // Brama Floriańska
        LatLng(50.0630, 19.9390), // ul. Floriańska
        LatLng(50.0617, 19.9373), // Rynek / Sukiennice
      ],
      audits: standardAudits,
    );

    // 2. Trasa KrakAccess (Płaskie Planty, obniżone krawężniki, płaska kostka płytowa)
    final accessibleAudits = [
      const AccessibilityAudit(
        id: 'aud_acc_1',
        checkpointName: 'Przejście naziemne Planty (ul. Westerplatte / Lubicz)',
        location: LatLng(50.0648, 19.9451),
        photoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
        isAccessible: true,
        score: 95,
        stairsDetected: false,
        curbStatus: 'Krawężnik zlicowany z asfaltem (0 cm)',
        surfaceType: 'Asfalt gładki / Płyty granitowe szlifowane',
        hazards: [],
        aiVerdictPl: 'BEZPIECZNE: Płaski przejazd przez aleję Plant, pasy z sygnalizacją dźwiękową, brak stopni.',
        aiVerdictEn: 'SAFE: Flat crossing through Planty park, audible pedestrian signals, zero steps.',
      ),
      const AccessibilityAudit(
        id: 'aud_acc_2',
        checkpointName: 'Dojście ul. Szpitalną do Rynku',
        location: LatLng(50.0628, 19.9388),
        photoUrl: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=800&q=80',
        isAccessible: true,
        score: 98,
        stairsDetected: false,
        curbStatus: 'Łagodny najazd rampowy',
        surfaceType: 'Gładkie płyty chodnikowe bezszwowe',
        hazards: [],
        aiVerdictPl: 'OPTYMALNE: Równa nawierzchnia po rewitalizacji, szerokość >2.2m, bezpieczne dla wózków elektrycznych.',
        aiVerdictEn: 'OPTIMAL: Smooth revitalized paving slabs, width >2.2m, completely safe for electric wheelchairs.',
      ),
    ];

    final accessibleRoute = RouteModel(
      id: 'route_accessible_dworzec',
      titlePl: 'Trasa KrakAccess (Weryfikacja AI)',
      titleEn: 'KrakAccess Route (AI Verified)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981), // Emerald Green
      distanceMeters: 920,
      durationMinutes: 13,
      accessibilityScore: 96,
      stairsAvoided: 24,
      surfaceSummaryPl: 'Gładkie płyty, obniżone krawężniki 0-1cm, 0 schodów',
      surfaceSummaryEn: 'Smooth paving slabs, 0-1cm dropped curbs, 0 stairs',
      coordinates: const [
        LatLng(50.0668, 19.9464), // Start: Dworzec
        LatLng(50.0662, 19.9450), // Obejście naziemne
        LatLng(50.0648, 19.9451), // Planty łagodne
        LatLng(50.0638, 19.9418), // ul. Szpitalna / Teatr Słowackiego
        LatLng(50.0628, 19.9388), // ul. Szpitalna
        LatLng(50.0617, 19.9373), // Sukiennice
      ],
      audits: accessibleAudits,
    );

    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getWawelKazimierzRoutes() {
    final standardRoute = RouteModel(
      id: 'route_std_wawel',
      titlePl: 'Trasa standardowa (przez schody św. Idziego)',
      titleEn: 'Standard Route (via St. Giles stairs)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFE53935),
      distanceMeters: 1100,
      durationMinutes: 15,
      accessibilityScore: 40,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Schody kamienne (18 stopni), kocie łby na ul. Miodowej',
      surfaceSummaryEn: 'Stone steps (18 steps), uneven cobblestone',
      coordinates: const [
        LatLng(50.0545, 19.9354),
        LatLng(50.0538, 19.9372),
        LatLng(50.0530, 19.9410),
        LatLng(50.0519, 19.9452),
      ],
      audits: [
        const AccessibilityAudit(
          id: 'aud_wawel_std',
          checkpointName: 'Zejście pod Wzgórzem Wawelskim',
          location: LatLng(50.0538, 19.9372),
          photoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
          isAccessible: false,
          score: 30,
          stairsDetected: true,
          stairsCount: 18,
          curbStatus: 'Schody strome kamienne',
          surfaceType: 'Wapień historyczny śliski',
          hazards: ['Brak pochylni', '18 stopni', 'Wąski chodnik'],
          aiVerdictPl: 'Bariera: Strome schody bez poręczy i rampy.',
          aiVerdictEn: 'Barrier: Steep stone stairs with no ramp or handrail.',
        ),
      ],
    );

    final accessibleRoute = RouteModel(
      id: 'route_acc_wawel',
      titlePl: 'Trasa KrakAccess (Bulwary i ul. Dietla)',
      titleEn: 'KrakAccess Route (Boulevards & Dietla)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 1250,
      durationMinutes: 17,
      accessibilityScore: 94,
      stairsAvoided: 18,
      surfaceSummaryPl: 'Nawierzchnia płaska asfaltowa, 0 schodów, szerokie przejścia',
      surfaceSummaryEn: 'Flat asphalt and wide crossings, 0 stairs',
      coordinates: const [
        LatLng(50.0545, 19.9354),
        LatLng(50.0530, 19.9360),
        LatLng(50.0515, 19.9395),
        LatLng(50.0510, 19.9430),
        LatLng(50.0519, 19.9452),
      ],
      audits: [
        const AccessibilityAudit(
          id: 'aud_wawel_acc',
          checkpointName: 'Płaski zjazd ul. Bernardyńska / Dietla',
          location: LatLng(50.0515, 19.9395),
          photoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
          isAccessible: true,
          score: 95,
          stairsDetected: false,
          curbStatus: 'Zjazd rowerowo-wózkowy 0cm',
          surfaceType: 'Asfalt gładki',
          hazards: [],
          aiVerdictPl: 'BEZPIECZNE: Szeroki zjazd o nachyleniu poniżej 4%, zgodny z normami dostępności.',
          aiVerdictEn: 'SAFE: Wide gentle slope below 4% gradient, fully compliant with accessibility standards.',
        ),
      ],
    );

    return [accessibleRoute, standardRoute];
  }
}
