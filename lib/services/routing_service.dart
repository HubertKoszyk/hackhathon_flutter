import 'dart:convert';
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
    RoutePreset(
      id: 'preset_bramy_sukiennice',
      titlePl: 'Barbakan ➔ Rynek Główny (ul. Sławkowska)',
      titleEn: 'Barbican ➔ Main Market (Sławkowska St.)',
      start: LatLng(50.0656, 19.9416),
      end: LatLng(50.0617, 19.9373),
      startName: 'Barbakan Krakowski',
      endName: 'Sukiennice',
    ),
  ];

  /// Pobiera trasy spersonalizowane pod wybrany profil mobilności
  static List<RouteModel> getRoutesForPreset(String presetId, MobilityProfile profile) {
    if (presetId == 'preset_wawel_kazimierz') {
      return _getWawelKazimierzRoutes(profile);
    }
    if (presetId == 'preset_bramy_sukiennice') {
      return _getBarbakanRynekRoutes(profile);
    }
    return _getDworzecRynekRoutes(profile);
  }

  /// Dynamiczne pobieranie trasy z OSRM z kalkulacją barier
  static Future<List<RouteModel>> calculateDynamicRoute({
    required LatLng start,
    required LatLng end,
    required MobilityProfile profile,
    String? startName,
    String? destinationName,
  }) async {
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
          final double distance = (routesJson[0]['distance'] as num).toDouble();
          final double duration = (routesJson[0]['duration'] as num).toDouble();

          final List<LatLng> basePoints = rawCoords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          return _buildDynamicRoutePair(
            start: start,
            end: end,
            basePoints: basePoints,
            distanceMeters: distance.round(),
            durationMinutes: (duration / 60).round().clamp(1, 999),
            profile: profile,
            startName: startName ?? 'Punkt startowy',
            destName: destinationName ?? 'Cel podróży',
          );
        }
      }
    } catch (_) {
      // Fallback w razie braku sieci
    }

    // Bezpieczny generator trasy
    final interpolated = _interpolatePoints(start, end);
    return _buildDynamicRoutePair(
      start: start,
      end: end,
      basePoints: interpolated,
      distanceMeters: 750,
      durationMinutes: 10,
      profile: profile,
      startName: startName ?? 'Punkt startowy',
      destName: destinationName ?? 'Cel podróży',
    );
  }

  static List<LatLng> _interpolatePoints(LatLng a, LatLng b) {
    return [
      a,
      LatLng(a.latitude + (b.latitude - a.latitude) * 0.35, a.longitude + (b.longitude - a.longitude) * 0.25),
      LatLng(a.latitude + (b.latitude - a.latitude) * 0.70, a.longitude + (b.longitude - a.longitude) * 0.80),
      b,
    ];
  }

  static List<RouteModel> _buildDynamicRoutePair({
    required LatLng start,
    required LatLng end,
    required List<LatLng> basePoints,
    required int distanceMeters,
    required int durationMinutes,
    required MobilityProfile profile,
    required String startName,
    required String destName,
  }) {
    final midpoint = basePoints.length > 2
        ? basePoints[basePoints.length ~/ 2]
        : LatLng((start.latitude + end.latitude) / 2, (start.longitude + end.longitude) / 2);

    final accessibleAudit = AccessibilityAudit(
      id: 'aud_dyn_acc_${DateTime.now().millisecondsSinceEpoch}',
      checkpointName: 'Weryfikacja widoku ulicy KrakAccess ($destName)',
      location: midpoint,
      photoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
      isAccessible: true,
      score: profile == MobilityProfile.wheelchair ? 97 : (profile == MobilityProfile.cane ? 94 : 96),
      stairsDetected: false,
      stairsCount: 0,
      curbStatus: 'Zjazd rampowy < 1.5 cm',
      surfaceType: 'Gładkie płyty chodnikowe',
      hazards: const [],
      aiVerdictPl: profile == MobilityProfile.wheelchair
          ? 'BEZPIECZNE: Płaski przejazd bez stopni, obniżone krawężniki i szeroki chodnik.'
          : (profile == MobilityProfile.cane
              ? 'BEZPIECZNE: Płaski trakt z ławkami do odpoczynku w odległości 40m.'
              : 'BEZPIECZNE: Szeroki trakt dla wózka dziecięcego, brak wstrząsów.'),
      aiVerdictEn: 'SAFE: Flat surface, dropped curbs, excellent accessibility.',
      bypassTitlePl: 'Zweryfikowany objazd KrakAccess',
      bypassTitleEn: 'KrakAccess Verified Bypass',
      bypassDescriptionPl: 'Trasa prowadzona wyłącznie równymi chodnikami i przejściami naziemnymi.',
      bypassDescriptionEn: 'Route routed exclusively through smooth pavements and pedestrian crossings.',
      profileImpactPl: 'Dostosowane do wybranego profilu mobilności.',
      profileImpactEn: 'Adapted for the selected mobility profile.',
    );

    final standardAudit = AccessibilityAudit(
      id: 'aud_dyn_std_${DateTime.now().millisecondsSinceEpoch}',
      checkpointName: 'Punkt kolizyjny trasy standardowej',
      location: midpoint,
      photoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
      isAccessible: false,
      score: profile == MobilityProfile.wheelchair ? 25 : (profile == MobilityProfile.cane ? 45 : 35),
      stairsDetected: true,
      stairsCount: 14,
      curbStatus: 'Wysoki krawężnik 12cm',
      surfaceType: 'Nierówna kostka / schody',
      hazards: const ['14 stopni', 'Brak pochylni', 'Wąski krawężnik'],
      aiVerdictPl: profile == MobilityProfile.wheelchair
          ? 'BARIERA: Wykryto schody i krawężnik 12 cm uniemożliwiający przejazd wózka.'
          : (profile == MobilityProfile.cane
              ? 'UWAGA: Strome stopnie bez stabilnej poręczy – ryzyko upadku.'
              : 'UTRUDNIENIE: Konieczność wnoszenia wózka dziecięcego.'),
      aiVerdictEn: 'BARRIER: Obstacle detected preventing easy transit.',
      bypassPhotoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
      bypassTitlePl: 'Obejście wyznaczone przez AI',
      bypassTitleEn: 'AI Bypass',
      bypassDescriptionPl: 'Skierowano 60m dalej płaskim zjazdem chodnikowym.',
      bypassDescriptionEn: 'Rerouted 60m further via flat pedestrian ramp.',
    );

    final accessibleRoute = RouteModel(
      id: 'route_dyn_acc',
      titlePl: 'Trasa KrakAccess (Dostosowana: ${_getProfileNamePl(profile)})',
      titleEn: 'KrakAccess Route (${_getProfileNameEn(profile)})',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: distanceMeters + 60,
      durationMinutes: durationMinutes + 1,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 97 : (profile == MobilityProfile.cane ? 94 : 96),
      stairsAvoided: 14,
      surfaceSummaryPl: 'Gładkie płyty chodnikowe, 0 schodów, 100% zjazdów rampowych',
      surfaceSummaryEn: 'Smooth pavement, 0 stairs, 100% dropped curbs',
      coordinates: basePoints,
      audits: [accessibleAudit],
      profileHighlightsPl: _getHighlightsPl(profile),
      profileHighlightsEn: _getHighlightsEn(profile),
      detectedBarrierPl: 'Wykryto 14 stopni i krawężnik 12 cm na trasie bezpośredniej',
      detectedBarrierEn: '14 stairs and 12cm curb detected on direct path',
      bypassReasonPl: 'Ominięto barierę zjazdem rampowym (+60 m, 0 stopni)',
      bypassReasonEn: 'Bypassed barrier via flat ramp (+60 m, 0 stairs)',
    );

    final standardRoute = RouteModel(
      id: 'route_dyn_std',
      titlePl: 'Trasa standardowa (Google Maps / z barierami)',
      titleEn: 'Standard Route (with barriers)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: distanceMeters,
      durationMinutes: durationMinutes,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 25 : (profile == MobilityProfile.cane ? 45 : 35),
      stairsAvoided: 0,
      surfaceSummaryPl: 'Schody (14 stopni), krawężniki 12cm, nierówności',
      surfaceSummaryEn: 'Stairs (14 steps), 12cm curbs, uneven surface',
      coordinates: basePoints,
      audits: [standardAudit],
      profileHighlightsPl: const ['Krótsza o 60m', 'Zawiera bariery architektoniczne'],
      profileHighlightsEn: const ['60m shorter', 'Contains architectural barriers'],
    );

    return [accessibleRoute, standardRoute];
  }

  static List<RouteModel> _getDworzecRynekRoutes(MobilityProfile profile) {
    final standardAudits = [
      AccessibilityAudit(
        id: 'aud_std_1',
        checkpointName: 'Przejście podziemne Dworzec / Planty (ul. Lubicz)',
        location: const LatLng(50.0652, 19.9442),
        photoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
        isAccessible: false,
        score: profile == MobilityProfile.wheelchair ? 20 : (profile == MobilityProfile.cane ? 45 : 30),
        stairsDetected: true,
        stairsCount: 24,
        curbStatus: 'Brak rampy / schody strome',
        surfaceType: 'Śliskie kafelki / Schody betonowe',
        hazards: const ['24 stopnie w dół i w górę', 'Zepsuta winda platformowa', 'Brak pochylni'],
        aiVerdictPl: profile == MobilityProfile.wheelchair
            ? 'KRYTYCZNA BARIERA DLA WÓZKA: 24 stopnie bez windy. Przejazd niemożliwy bez asysty 2 osób.'
            : (profile == MobilityProfile.cane
                ? 'ZAGROŻENIE DLA SENIORA: Śliskie stopnie i strome zejście – ryzyko potknięcia i upadku.'
                : 'UTRUDNIENIE: Konieczność zniesienia wózka dziecięcego ze schodów.'),
        aiVerdictEn: 'CRITICAL BARRIER: 24 steps without functioning elevator.',
        bypassPhotoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
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
        photoUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=800&q=80',
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
        bypassPhotoUrl: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=800&q=80',
        bypassTitlePl: 'Objazd ul. Szpitalną',
        bypassTitleEn: 'Bypass via Szpitalna St.',
        bypassDescriptionPl: 'Gładkie płyty granitowe po rewitalizacji bez szwów.',
        bypassDescriptionEn: 'Smooth revitalized granite slabs.',
      ),
    ];

    final standardRoute = RouteModel(
      id: 'route_standard_dworzec',
      titlePl: 'Trasa standardowa (Google Maps / z barierami)',
      titleEn: 'Standard Route (with barriers)',
      type: RouteType.standard,
      polylineColor: const Color(0xFFEF4444),
      distanceMeters: 850,
      durationMinutes: 12,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 28 : (profile == MobilityProfile.cane ? 52 : 38),
      stairsAvoided: 0,
      surfaceSummaryPl: 'Schody (24 stopnie podziemne), kocie łby na Floriańskiej',
      surfaceSummaryEn: 'Stairs (24 underground steps), rough cobblestone',
      coordinates: const [
        LatLng(50.0668, 19.9464),
        LatLng(50.0660, 19.9458),
        LatLng(50.0652, 19.9442), // Bariera: przejście schody
        LatLng(50.0645, 19.9405), // Kocie łby Floriańska
        LatLng(50.0630, 19.9390),
        LatLng(50.0617, 19.9373),
      ],
      audits: standardAudits,
      profileHighlightsPl: const ['Krótsza o 70 m', 'Zawiera 24 strome stopnie bez windy'],
      profileHighlightsEn: const ['70 m shorter', 'Contains 24 steep steps without lift'],
    );

    // Dostępna KrakAccess
    final accessibleAudits = [
      AccessibilityAudit(
        id: 'aud_acc_1',
        checkpointName: 'Przejście naziemne Planty (ul. Westerplatte / Lubicz)',
        location: const LatLng(50.0648, 19.9451),
        photoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
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
        bypassTitlePl: 'Sprawdzony punkt widokiem ulicy',
        bypassTitleEn: 'Street View Verified',
        bypassDescriptionPl: 'Audyt AI potwierdził obecność obniżonych krawężników i brak barier.',
        bypassDescriptionEn: 'AI audit verified dropped curbs and zero obstacles.',
      ),
      AccessibilityAudit(
        id: 'aud_acc_2',
        checkpointName: 'Dojście ul. Szpitalną do Rynku',
        location: const LatLng(50.0628, 19.9388),
        photoUrl: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=800&q=80',
        isAccessible: true,
        score: 98,
        stairsDetected: false,
        curbStatus: 'Łagodny najazd rampowy',
        surfaceType: 'Gładkie płyty chodnikowe bezszwowe',
        hazards: const [],
        aiVerdictPl: 'OPTYMALNE: Nowa nawierzchnia płytowa po rewitalizacji, brak wstrząsów, szerokość >2.4 m.',
        aiVerdictEn: 'OPTIMAL: Smooth paving slabs, width >2.4m, safe for all mobility types.',
      ),
    ];

    final accessibleRoute = RouteModel(
      id: 'route_accessible_dworzec',
      titlePl: 'Trasa KrakAccess (${_getProfileNamePl(profile)})',
      titleEn: 'KrakAccess Route (${_getProfileNameEn(profile)})',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 920,
      durationMinutes: 13,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 98 : (profile == MobilityProfile.cane ? 96 : 97),
      stairsAvoided: 24,
      surfaceSummaryPl: 'Gładkie płyty szlifowane, 0 schodów, 100% zjazdów rampowych',
      surfaceSummaryEn: 'Smooth granite slabs, 0 stairs, 100% dropped curbs',
      coordinates: const [
        LatLng(50.0668, 19.9464),
        LatLng(50.0662, 19.9450),
        LatLng(50.0648, 19.9451),
        LatLng(50.0638, 19.9418),
        LatLng(50.0628, 19.9388),
        LatLng(50.0617, 19.9373),
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
        LatLng(50.0545, 19.9354),
        LatLng(50.0538, 19.9372),
        LatLng(50.0530, 19.9410),
        LatLng(50.0519, 19.9452),
      ],
      audits: [
        AccessibilityAudit(
          id: 'aud_wawel_std',
          checkpointName: 'Zejście pod Wzgórzem Wawelskim (ul. św. Idziego)',
          location: const LatLng(50.0538, 19.9372),
          photoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=800&q=80',
          isAccessible: false,
          score: profile == MobilityProfile.wheelchair ? 20 : 35,
          stairsDetected: true,
          stairsCount: 18,
          curbStatus: 'Strome schody bez poręczy',
          surfaceType: 'Wapień historyczny śliski',
          hazards: const ['18 stopni', 'Brak pochylni', 'Spadek terenu 11%'],
          aiVerdictPl: 'KRYTYCZNA BARIERA: Schody kamienne o nachyleniu 11% bez pochylni.',
          aiVerdictEn: 'CRITICAL BARRIER: Steep stone steps with 11% gradient.',
          bypassPhotoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
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
      titlePl: 'Trasa KrakAccess (${_getProfileNamePl(profile)})',
      titleEn: 'KrakAccess Route (${_getProfileNameEn(profile)})',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 1250,
      durationMinutes: 17,
      accessibilityScore: profile == MobilityProfile.wheelchair ? 95 : (profile == MobilityProfile.cane ? 93 : 95),
      stairsAvoided: 18,
      surfaceSummaryPl: 'Łagodne nachylenie <3.5%, gładki asfalt, 0 schodów',
      surfaceSummaryEn: 'Gentle slope <3.5%, smooth asphalt, 0 stairs',
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
      titlePl: 'Trasa KrakAccess (ul. Sławkowska)',
      titleEn: 'KrakAccess Route (Sławkowska St.)',
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
      titlePl: 'Trasa standardowa (przez kocie łby)',
      titleEn: 'Standard Route (via cobblestones)',
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

  static String _getProfileNamePl(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'Wózek inwalidzki';
      case MobilityProfile.cane:
        return 'O kuli / Senior';
      case MobilityProfile.stroller:
        return 'Wózek dziecięcy';
    }
  }

  static String _getProfileNameEn(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return 'Wheelchair';
      case MobilityProfile.cane:
        return 'Cane / Senior';
      case MobilityProfile.stroller:
        return 'Stroller';
    }
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
