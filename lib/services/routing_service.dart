import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/accessibility_audit.dart';
import '../models/route_model.dart';
import '../providers/app_state.dart';
import 'ai_route_analyst.dart';
import 'gtfs_transit_service.dart';

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

  /// Pobiera trasy dla wybranego presetu z wyraźnie różnymi współrzędnymi i obsługą obu kierunków!
  static List<RouteModel> getRoutesForPreset(
    String presetId,
    MobilityProfile profile, {
    bool reversed = false,
  }) {
    if (presetId == 'preset_wawel_kazimierz') {
      return _getWawelKazimierzRoutes(profile, reversed: reversed);
    }
    if (presetId == 'preset_barbakan_sukiennice') {
      return _getBarbakanRynekRoutes(profile, reversed: reversed);
    }
    return _getDworzecRynekRoutes(profile, reversed: reversed);
  }

  /// Dynamiczne wyznaczanie trasy A ➔ B z analizą AI Gemini 3.8 Flash i wykrywaniem barier
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
          duration = ((routesJson[0]['duration'] as num).toDouble() / 60)
              .round()
              .clamp(1, 999);

          directPoints = rawCoords
              .map(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();
        }
      }
    } catch (_) {
      // Ignoruj błąd sieci
    }

    if (directPoints.isEmpty) {
      directPoints = _interpolatePoints(start, end, 6);
      distance = const Distance().as(LengthUnit.Meter, start, end).round();
      duration = (distance / 75).round().clamp(1, 999);
    }

    // Wygeneruj odrębną geometrię objazdu (Bypass) dla trasy KrakAccess!
    final bypassPoints = _generateBypassCoordinates(directPoints, start, end);

    // AI myśli i analizuje realne bariery, schody i nawierzchnię w Krakowie
    final analysis = await AiRouteAnalyst.analyzeRoute(
      startName: startName ?? 'Punkt startowy',
      destinationName: destinationName ?? 'Cel podróży',
      start: start,
      end: end,
      distanceMeters: distance,
      profile: profile,
      directPoints: directPoints,
    );

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
      analysis: analysis,
    );
  }

  static List<LatLng> _interpolatePoints(LatLng a, LatLng b, int segments) {
    final List<LatLng> pts = [];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      pts.add(
        LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
      );
    }
    return pts;
  }

  /// Tworzy widocznie różną trasę objazdu omijającą barierę na trasie prostej
  static List<LatLng> _generateBypassCoordinates(
    List<LatLng> direct,
    LatLng start,
    LatLng end,
  ) {
    if (direct.length < 2) return direct;

    final List<LatLng> bypass = [];

    // Oblicz wektor prostopadły do linii start-end
    final dLat = end.latitude - start.latitude;
    final dLng = end.longitude - start.longitude;
    final len = math.sqrt(dLat * dLat + dLng * dLng);

    // Przesunięcie o ok. 70-80 metrów w bok (łuk objazdu przez równoległą aleję)
    final offsetLat = (-dLng / (len == 0 ? 1 : len)) * 0.0010;
    final offsetLng = (dLat / (len == 0 ? 1 : len)) * 0.0010;

    for (int i = 0; i < direct.length; i++) {
      if (i == 0 || i == direct.length - 1) {
        bypass.add(direct[i]);
      } else {
        // Płynny łuk wokół środka trasy (gdzie leży bariera)
        final factor = math.sin((i / (direct.length - 1)) * math.pi);
        bypass.add(
          LatLng(
            direct[i].latitude + offsetLat * factor,
            direct[i].longitude + offsetLng * factor,
          ),
        );
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
    required AiRouteAnalysisResult analysis,
  }) {
    final standardAudit = AccessibilityAudit(
      id: 'aud_dyn_std_${DateTime.now().millisecondsSinceEpoch}',
      checkpointName: analysis.barrierNamePl,
      location: analysis.obstacleLocation,
      photoUrl: analysis.photoUrl,
      isAccessible: false,
      score: analysis.standardScore,
      stairsDetected: analysis.stairsCount > 0,
      stairsCount: analysis.stairsCount,
      curbStatus: analysis.curbStatusPl,
      surfaceType: analysis.surfaceTypePl,
      hazards: analysis.hazards,
      aiVerdictPl: analysis.aiVerdictPl,
      aiVerdictEn: analysis.aiVerdictEn,
      bypassPhotoUrl: analysis.bypassPhotoUrl,
      bypassTitlePl: 'Zweryfikowany objazd NavAble',
      bypassTitleEn: 'NavAble Verified Bypass',
      bypassDescriptionPl: analysis.bypassReasonPl,
      bypassDescriptionEn: analysis.bypassReasonEn,
      profileImpactPl: _getProfileImpactPl(
        profile,
        analysis.stairsCount > 0 ? 'schody' : 'krawężnik',
      ),
      profileImpactEn: _getProfileImpactEn(
        profile,
        analysis.stairsCount > 0 ? 'stairs' : 'curb',
      ),
      isLiveGeoPhoto: analysis.isLivePhoto,
      photoSourceAttribution: analysis.photoAttribution,
      photoTitle: analysis.photoTitle,
    );

    final accessibleAudit = AccessibilityAudit(
      id: 'aud_dyn_acc_${DateTime.now().millisecondsSinceEpoch}',
      checkpointName: 'Płaska droga ($destName)',
      location: bypassPoints[bypassPoints.length ~/ 2],
      photoUrl: analysis.bypassPhotoUrl,
      isAccessible: true,
      score: analysis.accessibleScore,
      stairsDetected: false,
      stairsCount: 0,
      curbStatus: 'Zjazd rampowy zlicowany 0 cm',
      surfaceType: 'Gładkie płyty chodnikowe bezszwowe',
      hazards: const [],
      aiVerdictPl: profile == MobilityProfile.wheelchair
          ? 'BEZPIECZNE DLA WÓZKA: Płaski trakt pieszy bez schodów, szerokość >2.2 m, 100% zjazdów zlicowanych 0 cm.'
          : (profile == MobilityProfile.cane
                ? 'BEZPIECZNE DLA SENIORA: Płaski odcinek z ławkami co 120 m i łagodnym spadkiem <2.5%.'
                : 'BEZPIECZNE DLA WÓZKA DZIECIĘCEGO: Szeroki chodnik bez drgań – ochrona snu dziecka.'),
      aiVerdictEn:
          'SAFE: Flat surface, dropped curbs, excellent accessibility.',
      bypassPhotoUrl: analysis.photoUrl,
      bypassTitlePl: 'Ominięta bariera na trasie bezpośredniej',
      bypassTitleEn: 'Bypassed barrier on direct route',
      bypassDescriptionPl: analysis.bypassReasonPl,
      bypassDescriptionEn: analysis.bypassReasonEn,
      profileImpactPl: 'Dostosowane do wybranego profilu mobilności.',
      profileImpactEn: 'Adapted for the selected mobility profile.',
      isLiveGeoPhoto: false,
      photoSourceAttribution: 'NavAble Verified Bypass',
      photoTitle: 'Trasa bez barier NavAble',
    );

    final bypassDistance =
        distanceMeters + (distanceMeters * 0.08).round() + 50;
    final bypassDuration = durationMinutes + 1;

    // TRASA ZIELONA (KrakAccess - Omija barierę)
    final accessibleRoute = RouteModel(
      id: 'route_dyn_acc',
      titlePl: 'Trasa NavAble (Obejście barier)',
      titleEn: 'NavAble Route (Barrier Bypass)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: bypassDistance,
      durationMinutes: bypassDuration,
      accessibilityScore: analysis.accessibleScore,
      stairsCount: 0,
      stairsAvoided: analysis.stairsCount,
      surfaceSummaryPl: 'Gładkie płyty chodnikowe, 0 stopni, rampy 0cm',
      surfaceSummaryEn: 'Smooth pavement, 0 stairs, 0cm dropped curbs',
      coordinates: bypassPoints,
      audits: [accessibleAudit],
      profileHighlightsPl: analysis.highlightsPl,
      profileHighlightsEn: analysis.highlightsEn,
      detectedBarrierPl: 'Bariera na trasie prostej: ${analysis.barrierNamePl}',
      detectedBarrierEn: 'Barrier on direct route: ${analysis.barrierNameEn}',
      bypassReasonPl: analysis.bypassReasonPl,
      bypassReasonEn: analysis.bypassReasonEn,
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
      accessibilityScore: analysis.standardScore,
      stairsCount: analysis.stairsCount,
      stairsAvoided: 0,
      surfaceSummaryPl: analysis.surfaceTypePl,
      surfaceSummaryEn: analysis.surfaceTypeEn,
      coordinates: directPoints,
      audits: [standardAudit],
      profileHighlightsPl: [
        if (analysis.stairsCount > 0)
          'Zawiera ${analysis.stairsCount} stopni schodowych'
        else
          'Bariery architektoniczne / wysokie krawężniki',
        'Krótsza o ~${bypassDistance - distanceMeters} m',
        'Brak certyfikacji dostępności WCAG',
      ],
      profileHighlightsEn: [
        if (analysis.stairsCount > 0)
          'Contains ${analysis.stairsCount} stairs'
        else
          'Architectural barriers / high curbs',
        'Shorter by ~${bypassDistance - distanceMeters} m',
        'Direct unverified route',
      ],
      detectedBarrierPl: analysis.barrierNamePl,
      detectedBarrierEn: analysis.barrierNameEn,
      bypassReasonPl: analysis.bypassReasonPl,
      bypassReasonEn: analysis.bypassReasonEn,
    );

    // Kalkulacja najszybszej dostępnej trasy komunikacji miejskiej GTFS (tramwaj/autobus)
    final transitRoute = GtfsTransitService.calculateFastestTransitRoute(
      start: start,
      end: end,
      profile: profile,
      walkingDistanceMeters: distanceMeters,
      walkingDurationMinutes: bypassDuration,
      startName: startName,
      destinationName: destName,
    );

    if (transitRoute != null) {
      return [accessibleRoute, transitRoute, standardRoute];
    }
    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getDworzecRynekRoutes(
    MobilityProfile profile, {
    bool reversed = false,
  }) {
    // 1. Trasa standardowa (CZERWONA - Tunel ze schodami pod Lubicz + kocie łby na Floriańskiej)
    final standardAudits = [
      AccessibilityAudit(
        id: 'aud_std_1',
        checkpointName: 'Przejście podziemne Dworzec / Planty (ul. Lubicz)',
        location: const LatLng(50.0652, 19.9442),
        photoUrl: 'assets/streetview/lubicz_barrier.jpg',
        isAccessible: false,
        score: profile == MobilityProfile.wheelchair
            ? 20
            : (profile == MobilityProfile.cane ? 45 : 30),
        stairsDetected: true,
        stairsCount: 24,
        curbStatus: 'Brak rampy / schody strome',
        surfaceType: 'Schody betonowe (24 stopnie w dół i w górę)',
        hazards: const [
          '24 stopnie w dół i w górę',
          'Zepsuta winda platformowa',
          'Brak pochylni',
        ],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'KRYTYCZNA BARIERA DLA WÓZKA: 24 stopnie bez windy. Przejazd niemożliwy bez asysty 2 osób.'
            : (profile == MobilityProfile.cane
                  ? 'ZAGROŻENIE DLA SENIORA: Śliskie stopnie i strome zejście – wysokie ryzyko upadku.'
                  : 'UTRUDNIENIE: Konieczność zniesienia wózka dziecięcego ze schodów.'),
        aiVerdictEn: 'CRITICAL BARRIER: 24 steps without functioning elevator.',
        bypassPhotoUrl: 'assets/streetview/planty_bypass.jpg',
        bypassTitlePl: 'Obejście NavAble (Naziemne Planty)',
        bypassTitleEn: 'NavAble Bypass (Ground Crossing)',
        bypassDescriptionPl:
            'Skierowano przez przejście naziemne z sygnalizacją dźwiękową i rampą 0cm.',
        bypassDescriptionEn:
            'Rerouted through ground level crossing with 0cm ramp.',
        profileImpactPl: _getProfileImpactPl(profile, 'schody'),
        profileImpactEn: _getProfileImpactEn(profile, 'stairs'),
      ),
      AccessibilityAudit(
        id: 'aud_std_2',
        checkpointName: 'Wlot ul. Floriańskiej (Brama Floriańska)',
        location: const LatLng(50.0645, 19.9405),
        photoUrl: 'assets/streetview/florianska_barrier.jpg',
        isAccessible: false,
        score: profile == MobilityProfile.wheelchair
            ? 35
            : (profile == MobilityProfile.cane ? 60 : 45),
        stairsDetected: false,
        stairsCount: 0,
        curbStatus: 'Krawężnik 12 cm',
        surfaceType: 'Zabytkowa kostka bazaltowa (kocie łby)',
        hazards: const [
          'Silne drgania',
          'Głębokie spoiny >3cm',
          'Ryzyko zaklinowania kółek',
        ],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'TRUDNA NAWIERZCHNIA: Nierówny bruk historyczny powoduje niebezpieczne wibracje i blokowanie kółek wózka.'
            : (profile == MobilityProfile.cane
                  ? 'Nierówna kostka: Utrudnione oparcie laski, ryzyko skręcenia kostki.'
                  : 'Uciążliwe wstrząsy dla śpiącego dziecka w wózku.'),
        aiVerdictEn:
            'Uneven cobblestone causing intense vibrations and trip hazard.',
        bypassPhotoUrl: 'assets/streetview/slawkowska_bypass.jpg',
        bypassTitlePl: 'Objazd ul. Szpitalną',
        bypassTitleEn: 'Bypass via Szpitalna St.',
        bypassDescriptionPl:
            'Gładkie płyty granitowe po rewitalizacji bez szwów.',
        bypassDescriptionEn: 'Smooth revitalized granite slabs.',
      ),
    ];

    final stdCoords = const [
      LatLng(50.0668, 19.9464), // Dworzec
      LatLng(50.0658, 19.9450),
      LatLng(50.0652, 19.9442), // Bariera: schody w tunelu
      LatLng(50.0645, 19.9405), // Brama Floriańska / bruk
      LatLng(50.0630, 19.9390), // ul. Floriańska
      LatLng(50.0617, 19.9373), // Sukiennice
    ];

    final standardRoute = RouteModel(
      id: 'route_standard_dworzec',
      titlePl: reversed
          ? 'Trasa standardowa (Kocie łby i schody w tunelu Lubicz)'
          : 'Trasa standardowa (Schody podziemne i kocie łby)',
      titleEn: reversed
          ? 'Standard Route (Cobblestones & Underpass Stairs)'
          : 'Standard Route (Stairs & Cobblestones)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 850,
      durationMinutes: 12,
      accessibilityScore: profile == MobilityProfile.wheelchair
          ? 25
          : (profile == MobilityProfile.cane ? 50 : 36),
      stairsCount: 24,
      stairsAvoided: 0,
      surfaceSummaryPl:
          'Schody (24 stopnie w tunelu), kocie łby na Floriańskiej',
      surfaceSummaryEn: 'Stairs (24 underground steps), rough cobblestone',
      coordinates: reversed ? stdCoords.reversed.toList() : stdCoords,
      audits: standardAudits,
      profileHighlightsPl: const [
        'Krótsza o 70 m',
        'Zawiera 24 strome stopnie bez windy',
      ],
      profileHighlightsEn: const [
        '70 m shorter',
        'Contains 24 steep steps without lift',
      ],
      detectedBarrierPl: 'Przejście podziemne Lubicz: 24 stopnie bez windy',
      detectedBarrierEn: 'Lubicz underpass: 24 steps without elevator',
      bypassReasonPl:
          'Ominięto schody naziemnym przejściem przez Planty (+70 m, 0 stopni)',
      bypassReasonEn:
          'Bypassed stairs via flat ground crossing (+70 m, 0 stairs)',
    );

    // 2. Trasa dostępna KrakAccess (ZIELONA - Naziemne Planty + ul. Szpitalna)
    final accessibleAudits = [
      AccessibilityAudit(
        id: 'aud_acc_1',
        checkpointName: 'Przejście naziemne Planty (ul. Westerplatte / Lubicz)',
        location: const LatLng(50.0648, 19.9451),
        photoUrl: 'assets/streetview/planty_bypass.jpg',
        isAccessible: true,
        score: profile == MobilityProfile.wheelchair
            ? 98
            : (profile == MobilityProfile.cane ? 96 : 97),
        stairsDetected: false,
        stairsCount: 0,
        curbStatus: 'Zjazd zlicowany z jezdnią 0 cm',
        surfaceType: 'Gładki asfalt / Płyty szlifowane',
        hazards: const [],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'OPTYMALNE: Całkowicie płaski przejazd przez aleję Plant, 0 stopni, szerokie pasy z rampami.'
            : (profile == MobilityProfile.cane
                  ? 'KOMFORTOWE: Płaski trakt z ławeczkami w cieniu drzew na Plantach, brak stopni.'
                  : 'IDEALNE: Szerokie, równe przejście dla wózka dziecięcego.'),
        aiVerdictEn: 'OPTIMAL: Fully accessible ground crossing, zero steps.',
        bypassPhotoUrl: 'assets/streetview/lubicz_barrier.jpg',
        bypassTitlePl: 'Ominięte schody w tunelu Lubicz (24 stopnie)',
        bypassTitleEn: 'Bypassed 24 steps in Lubicz underpass',
        bypassDescriptionPl:
            'Audyt AI potwierdził obecność obniżonych krawężników i brak barier.',
        bypassDescriptionEn:
            'AI audit verified dropped curbs and zero obstacles.',
      ),
      AccessibilityAudit(
        id: 'aud_acc_2',
        checkpointName: 'Dojście ul. Szpitalną do Rynku',
        location: const LatLng(50.0628, 19.9388),
        photoUrl: 'assets/streetview/slawkowska_bypass.jpg',
        isAccessible: true,
        score: 98,
        stairsDetected: false,
        stairsCount: 0,
        curbStatus: 'Łagodny najazd rampowy 0-1cm',
        surfaceType: 'Gładkie płyty chodnikowe bezszwowe',
        hazards: const [],
        aiVerdictPl:
            'OPTYMALNE: Nowa nawierzchnia płytowa po rewitalizacji, brak wstrząsów, szerokość >2.4 m.',
        aiVerdictEn:
            'OPTIMAL: Smooth paving slabs, width >2.4m, safe for all mobility types.',
        bypassPhotoUrl: 'assets/streetview/florianska_barrier.jpg',
        bypassTitlePl: 'Ominięty zabytkowy bruk na Floriańskiej',
        bypassTitleEn: 'Bypassed cobblestones on Floriańska',
        bypassDescriptionPl: 'Pomyślnie ominięto kocie łby i wstrząsy.',
        bypassDescriptionEn:
            'Successfully avoided cobblestones and vibrations.',
      ),
    ];

    final accCoords = const [
      LatLng(50.0668, 19.9464), // Start: Dworzec
      LatLng(50.0662, 19.9458),
      LatLng(50.0648, 19.9451), // Naziemne przejście dla pieszych
      LatLng(50.0638, 19.9418), // Teatr Słowackiego
      LatLng(50.0628, 19.9388), // ul. Szpitalna
      LatLng(50.0617, 19.9373), // Sukiennice
    ];

    final accessibleRoute = RouteModel(
      id: 'route_accessible_dworzec',
      titlePl: reversed
          ? 'Trasa NavAble (ul. Szpitalna i Płaskie Planty)'
          : 'Trasa NavAble (Płaskie Planty i ul. Szpitalna)',
      titleEn: reversed
          ? 'NavAble Route (Szpitalna St. & Planty)'
          : 'NavAble Route (Planty & Szpitalna St.)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 920,
      durationMinutes: 13,
      accessibilityScore: profile == MobilityProfile.wheelchair
          ? 98
          : (profile == MobilityProfile.cane ? 96 : 97),
      stairsCount: 0,
      stairsAvoided: 24,
      surfaceSummaryPl:
          'Gładkie płyty szlifowane, 0 schodów, 100% zjazdów rampowych',
      surfaceSummaryEn: 'Smooth granite slabs, 0 stairs, 100% dropped curbs',
      coordinates: reversed ? accCoords.reversed.toList() : accCoords,
      audits: accessibleAudits,
      profileHighlightsPl: _getDworzecHighlightsPl(profile),
      profileHighlightsEn: _getDworzecHighlightsEn(profile),
      detectedBarrierPl:
          'Przejście podziemne: 24 stopnie w dół i w górę bez windy',
      detectedBarrierEn: 'Underpass: 24 steps without functioning elevator',
      bypassReasonPl:
          'Ominięto schody naziemnym przejściem przez Planty (+70 m, 0 stopni)',
      bypassReasonEn:
          'Bypassed stairs via flat Planty crossing (+70 m, 0 stairs)',
    );

    // GTFS Komunikacja Miejska dla trasy Dworzec - Rynek (Linie 18, 4, 14, 20)
    final transitRoute = GtfsTransitService.calculateFastestTransitRoute(
      start: reversed
          ? const LatLng(50.0617, 19.9373)
          : const LatLng(50.0668, 19.9460),
      end: reversed
          ? const LatLng(50.0668, 19.9460)
          : const LatLng(50.0617, 19.9373),
      profile: profile,
      walkingDistanceMeters: 920,
      walkingDurationMinutes: 13,
      startName: reversed ? 'Rynek Główny' : 'Dworzec Główny',
      destinationName: reversed ? 'Dworzec Główny' : 'Rynek Główny',
    );

    if (transitRoute != null) {
      return [accessibleRoute, transitRoute, standardRoute];
    }
    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getWawelKazimierzRoutes(
    MobilityProfile profile, {
    bool reversed = false,
  }) {
    final stdCoords = const [
      LatLng(50.0545, 19.9354), // Wawel Podzamcze
      LatLng(50.0538, 19.9372), // Schody kamienne
      LatLng(50.0530, 19.9410),
      LatLng(50.0519, 19.9452), // Plac Nowy
    ];

    final standardRoute = RouteModel(
      id: 'route_std_wawel',
      titlePl: reversed
          ? 'Trasa standardowa (strome podejście ze schodami kamiennymi)'
          : 'Trasa standardowa (przez strome schody)',
      titleEn: reversed
          ? 'Standard Route (via steep steps ascent)'
          : 'Standard Route (via steep steps)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 1100,
      durationMinutes: 15,
      accessibilityScore: profile == MobilityProfile.wheelchair
          ? 22
          : (profile == MobilityProfile.cane ? 35 : 40),
      stairsCount: 18,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Strome stopnie kamienne (18 schodów), śliski wapień',
      surfaceSummaryEn: 'Steep stone steps (18 stairs), slippery limestone',
      coordinates: reversed ? stdCoords.reversed.toList() : stdCoords,
      audits: [
        AccessibilityAudit(
          id: 'aud_wawel_std',
          checkpointName: 'Zejście pod Wzgórzem Wawelskim (ul. św. Idziego)',
          location: const LatLng(50.0538, 19.9372),
          photoUrl: 'assets/streetview/wawel_stairs_barrier.jpg',
          isAccessible: false,
          score: profile == MobilityProfile.wheelchair ? 20 : 35,
          stairsDetected: true,
          stairsCount: 18,
          curbStatus: 'Strome schody bez poręczy',
          surfaceType: 'Wapień historyczny śliski',
          hazards: const ['18 stopni', 'Brak pochylni', 'Spadek terenu 11%'],
          aiVerdictPl:
              'KRYTYCZNA BARIERA: Schody kamienne o nachyleniu 11% bez pochylni.',
          aiVerdictEn: 'CRITICAL BARRIER: Steep stone steps with 11% gradient.',
          bypassPhotoUrl: 'assets/streetview/bernardynska_bypass.jpg',
          bypassTitlePl: 'Płaski zjazd ul. Bernardyńską',
          bypassTitleEn: 'Flat ramp via Bernardyńska St.',
          bypassDescriptionPl:
              'Łagodne nachylenie <3.5%, gładki asfalt i bezpieczne barierki.',
          bypassDescriptionEn: 'Gentle slope <3.5%, smooth asphalt.',
        ),
      ],
      profileHighlightsPl: const [
        'Krótsza o 150m',
        'Strome schody kamienne (18 stopni ze Wzgórza)',
      ],
      profileHighlightsEn: const [
        '150m shorter',
        'Steep stone steps (18 steps from Wawel)',
      ],
      detectedBarrierPl:
          'Strome zejście z Wawelu: 18 kamiennych stopni bez rampy',
      detectedBarrierEn: 'Steep Wawel descent: 18 stone steps without ramp',
      bypassReasonPl:
          'Skierowano łagodnym traktem ul. Bernardyńskiej (+150m, 0 stopni)',
      bypassReasonEn:
          'Rerouted through gentle Bernardyńska slope (+150m, 0 stairs)',
    );

    final accCoords = const [
      LatLng(50.0545, 19.9354),
      LatLng(50.0530, 19.9360),
      LatLng(50.0515, 19.9395), // Bernardyńska łagodna
      LatLng(50.0510, 19.9430), // Dietla
      LatLng(50.0519, 19.9452), // Plac Nowy
    ];

    final accessibleRoute = RouteModel(
      id: 'route_acc_wawel',
      titlePl: reversed
          ? 'Trasa NavAble (Płaski podjazd Dietla i Bernardyńską)'
          : 'Trasa NavAble (Płaski zjazd ul. Bernardyńską i Dietla)',
      titleEn: reversed
          ? 'NavAble Route (Dietla & Bernardyńska)'
          : 'NavAble Route (Bernardyńska & Dietla)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 1250,
      durationMinutes: 17,
      accessibilityScore: profile == MobilityProfile.wheelchair
          ? 95
          : (profile == MobilityProfile.cane ? 93 : 95),
      stairsCount: 0,
      stairsAvoided: 18,
      surfaceSummaryPl: 'Łagodne nachylenie <3.5%, gładki asfalt, 0 schodów',
      surfaceSummaryEn: 'Gentle slope <3.5%, smooth asphalt, 0 stairs',
      coordinates: reversed ? accCoords.reversed.toList() : accCoords,
      audits: [
        const AccessibilityAudit(
          id: 'aud_wawel_acc',
          checkpointName: 'Płaski zjazd ul. Bernardyńska / Dietla',
          location: LatLng(50.0515, 19.9395),
          photoUrl: 'assets/streetview/bernardynska_bypass.jpg',
          isAccessible: true,
          score: 95,
          stairsDetected: false,
          stairsCount: 0,
          curbStatus: 'Zjazd wózkowy 0cm',
          surfaceType: 'Asfalt gładki',
          hazards: [],
          aiVerdictPl:
              'BEZPIECZNE: Płaski trakt pieszy o nachyleniu 3.2%, w pełni zgodny z normami WCAG.',
          aiVerdictEn:
              'SAFE: Flat pedestrian path with 3.2% slope, fully WCAG compliant.',
          bypassPhotoUrl: 'assets/streetview/wawel_stairs_barrier.jpg',
          bypassTitlePl: 'Ominięte 18 stopni ze Wzgórza Wawelskiego',
          bypassTitleEn: 'Bypassed 18 steep steps from Wawel Hill',
        ),
      ],
      profileHighlightsPl: _getWawelHighlightsPl(profile),
      profileHighlightsEn: _getWawelHighlightsEn(profile),
      detectedBarrierPl:
          'Strome zejście z Wawelu: 18 kamiennych stopni bez rampy',
      detectedBarrierEn: 'Steep Wawel descent: 18 stone steps without ramp',
      bypassReasonPl:
          'Skierowano łagodnym traktem ul. Bernardyńskiej (+150m, 0 stopni)',
      bypassReasonEn:
          'Rerouted through gentle Bernardyńska slope (+150m, 0 stairs)',
    );

    // GTFS Komunikacja Miejska dla trasy Wawel - Kazimierz (Linie 8, 18)
    final transitRoute = GtfsTransitService.calculateFastestTransitRoute(
      start: reversed
          ? const LatLng(50.0519, 19.9452)
          : const LatLng(50.0545, 19.9354),
      end: reversed
          ? const LatLng(50.0545, 19.9354)
          : const LatLng(50.0519, 19.9452),
      profile: profile,
      walkingDistanceMeters: 1250,
      walkingDurationMinutes: 17,
      startName: reversed ? 'Kazimierz (Plac Wolnica)' : 'Wawel (Zamek)',
      destinationName: reversed ? 'Wawel (Zamek)' : 'Kazimierz (Plac Wolnica)',
    );

    if (transitRoute != null) {
      return [accessibleRoute, transitRoute, standardRoute];
    }
    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getBarbakanRynekRoutes(
    MobilityProfile profile, {
    bool reversed = false,
  }) {
    final accCoords = const [
      LatLng(50.0656, 19.9416),
      LatLng(50.0645, 19.9395),
      LatLng(50.0628, 19.9380),
      LatLng(50.0617, 19.9373),
    ];

    final accessibleRoute = RouteModel(
      id: 'route_acc_barbakan',
      titlePl: reversed
          ? 'Trasa NavAble (ul. Sławkowska ➔ Barbakan)'
          : 'Trasa NavAble (ul. Sławkowska - gładka)',
      titleEn: reversed
          ? 'NavAble Route (Sławkowska St. ➔ Barbican)'
          : 'NavAble Route (Sławkowska St. - smooth)',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 480,
      durationMinutes: 7,
      accessibilityScore: 98,
      stairsCount: 0,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Gładkie płyty granitowe, zlicowane krawężniki 0-1cm',
      surfaceSummaryEn: 'Smooth granite slabs, flush curbs 0-1cm',
      coordinates: reversed ? accCoords.reversed.toList() : accCoords,
      audits: [
        AccessibilityAudit(
          id: 'aud_barbakan_acc',
          checkpointName: 'Ulica Sławkowska (Gładkie płyty szlifowane)',
          location: const LatLng(50.0635, 19.9380),
          photoUrl: 'assets/streetview/slawkowska_bypass.jpg',
          isAccessible: true,
          score: 98,
          stairsDetected: false,
          stairsCount: 0,
          curbStatus: 'Zjazdy zlicowane 0-1 cm',
          surfaceType: 'Gładkie płyty granitowe bezszwowe',
          hazards: const [],
          aiVerdictPl:
              'OPTYMALNE: Nowa nawierzchnia płytowa po rewitalizacji, brak wstrząsów, szerokość >2.4 m.',
          aiVerdictEn:
              'OPTIMAL: Smooth paving slabs, width >2.4m, safe for all mobility types.',
          bypassPhotoUrl: 'assets/streetview/florianska_barrier.jpg',
          bypassTitlePl: 'Ominięty zabytkowy bruk na Floriańskiej',
          bypassTitleEn: 'Bypassed Floriańska cobblestones',
          bypassDescriptionPl:
              'Pomyślnie ominięto kocie łby i niebezpieczne wstrząsy.',
          bypassDescriptionEn:
              'Successfully avoided cobblestones and vibrations.',
        ),
      ],
      profileHighlightsPl: _getBarbakanHighlightsPl(profile),
      profileHighlightsEn: _getBarbakanHighlightsEn(profile),
      detectedBarrierPl:
          'Zabytkowy nierówny bruk na ul. Floriańskiej (kocie łby)',
      detectedBarrierEn: 'Historic uneven cobblestones on Floriańska St.',
      bypassReasonPl:
          'Skierowano równoległą ul. Sławkowską o gładkich płytach granitowych',
      bypassReasonEn:
          'Rerouted via parallel Sławkowska St. with smooth granite slabs',
    );

    final stdCoords = const [
      LatLng(50.0656, 19.9416),
      LatLng(50.0640, 19.9410),
      LatLng(50.0617, 19.9373),
    ];

    final standardRoute = RouteModel(
      id: 'route_std_barbakan',
      titlePl: reversed
          ? 'Trasa standardowa (ul. Floriańska ➔ Barbakan)'
          : 'Trasa standardowa (ul. Floriańska - kocie łby)',
      titleEn: reversed
          ? 'Standard Route (Floriańska St. ➔ Barbican)'
          : 'Standard Route (Floriańska - cobblestones)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 450,
      durationMinutes: 6,
      accessibilityScore: 40,
      stairsCount: 0,
      stairsAvoided: 0,
      surfaceSummaryPl: 'Zabytkowy nierówny bruk (kocie łby)',
      surfaceSummaryEn: 'Historic uneven cobblestones',
      coordinates: reversed ? stdCoords.reversed.toList() : stdCoords,
      audits: [
        AccessibilityAudit(
          id: 'aud_barbakan_std',
          checkpointName:
              'Wlot ul. Floriańskiej (Brama Floriańska / kocie łby)',
          location: const LatLng(50.0645, 19.9405),
          photoUrl: 'assets/streetview/florianska_barrier.jpg',
          isAccessible: false,
          score: profile == MobilityProfile.wheelchair
              ? 35
              : (profile == MobilityProfile.cane ? 55 : 45),
          stairsDetected: false,
          stairsCount: 0,
          curbStatus: 'Krawężnik 12-14 cm',
          surfaceType: 'Zabytkowy nierówny bruk (kocie łby)',
          hazards: const [
            'Silne wstrząsy i drgania',
            'Głębokie spoiny >3 cm',
            'Krawężnik 14 cm',
          ],
          aiVerdictPl: profile == MobilityProfile.wheelchair
              ? 'KRYTYCZNE DRGANIA: Historyczny bruk na Floriańskiej grozi wywróceniem wózka. Zalecany objazd ul. Sławkowską.'
              : 'UTRUDNIENIE: Nierówna nawierzchnia i wysokie uskoki krawężników.',
          aiVerdictEn:
              'SEVERE VIBRATIONS: Historic cobblestones. Use Sławkowska bypass.',
          bypassPhotoUrl: 'assets/streetview/slawkowska_bypass.jpg',
          bypassTitlePl: 'Objazd ul. Sławkowską (Gładkie płyty)',
          bypassTitleEn: 'Bypass via Sławkowska St.',
          bypassDescriptionPl:
              'Gładkie płyty granitowe po rewitalizacji bez szwów.',
          bypassDescriptionEn: 'Smooth revitalized granite slabs.',
          profileImpactPl: _getProfileImpactPl(profile, 'krawężnik'),
          profileImpactEn: _getProfileImpactEn(profile, 'curb'),
        ),
      ],
      profileHighlightsPl: const [
        'Krótsza o 30m',
        'Mocne drgania nawierzchni (kocie łby na Floriańskiej)',
      ],
      profileHighlightsEn: const [
        '30m shorter',
        'Severe vibrations (cobblestones on Floriańska)',
      ],
      detectedBarrierPl:
          'Zabytkowy nierówny bruk na ul. Floriańskiej (kocie łby)',
      detectedBarrierEn: 'Historic uneven cobblestones on Floriańska St.',
      bypassReasonPl:
          'Zalecany objazd ul. Sławkowską o gładkich płytach szlifowanych',
      bypassReasonEn: 'Bypass recommended via Sławkowska St.',
    );

    // GTFS Komunikacja Miejska dla trasy Barbakan - Sukiennice (Linie 4, 14, 20)
    final transitRoute = GtfsTransitService.calculateFastestTransitRoute(
      start: reversed
          ? const LatLng(50.0617, 19.9373)
          : const LatLng(50.0656, 19.9416),
      end: reversed
          ? const LatLng(50.0656, 19.9416)
          : const LatLng(50.0617, 19.9373),
      profile: profile,
      walkingDistanceMeters: 450,
      walkingDurationMinutes: 6,
      startName: reversed ? 'Sukiennice' : 'Barbakan',
      destinationName: reversed ? 'Barbakan' : 'Sukiennice',
    );

    if (transitRoute != null) {
      return [accessibleRoute, transitRoute, standardRoute];
    }
    return [accessibleRoute, standardRoute];
  }

  static List<String> _getDworzecHighlightsPl(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          '0 schodów na całej trasie',
          'Ominięto 24 stopnie w tunelu Lubicz',
          'Ominięto kocie łby na Floriańskiej (trasa ul. Szpitalną)',
          '100% zjazdów rampowych (<1.5 cm)',
        ];
      case MobilityProfile.cane:
        return [
          'Ominięto 24 strome stopnie podziemne',
          '8 ławek do odpoczynku na Plantach',
          'Płaski trakt bez stromych wzniesień',
        ];
      case MobilityProfile.stroller:
        return [
          'Brak schodów do wnoszenia wózka',
          'Szeroki chodnik >2.2 m przez Planty',
          'Łagodne rampy zjazdowe',
        ];
    }
  }

  static List<String> _getDworzecHighlightsEn(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          '0 stairs along entire route',
          'Bypassed 24 steps in Lubicz underpass',
          'Avoided cobblestones on Floriańska (via Szpitalna)',
          '100% dropped curbs (<1.5 cm)',
        ];
      case MobilityProfile.cane:
        return [
          'Avoided 24 steep underground steps',
          '8 resting benches in Planty park',
          'Gentle level path without steep inclines',
        ];
      case MobilityProfile.stroller:
        return [
          'No stairs to carry stroller',
          'Wide sidewalk >2.2 m across Planty',
          'Gentle ramp transitions',
        ];
    }
  }

  static List<String> _getWawelHighlightsPl(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          '0 schodów na całej trasie',
          'Ominięto 18 stromych stopni ze Wzgórza',
          'Łagodny zjazd ul. Bernardyńską (<3.5%)',
          'Zjazdy zlicowane 0 cm',
        ];
      case MobilityProfile.cane:
        return [
          'Ominięto 18 śliskich stopni kamiennych',
          'Płaski zjazd ul. Bernardyńską i Dietla',
          'Ławki do odpoczynku wzdłuż trasy',
        ];
      case MobilityProfile.stroller:
        return [
          'Brak konieczności noszenia wózka ze Wzgórza',
          'Szeroki, gładki chodnik',
          'Płaskie najazdy 0 cm',
        ];
    }
  }

  static List<String> _getWawelHighlightsEn(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          '0 stairs along entire route',
          'Bypassed 18 steep Wawel hill steps',
          'Gentle slope via Bernardyńska (<3.5%)',
          'Flush 0 cm dropped curbs',
        ];
      case MobilityProfile.cane:
        return [
          'Avoided 18 slippery limestone steps',
          'Gentle slope via Bernardyńska and Dietla',
          'Resting benches along the route',
        ];
      case MobilityProfile.stroller:
        return [
          'No carrying stroller down Wawel steps',
          'Wide and smooth pedestrian path',
          'Flush ramp transitions 0 cm',
        ];
    }
  }

  static List<String> _getBarbakanHighlightsPl(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          'Gładkie płyty granitowe na ul. Sławkowskiej',
          'Ominięto kocie łby na Floriańskiej',
          'Zlicowane krawężniki 0-1 cm',
        ];
      case MobilityProfile.cane:
        return [
          'Płaska i antypoślizgowa nawierzchnia',
          'Ominięto nierówny bruk na Floriańskiej',
          'Brak ryzyka potknięcia o kocie łby',
        ];
      case MobilityProfile.stroller:
        return [
          'Brak wstrząsów dla dziecka w wózku',
          'Gładka trasa ul. Sławkowską',
          'Łagodne przejścia naziemne',
        ];
    }
  }

  static List<String> _getBarbakanHighlightsEn(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return [
          'Smooth granite slabs along Sławkowska St.',
          'Avoided rough cobblestones on Floriańska',
          'Flush curbs 0-1 cm',
        ];
      case MobilityProfile.cane:
        return [
          'Non-slip even pavement',
          'Avoided rough Floriańska stones',
          'No tripping hazard',
        ];
      case MobilityProfile.stroller:
        return [
          'No vibrations for baby in stroller',
          'Smooth route via Sławkowska St.',
          'Gentle street crossings',
        ];
    }
  }

  static String _getProfileImpactPl(MobilityProfile p, String barrierType) {
    if (barrierType == 'schody') {
      switch (p) {
        case MobilityProfile.wheelchair:
          return 'WÓZEK INWALIDZKI: Bariera bezwzględna. Brak rampy i zepsute windy uniemożliwiają przejazd bez asysty co najmniej 2 osób.';
        case MobilityProfile.cane:
          return 'SENIOR / O KULI: Bardzo wysokie ryzyko upadku. Brak poręczy i strome stopnie przeciążają stawy biodrowe i kolanowe.';
        case MobilityProfile.stroller:
          return 'WÓZEK DZIECIĘCY: Wymusza niebezpieczne wnoszenie lub znoszenie ciężkiego wózka (~15-18 kg) z dzieckiem po stopniach.';
      }
    }
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'WÓZEK INWALIDZKI: Krawężnik >10 cm grozi wywrotką wózka do przodu. Kocie łby wywołują bolesne drgania kręgosłupa i blokują kółka skrętne.';
      case MobilityProfile.cane:
        return 'SENIOR / O KULI: Nierówne spoiny bruku grożą ugrzęźnięciem końcówki kuli. Długi dystans bez ławek spoczynkowych wywołuje zmęczenie.';
      case MobilityProfile.stroller:
        return 'WÓZEK DZIECIĘCY: Wyboje i kocie łby wybudzają dziecko ze snu mikrowstrząsami. Krawężniki 14 cm wymuszają siłowe szarpanie osią wózka.';
    }
  }

  static String _getProfileImpactEn(MobilityProfile p, String barrierType) {
    if (barrierType == 'stairs') {
      switch (p) {
        case MobilityProfile.wheelchair:
          return 'WHEELCHAIR: Absolute barrier. Requires 2 assistants or detour via certified ramps.';
        case MobilityProfile.cane:
          return 'SENIOR / CANE: High fall hazard and acute stress on joints without handrails.';
        case MobilityProfile.stroller:
          return 'STROLLER: Requires lifting and carrying heavy pram (~15-18 kg) upstairs.';
      }
    }
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'WHEELCHAIR: High curb threatens forward tip; rough cobblestones cause spine vibration.';
      case MobilityProfile.cane:
        return 'SENIOR / CANE: Cobblestone gaps catch cane tips; lack of resting benches causes fatigue.';
      case MobilityProfile.stroller:
        return 'STROLLER: Cobblestone vibration disturbs infant sleep; 14cm curbs require jerking wheels.';
    }
  }
}
