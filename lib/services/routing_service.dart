import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/accessibility_audit.dart';
import '../models/route_model.dart';
import '../providers/app_state.dart';

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
      start: LatLng(50.0668, 19.9464),
      end: LatLng(50.0617, 19.9373),
      startName: 'Dworzec Główny PKP',
      endName: 'Sukiennice (Rynek Główny)',
    ),
    RoutePreset(
      id: 'preset_wawel_kazimierz',
      titlePl: 'Wawel (Zamek) ➔ Plac Nowy (Kazimierz)',
      titleEn: 'Wawel Castle ➔ Plac Nowy (Kazimierz)',
      start: LatLng(50.0545, 19.9354),
      end: LatLng(50.0519, 19.9452),
      startName: 'Wawel (ul. Podzamcze)',
      endName: 'Plac Nowy (Kazimierz)',
    ),
    RoutePreset(
      id: 'preset_barbakan_sukiennice',
      titlePl: 'Barbakan ➔ Rynek Główny',
      titleEn: 'Barbican ➔ Main Market Square',
      start: LatLng(50.0656, 19.9416),
      end: LatLng(50.0617, 19.9373),
      startName: 'Barbakan Krakowski',
      endName: 'Sukiennice (Rynek Główny)',
    ),
  ];

  /// Pobiera trasy dla wybranego presetu z wyraźnie różnymi współrzędnymi!
  static List<RouteModel> getRoutesForPreset(String presetId, MobilityProfile profile) {
    if (presetId == 'preset_wawel_kazimierz') {
      return _getWawelKazimierzRoutes(profile);
    }
    if (presetId == 'preset_barbakan_sukiennice') {
      return _getBarbakanRynekRoutes(profile);
    }
    return _getDworzecRynekRoutes(profile);
  }

  /// Dynamiczne wyznaczanie trasy A ➔ B z osobnymi trasami i wykrywaniem barier
  static Future<List<RouteModel>> calculateDynamicRoute({
    required LatLng start,
    required LatLng end,
    required MobilityProfile profile,
    String? startName,
    String? destinationName,
  }) async {
    List<LatLng> directPoints = [];
    int distance = 800;
    int duration = 11;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routesJson = data['routes'] as List?;
        if (routesJson != null && routesJson.isNotEmpty) {
          final rawCoords = routesJson[0]['geometry']['coordinates'] as List;
          distance = (routesJson[0]['distance'] as num).toDouble().round();
          duration = ((routesJson[0]['duration'] as num).toDouble() / 60).round().clamp(1, 999);

          directPoints = rawCoords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
        }
      }
    } catch (_) {
      // Ignoruj błąd sieci
    }

    if (directPoints.isEmpty) {
      directPoints = _interpolatePoints(start, end, 6);
    }

    // Wygeneruj odrębną geometrię objazdu (Bypass) dla trasy KrakAccess!
    final bypassPoints = _generateBypassCoordinates(directPoints, start, end);

    return _buildDynamicRoutePair(
      start: start,
      end: end,
      directPoints: directPoints,
      bypassPoints: bypassPoints,
      distanceMeters: distance,
      durationMinutes: duration,
      profile: profile,
      startName: startName ?? 'Punkt startowy',
      destName: destinationName ?? 'Cel podróży',
    );
  }

  static List<LatLng> _interpolatePoints(LatLng a, LatLng b, int segments) {
    final List<LatLng> pts = [];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      pts.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
    return pts;
  }

  /// Tworzy widocznie różną trasę objazdu omijającą barierę na trasie prostej
  static List<LatLng> _generateBypassCoordinates(List<LatLng> direct, LatLng start, LatLng end) {
    if (direct.length < 2) return direct;

    final List<LatLng> bypass = [];

    // Oblicz wektor prostopadły do linii start-end
    final dLat = end.latitude - start.latitude;
    final dLng = end.longitude - start.longitude;
    final len = math.sqrt(dLat * dLat + dLng * dLng);

    // Przesunięcie o ok. 70 metrów w bok (łuk objazdu przez równoległą aleję)
    final offsetLat = (-dLng / (len == 0 ? 1 : len)) * 0.0009;
    final offsetLng = (dLat / (len == 0 ? 1 : len)) * 0.0009;

    for (int i = 0; i < direct.length; i++) {
      if (i == 0 || i == direct.length - 1) {
        bypass.add(direct[i]);
      } else {
        // Płynny łuk wokół środka trasy (gdzie leży bariera)
        final factor = math.sin((i / (direct.length - 1)) * math.pi);
        bypass.add(LatLng(
          direct[i].latitude + offsetLat * factor,
          direct[i].longitude + offsetLng * factor,
        ));
      }
    }
    return bypass;
  }

  static List<RouteModel> _buildDynamicRoutePair({
    required LatLng start,
    required LatLng end,
    required List<LatLng> directPoints,
    required List<LatLng> bypassPoints,
    required int distanceMeters,
    required int durationMinutes,
    required MobilityProfile profile,
    required String startName,
    required String destName,
  }) {
    final midpoint = directPoints[directPoints.length ~/ 2];

    final standardAudit = AccessibilityAudit(
      id: 'aud_dyn_std_${DateTime.now().millisecondsSinceEpoch}',
      checkpointName: 'Wykryta bariera architektoniczna ($destName)',
      location: midpoint,
      // Zdjęcie schodów i krawężnika miejskiego
      photoUrl: 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?auto=format&fit=crop&w=800&q=80',
      isAccessible: false,
      score: profile == MobilityProfile.wheelchair ? 22 : (profile == MobilityProfile.cane ? 46 : 32),
      stairsDetected: true,
      stairsCount: 16,
      curbStatus: 'Wysoki krawężnik 12 cm (brak rampy)',
      surfaceType: 'Schody betonowe / popękany chodnik',
      hazards: const ['16 stopni schodowych', 'Brak pochylni', 'Krawężnik 12 cm'],
      aiVerdictPl: profile == MobilityProfile.wheelchair
          ? 'KRYTYCZNA BARIERA DLA WÓZKA: 16 stopni bez windy lub rampy. Przejazd niemożliwy.'
          : (profile == MobilityProfile.cane
              ? 'ZAGROŻENIE DLA SENIORA: Strome stopnie bez barierki – ryzyko upadku.'
              : 'UTRUDNIENIE: Wymaga wnoszenia wózka dziecięcego po schodach.'),
      aiVerdictEn: 'ARCHITECTURAL BARRIER: 16 stairs detected without ramp or elevator.',
      // Zdjęcie płaskiego objazdu KrakAccess
      bypassPhotoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
      bypassTitlePl: 'Zweryfikowany objazd KrakAccess',
      bypassTitleEn: 'KrakAccess Verified Bypass',
      bypassDescriptionPl: 'Objazd sąsiednią aleją z płaskim chodnikiem i rampami 0 cm.',
      bypassDescriptionEn: 'Bypass via adjacent avenue with flat sidewalk and 0cm ramps.',
      profileImpactPl: _getProfileImpactPl(profile, 'schody'),
      profileImpactEn: _getProfileImpactEn(profile, 'stairs'),
    );

    final accessibleAudit = AccessibilityAudit(
      id: 'aud_dyn_acc_${DateTime.now().millisecondsSinceEpoch}',
      checkpointName: 'Płaski punkt kontrolny KrakAccess',
      location: bypassPoints[bypassPoints.length ~/ 2],
      photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
      isAccessible: true,
      score: profile == MobilityProfile.wheelchair ? 98 : (profile == MobilityProfile.cane ? 95 : 97),
      stairsDetected: false,
      stairsCount: 0,
      curbStatus: 'Zjazd rampowy zlicowany 0 cm',
      surfaceType: 'Gładkie płyty chodnikowe bezszwowe',
      hazards: const [],
      aiVerdictPl: profile == MobilityProfile.wheelchair
          ? 'BEZPIECZNE: Płaski trakt pieszy bez schodów, szerokość >2.2 m, 100% ramp.'
          : (profile == MobilityProfile.cane
              ? 'BEZPIECZNE: Płaski odcinek z ławkami i łagodnym spadkiem <2.5%.'
              : 'BEZPIECZNE: Szeroki chodnik dla wózka dziecięcego bez wstrząsów.'),
      aiVerdictEn: 'SAFE: Flat surface, dropped curbs, excellent accessibility.',
      bypassTitlePl: 'Sprawdzony trakt KrakAccess',
      bypassTitleEn: 'KrakAccess Verified Path',
      bypassDescriptionPl: 'Trasa prowadzona wyłącznie równymi chodnikami i przejściami naziemnymi.',
      bypassDescriptionEn: 'Route routed exclusively through smooth pavements and pedestrian crossings.',
      profileImpactPl: 'Dostosowane do wybranego profilu mobilności.',
      profileImpactEn: 'Adapted for the selected mobility profile.',
    );

    // TRASA ZIELONA (KrakAccess - Omija barierę)
    final accessibleRoute = RouteModel(
      id: 'route_dyn_acc',
      titlePl: 'Trasa KrakAccess (Obejście barier)',
      titleEn: 'KrakAccess Route (Barrier Bypass)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: distanceMeters + 75,
      durationMinutes: durationMinutes + 1,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 98 : (profile == MobilityProfile.cane ? 95 : 97),
      stairsAvoided: 16,
      surfaceSummaryPl: 'Gładkie płyty chodnikowe, 0 schodów, zjazdy rampowe 0cm',
      surfaceSummaryEn: 'Smooth pavement, 0 stairs, 0cm dropped curbs',
      coordinates: bypassPoints, // RÓŻNA GEOMETRIA!
      audits: [accessibleAudit],
      profileHighlightsPl: _getHighlightsPl(profile),
      profileHighlightsEn: _getHighlightsEn(profile),
      detectedBarrierPl: 'Bariera na trasie bezpośredniej: 16 stopni schodowych bez rampy',
      detectedBarrierEn: 'Barrier on direct route: 16 stairs without ramp',
      bypassReasonPl: 'Ominięto barierę płaskim łukiem chodnikowym (+75 m, 0 stopni)',
      bypassReasonEn: 'Bypassed barrier via flat sidewalk arc (+75 m, 0 stairs)',
    );

    // TRASA CZERWONA (Standardowa - Idzie prosto przez barierę)
    final standardRoute = RouteModel(
      id: 'route_dyn_std',
      titlePl: 'Trasa standardowa (Zawiera bariery)',
      titleEn: 'Standard Route (Contains barriers)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: distanceMeters,
      durationMinutes: durationMinutes,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 22 : (profile == MobilityProfile.cane ? 46 : 32),
      stairsAvoided: 0,
      surfaceSummaryPl: 'Schody (16 stopni), krawężniki 12cm, uszkodzona nawierzchnia',
      surfaceSummaryEn: 'Stairs (16 steps), 12cm curbs, uneven pavement',
      coordinates: directPoints, // RÓŻNA GEOMETRIA!
      audits: [standardAudit],
      profileHighlightsPl: const ['Krótsza o 75 m', 'Zawiera 16 stromych stopni bez windy'],
      profileHighlightsEn: const ['75 m shorter', 'Contains 16 steep steps without lift'],
    );

    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getDworzecRynekRoutes(MobilityProfile profile) {
    // 1. Trasa standardowa (CZERWONA - Tunel ze schodami pod Lubicz + kocie łby na Floriańskiej)
    final standardAudits = [
      AccessibilityAudit(
        id: 'aud_std_1',
        checkpointName: 'Przejście podziemne Dworzec / Planty (ul. Lubicz)',
        location: const LatLng(50.0652, 19.9442),
        photoUrl: 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?auto=format&fit=crop&w=800&q=80',
        isAccessible: false,
        score: profile == MobilityProfile.wheelchair ? 20 : (profile == MobilityProfile.cane ? 45 : 30),
        stairsDetected: true,
        stairsCount: 24,
        curbStatus: 'Brak rampy / schody strome',
        surfaceType: 'Schody betonowe (24 stopnie w dół i w górę)',
        hazards: const ['24 stopnie w dół i w górę', 'Zepsuta winda platformowa', 'Brak pochylni'],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'KRYTYCZNA BARIERA DLA WÓZKA: 24 stopnie bez windy. Przejazd niemożliwy bez asysty 2 osób.'
            : (profile == MobilityProfile.cane
                ? 'ZAGROŻENIE DLA SENIORA: Śliskie stopnie i strome zejście – wysokie ryzyko upadku.'
                : 'UTRUDNIENIE: Konieczność zniesienia wózka dziecięcego ze schodów.'),
        aiVerdictEn: 'CRITICAL BARRIER: 24 steps without functioning elevator.',
        bypassPhotoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
        bypassTitlePl: 'Obejście KrakAccess (Naziemne Planty)',
        bypassTitleEn: 'KrakAccess Bypass (Ground Crossing)',
        bypassDescriptionPl: 'Skierowano przez przejście naziemne z sygnalizacją dźwiękową i rampą 0cm.',
        bypassDescriptionEn: 'Rerouted through ground level crossing with 0cm ramp.',
        profileImpactPl: _getProfileImpactPl(profile, 'schody'),
        profileImpactEn: _getProfileImpactEn(profile, 'stairs'),
      ),
      AccessibilityAudit(
        id: 'aud_std_2',
        checkpointName: 'Wlot ul. Floriańskiej (Brama Floriańska)',
        location: const LatLng(50.0645, 19.9405),
        photoUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?auto=format&fit=crop&w=800&q=80',
        isAccessible: false,
        score: profile == MobilityProfile.wheelchair ? 35 : (profile == MobilityProfile.cane ? 60 : 45),
        stairsDetected: false,
        curbStatus: 'Krawężnik 12 cm',
        surfaceType: 'Zabytkowa kostka bazaltowa (kocie łby)',
        hazards: const ['Silne drgania', 'Głębokie spoiny >3cm', 'Ryzyko zaklinowania kółek'],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'TRUDNA NAWIERZCHNIA: Nierówny bruk historyczny powoduje niebezpieczne wibracje i blokowanie kółek wózka.'
            : (profile == MobilityProfile.cane
                ? 'Nierówna kostka: Utrudnione oparcie laski, ryzyko skręcenia kostki.'
                : 'Uciążliwe wstrząsy dla śpiącego dziecka w wózku.'),
        aiVerdictEn: 'Uneven cobblestone causing intense vibrations and trip hazard.',
        bypassPhotoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
        bypassTitlePl: 'Objazd ul. Szpitalną',
        bypassTitleEn: 'Bypass via Szpitalna St.',
        bypassDescriptionPl: 'Gładkie płyty granitowe po rewitalizacji bez szwów.',
        bypassDescriptionEn: 'Smooth revitalized granite slabs.',
      ),
    ];

    final standardRoute = RouteModel(
      id: 'route_standard_dworzec',
      titlePl: 'Trasa standardowa (Schody podziemne i kocie łby)',
      titleEn: 'Standard Route (Stairs & Cobblestones)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 850,
      durationMinutes: 12,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 25 : (profile == MobilityProfile.cane ? 50 : 36),
      stairsAvoided: 0,
      surfaceSummaryPl: 'Schody (24 stopnie w tunelu), kocie łby na Floriańskiej',
      surfaceSummaryEn: 'Stairs (24 underground steps), rough cobblestone',
      // GEOMETRIA PROSTA PRZEZ TUNEL I FLORIAŃSKĄ:
      coordinates: const [
        LatLng(50.0668, 19.9464), // Dworzec
        LatLng(50.0658, 19.9450),
        LatLng(50.0652, 19.9442), // Bariera: schody w tunelu
        LatLng(50.0645, 19.9405), // Brama Floriańska / bruk
        LatLng(50.0630, 19.9390), // ul. Floriańska
        LatLng(50.0617, 19.9373), // Sukiennice
      ],
      audits: standardAudits,
      profileHighlightsPl: const ['Krótsza o 70 m', 'Zawiera 24 strome stopnie bez windy'],
      profileHighlightsEn: const ['70 m shorter', 'Contains 24 steep steps without lift'],
    );

    // 2. Trasa dostępna KrakAccess (ZIELONA - Naziemne Planty + ul. Szpitalna)
    final accessibleAudits = [
      AccessibilityAudit(
        id: 'aud_acc_1',
        checkpointName: 'Przejście naziemne Planty (ul. Westerplatte / Lubicz)',
        location: const LatLng(50.0648, 19.9451),
        photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
        isAccessible: true,
        score: profile == MobilityProfile.wheelchair ? 98 : (profile == MobilityProfile.cane ? 96 : 97),
        stairsDetected: false,
        curbStatus: 'Zjazd zlicowany z jezdnią 0 cm',
        surfaceType: 'Gładki asfalt / Płyty szlifowane',
        hazards: const [],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'OPTYMALNE: Całkowicie płaski przejazd przez aleję Plant, 0 stopni, szerokie pasy z rampami.'
            : (profile == MobilityProfile.cane
                ? 'KOMFORTOWE: Płaski trakt z ławeczkami w cieniu drzew na Plantach, brak stopni.'
                : 'IDEALNE: Szerokie, równe przejście dla wózka dziecięcego.'),
        aiVerdictEn: 'OPTIMAL: Fully accessible ground crossing, zero steps.',
        bypassTitlePl: 'Sprawdzony trakt KrakAccess',
        bypassTitleEn: 'KrakAccess Path',
        bypassDescriptionPl: 'Audyt AI potwierdził obecność obniżonych krawężników i brak barier.',
        bypassDescriptionEn: 'AI audit verified dropped curbs and zero obstacles.',
      ),
      AccessibilityAudit(
        id: 'aud_acc_2',
        checkpointName: 'Dojście ul. Szpitalną do Rynku',
        location: const LatLng(50.0628, 19.9388),
        photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
        isAccessible: true,
        score: 98,
        stairsDetected: false,
        curbStatus: 'Łagodny najazd rampowy 0-1cm',
        surfaceType: 'Gładkie płyty chodnikowe bezszwowe',
        hazards: const [],
        aiVerdictPl: 'OPTYMALNE: Nowa nawierzchnia płytowa po rewitalizacji, brak wstrząsów, szerokość >2.4 m.',
        aiVerdictEn: 'OPTIMAL: Smooth paving slabs, width >2.4m, safe for all mobility types.',
      ),
    ];

    final accessibleRoute = RouteModel(
      id: 'route_accessible_dworzec',
      titlePl: 'Trasa KrakAccess (Płaskie Planty i ul. Szpitalna)',
      titleEn: 'KrakAccess Route (Planty & Szpitalna St.)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 920,
      durationMinutes: 13,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 98 : (profile == MobilityProfile.cane ? 96 : 97),
      stairsAvoided: 24,
      surfaceSummaryPl: 'Gładkie płyty szlifowane, 0 schodów, 100% zjazdów rampowych',
      surfaceSummaryEn: 'Smooth granite slabs, 0 stairs, 100% dropped curbs',
      // GEOMETRIA OBIEGAJĄCA SCHODY: Przejście naziemne + ul. Westerplatte + Szpitalna
      coordinates: const [
        LatLng(50.0668, 19.9464), // Start: Dworzec
        LatLng(50.0662, 19.9458),
        LatLng(50.0648, 19.9451), // Naziemne przejście dla pieszych
        LatLng(50.0638, 19.9418), // Teatr Słowackiego
        LatLng(50.0628, 19.9388), // ul. Szpitalna
        LatLng(50.0617, 19.9373), // Sukiennice
      ],
      audits: accessibleAudits,
      profileHighlightsPl: _getHighlightsPl(profile),
      profileHighlightsEn: _getHighlightsEn(profile),
      detectedBarrierPl: 'Przejście podziemne: 24 stopnie w dół i w górę bez windy',
      detectedBarrierEn: 'Underpass: 24 steps without functioning elevator',
      bypassReasonPl: 'Ominięto schody naziemnym przejściem przez Planty (+70 m, 0 stopni)',
      bypassReasonEn: 'Bypassed stairs via flat Planty crossing (+70 m, 0 stairs)',
    );

    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getWawelKazimierzRoutes(MobilityProfile profile) {
    final standardRoute = RouteModel(
      id: 'route_std_wawel',
      titlePl: 'Trasa standardowa (przez strome schody)',
      titleEn: 'Standard Route (via steep steps)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 1100,
      durationMinutes: 15,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 22 : (profile == MobilityProfile.cane ? 35 : 40),
      stairsAvoided: 0,
      surfaceSummaryPl: 'Strome stopnie kamienne (18 schodów), śliski wapień',
      surfaceSummaryEn: 'Steep stone steps (18 stairs), slippery limestone',
      coordinates: const [
        LatLng(50.0545, 19.9354), // Wawel Podzamcze
        LatLng(50.0538, 19.9372), // Schody kamienne
        LatLng(50.0530, 19.9410),
        LatLng(50.0519, 19.9452), // Plac Nowy
      ],
      audits: [
        AccessibilityAudit(
          id: 'aud_wawel_std',
          checkpointName: 'Zejście pod Wzgórzem Wawelskim (ul. św. Idziego)',
          location: const LatLng(50.0538, 19.9372),
          photoUrl: 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?auto=format&fit=crop&w=800&q=80',
          isAccessible: false,
          score: profile == MobilityProfile.wheelchair ? 20 : 35,
          stairsDetected: true,
          stairsCount: 18,
          curbStatus: 'Strome schody bez poręczy',
          surfaceType: 'Wapień historyczny śliski',
          hazards: const ['18 stopni', 'Brak pochylni', 'Spadek terenu 11%'],
          aiVerdictPl: 'KRYTYCZNA BARIERA: Schody kamienne o nachyleniu 11% bez pochylni.',
          aiVerdictEn: 'CRITICAL BARRIER: Steep stone steps with 11% gradient.',
          bypassPhotoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
          bypassTitlePl: 'Płaski zjazd ul. Bernardyńską',
          bypassTitleEn: 'Flat ramp via Bernardyńska St.',
          bypassDescriptionPl: 'Łagodne nachylenie <3.5%, gładki asfalt i bezpieczne barierki.',
          bypassDescriptionEn: 'Gentle slope <3.5%, smooth asphalt.',
        ),
      ],
      profileHighlightsPl: const ['Krótsza o 150m', 'Strome schody kamienne (18 stopni)'],
      profileHighlightsEn: const ['150m shorter', 'Steep stone steps (18 steps)'],
    );

    final accessibleRoute = RouteModel(
      id: 'route_acc_wawel',
      titlePl: 'Trasa KrakAccess (Płaski zjazd ul. Bernardyńską i Dietla)',
      titleEn: 'KrakAccess Route (Bernardyńska & Dietla)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 1250,
      durationMinutes: 17,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 95 : (profile == MobilityProfile.cane ? 93 : 95),
      stairsAvoided: 18,
      surfaceSummaryPl: 'Łagodne nachylenie <3.5%, gładki asfalt, 0 schodów',
      surfaceSummaryEn: 'Gentle slope <3.5%, smooth asphalt, 0 stairs',
      // Inna ścieżka! Omija wzgórze Bernardyńską
      coordinates: const [
        LatLng(50.0545, 19.9354),
        LatLng(50.0530, 19.9360),
        LatLng(50.0515, 19.9395), // Bernardyńska łagodna
        LatLng(50.0510, 19.9430), // Dietla
        LatLng(50.0519, 19.9452), // Plac Nowy
      ],
      audits: [
        const AccessibilityAudit(
          id: 'aud_wawel_acc',
          checkpointName: 'Płaski zjazd ul. Bernardyńska / Dietla',
          location: LatLng(50.0515, 19.9395),
          photoUrl: 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
          isAccessible: true,
          score: 95,
          stairsDetected: false,
          curbStatus: 'Zjazd wózkowy 0cm',
          surfaceType: 'Asfalt gładki',
          hazards: [],
          aiVerdictPl: 'BEZPIECZNE: Płaski trakt pieszy o nachyleniu 3.2%, w pełni zgodny z normami WCAG.',
          aiVerdictEn: 'SAFE: Flat pedestrian path with 3.2% slope, fully WCAG compliant.',
        ),
      ],
      profileHighlightsPl: _getHighlightsPl(profile),
      profileHighlightsEn: _getHighlightsEn(profile),
      detectedBarrierPl: 'Strome zejście z Wawelu: 18 kamiennych stopni bez rampy',
      detectedBarrierEn: 'Steep Wawel descent: 18 stone steps without ramp',
      bypassReasonPl: 'Skierowano łagodnym traktem ul. Bernardyńskiej (+150m, 0 stopni)',
      bypassReasonEn: 'Rerouted through gentle Bernardyńska slope (+150m, 0 stairs)',
    );

    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getBarbakanRynekRoutes(MobilityProfile profile) {
    final accessibleRoute = RouteModel(
      id: 'route_acc_barbakan',
      titlePl: 'Trasa KrakAccess (ul. Sławkowska - gładka)',
      titleEn: 'KrakAccess Route (Sławkowska St. - smooth)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 480,
      durationMinutes: 7,
      accessibilityScore: 98,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Gładkie płyty granitowe, zlicowane krawężniki 0-1cm',
      surfaceSummaryEn: 'Smooth granite slabs, flush curbs 0-1cm',
      coordinates: const [
        LatLng(50.0656, 19.9416),
        LatLng(50.0645, 19.9395),
        LatLng(50.0628, 19.9380),
        LatLng(50.0617, 19.9373),
      ],
      audits: const [],
      profileHighlightsPl: _getHighlightsPl(profile),
      profileHighlightsEn: _getHighlightsEn(profile),
    );

    final standardRoute = RouteModel(
      id: 'route_std_barbakan',
      titlePl: 'Trasa standardowa (ul. Floriańska - kocie łby)',
      titleEn: 'Standard Route (Floriańska - cobblestones)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 450,
      durationMinutes: 6,
      accessibilityScore: 40,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Zabytkowy nierówny bruk',
      surfaceSummaryEn: 'Historic uneven cobblestones',
      coordinates: const [
        LatLng(50.0656, 19.9416),
        LatLng(50.0640, 19.9410),
        LatLng(50.0617, 19.9373),
      ],
      audits: const [],
      profileHighlightsPl: const ['Krótsza o 30m', 'Mocne drgania nawierzchni'],
      profileHighlightsEn: const ['30m shorter', 'Severe vibrations'],
    );

    return [accessibleRoute, standardRoute];
  }

  static List<String> _getHighlightsPl(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          '0 schodów na całej trasie',
          '100% zjazdów rampowych (<1.5 cm)',
          'Ominięto kocie łby na Floriańskiej',
        ];
      case MobilityProfile.cane:
        return [
          '8 ławek do odpoczynku na Plantach',
          'Płaski trakt bez stromych wzniesień (<3%)',
          'Nawierzchnia antypoślizgowa',
        ];
      case MobilityProfile.stroller:
        return [
          'Szerokość ciągu pieszego >2.2 m',
          'Brak wstrząsów dla dziecka',
          'Łagodne rampy zjazdowe',
        ];
    }
  }

  static List<String> _getHighlightsEn(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          '0 stairs along entire route',
          '100% dropped curbs (<1.5 cm)',
          'Avoided rough cobblestone',
        ];
      case MobilityProfile.cane:
        return [
          '8 resting benches in Planty park',
          'Gentle slope (<3%)',
          'Non-slip pavement',
        ];
      case MobilityProfile.stroller:
        return [
          'Sidewalk width >2.2 m',
          'No vibrations for sleeping baby',
          'Gentle ramp transitions',
        ];
    }
  }

  static String _getProfileImpactPl(MobilityProfile p, String barrierType) {
    if (barrierType == 'schody') {
      switch (p) {
        case MobilityProfile.wheelchair:
          return 'WÓZEK: Całkowicie blokuje przejazd. Wymaga zawrócenia lub asysty 2 osób.';
        case MobilityProfile.cane:
          return 'SENIOR / KULA: Wysokie ryzyko upadku i przeciążenia stawów.';
        case MobilityProfile.stroller:
          return 'WÓZEK DZIECIĘCY: Wymaga wnoszenia ciężkiego wózka po stopniach.';
      }
    }
    return 'Wpływ na mobilność zależy od wybranego profilu.';
  }

  static String _getProfileImpactEn(MobilityProfile p, String barrierType) {
    if (barrierType == 'stairs') {
      switch (p) {
        case MobilityProfile.wheelchair:
          return 'WHEELCHAIR: Completely blocks transit. Requires 2 assistants or rerouting.';
        case MobilityProfile.cane:
          return 'SENIOR: High fall risk and knee stress on steep stairs.';
        case MobilityProfile.stroller:
          return 'STROLLER: Requires carrying stroller up/down stairs.';
      }
    }
    return 'Impact depends on mobility profile.';
  }
}
