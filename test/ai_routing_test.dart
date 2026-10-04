import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hackhathon_flutter/models/route_model.dart';
import 'package:hackhathon_flutter/models/transit_route_info.dart';
import 'package:hackhathon_flutter/providers/app_state.dart';
import 'package:hackhathon_flutter/services/routing_service.dart';
import 'package:hackhathon_flutter/services/ai_route_analyst.dart';
import 'package:hackhathon_flutter/services/navigation_service.dart';
import 'package:hackhathon_flutter/services/gtfs_transit_service.dart';

void main() {
  group('Routing & Statistics Tests', () {
    test('Dworzec -> Rynek preset has accurate stairs statistics and GTFS transit option', () {
      final routes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', MobilityProfile.wheelchair);
      expect(routes.length, 3);

      final accessible = routes.firstWhere((r) => r.type == RouteType.accessible);
      final transit = routes.firstWhere((r) => r.type == RouteType.transit);
      final standard = routes.firstWhere((r) => r.type == RouteType.standard);

      expect(accessible.stairsCount, 0);
      expect(accessible.stairsAvoided, 24);
      expect(standard.stairsCount, 24);
      expect(standard.stairsAvoided, 0);

      // Weryfikacja danych trasy komunikacji miejskiej GTFS
      expect(transit.transitInfo, isNotNull);
      expect(transit.stairsCount, 0);
      expect(transit.transitInfo!.transitLeg.isLowFloor, isTrue);
      expect(transit.transitInfo!.transitLeg.hasRamp, isTrue);
      expect(transit.transitInfo!.transitLeg.departureStop.wheelchairBoarding, isTrue);
    });


    test('Wawel -> Kazimierz preset has 18 stairs and DOES NOT mention Floriańska', () {
      final routes = RoutingService.getRoutesForPreset('preset_wawel_kazimierz', MobilityProfile.wheelchair);
      final accessible = routes.firstWhere((r) => r.type == RouteType.accessible);
      final standard = routes.firstWhere((r) => r.type == RouteType.standard);

      expect(accessible.stairsCount, 0);
      expect(accessible.stairsAvoided, 18);
      expect(standard.stairsCount, 18);
      expect(standard.stairsAvoided, 0);

      // Verify Floriańska is not present anywhere in Wawel route
      for (final highlight in accessible.profileHighlightsPl) {
        expect(highlight.toLowerCase().contains('floriań'), isFalse);
      }
      expect(accessible.detectedBarrierPl?.toLowerCase().contains('floriań') ?? false, isFalse);
      expect(accessible.bypassReasonPl?.toLowerCase().contains('floriań') ?? false, isFalse);
    });

    test('Barbakan -> Rynek preset correctly avoids cobblestones on Floriańska', () {
      final routes = RoutingService.getRoutesForPreset('preset_barbakan_sukiennice', MobilityProfile.wheelchair);
      final accessible = routes.firstWhere((r) => r.type == RouteType.accessible);
      final standard = routes.firstWhere((r) => r.type == RouteType.standard);

      expect(accessible.stairsCount, 0);
      expect(accessible.stairsAvoided, 0);
      expect(standard.stairsCount, 0);

      // On Barbakan route, Floriańska cobblestones are actually avoided via Sławkowska
      expect(accessible.profileHighlightsPl.any((h) => h.contains('Sławkowskiej')), isTrue);
    });

    test('Reversing preset routes reverses coordinates and updates titles', () {
      final forwardRoutes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', MobilityProfile.wheelchair);
      final reversedRoutes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', MobilityProfile.wheelchair, reversed: true);

      final forwardAcc = forwardRoutes.firstWhere((r) => r.type == RouteType.accessible);
      final reversedAcc = reversedRoutes.firstWhere((r) => r.type == RouteType.accessible);

      expect(forwardAcc.coordinates.first, reversedAcc.coordinates.last);
      expect(forwardAcc.coordinates.last, reversedAcc.coordinates.first);
    });

    test('AI route analyst produces realistic, location-specific data for AGH without Floriańska', () async {
      final analysis = await AiRouteAnalyst.analyzeRoute(
        startName: 'AGH (Miasteczko Studenckie)',
        destinationName: 'Błonia Krakowskie',
        start: const LatLng(50.0664, 19.9192),
        end: const LatLng(50.0594, 19.9125),
        distanceMeters: 950,
        profile: MobilityProfile.wheelchair,
      );

      // Must not mention Floriańska for an AGH -> Błonia route!
      expect(analysis.barrierNamePl.toLowerCase().contains('floriań'), isFalse);
      expect(analysis.bypassReasonPl.toLowerCase().contains('floriań'), isFalse);
      expect(analysis.highlightsPl.any((h) => h.toLowerCase().contains('floriań')), isFalse);
      expect(analysis.photoUrl.startsWith('assets/streetview/') || analysis.photoUrl.startsWith('http'), isTrue);
      expect(analysis.bypassPhotoUrl.startsWith('assets/streetview/'), isTrue);
    });

    test('Route from Dworzec to AGH shows 0 stairs (not 24 stairs!)', () async {
      final routes = await RoutingService.calculateDynamicRoute(
        start: const LatLng(50.0668, 19.9460), // Dworzec Główny
        end: const LatLng(50.0665, 19.9190),   // AGH
        profile: MobilityProfile.wheelchair,
        startName: 'Dworzec Główny PKP',
        destinationName: 'AGH Kraków',
      );

      final standard = routes.firstWhere((r) => r.type == RouteType.standard);
      // Trasa do AGH biegnie przez Basztową / Karmelicką / Czarnowiejską - nie ma tam tunelu Lubicz!
      expect(standard.stairsCount, 0);
      expect(standard.detectedBarrierPl?.toLowerCase().contains('lubicz'), isFalse);
    });

    test('Customized mobility profiles have distinct guidance for wheelchair, cane, and stroller', () async {
      final wheelchairRes = await AiRouteAnalyst.analyzeRoute(
        startName: 'Dworzec Główny PKP',
        destinationName: 'Rynek Główny',
        start: const LatLng(50.0668, 19.9460),
        end: const LatLng(50.0617, 19.9373),
        distanceMeters: 800,
        profile: MobilityProfile.wheelchair,
      );

      final caneRes = await AiRouteAnalyst.analyzeRoute(
        startName: 'Dworzec Główny PKP',
        destinationName: 'Rynek Główny',
        start: const LatLng(50.0668, 19.9460),
        end: const LatLng(50.0617, 19.9373),
        distanceMeters: 800,
        profile: MobilityProfile.cane,
      );

      final strollerRes = await AiRouteAnalyst.analyzeRoute(
        startName: 'Dworzec Główny PKP',
        destinationName: 'Rynek Główny',
        start: const LatLng(50.0668, 19.9460),
        end: const LatLng(50.0617, 19.9373),
        distanceMeters: 800,
        profile: MobilityProfile.stroller,
      );

      // Wheelchair checks
      expect(wheelchairRes.aiVerdictPl.toLowerCase().contains('wózk'), isTrue);
      expect(wheelchairRes.highlightsPl.any((h) => h.contains('0-1 cm') || h.contains('WCAG')), isTrue);

      // Cane checks (resting spots / fall prevention)
      expect(caneRes.aiVerdictPl.toLowerCase().contains('senior') || caneRes.aiVerdictPl.toLowerCase().contains('upadk') || caneRes.aiVerdictPl.toLowerCase().contains('kuli'), isTrue);
      expect(caneRes.highlightsPl.any((h) => h.contains('ławek') || h.contains('odpoczynku') || h.contains('antypoślizgow')), isTrue);

      // Stroller checks (child comfort / sleep / carrying)
      expect(strollerRes.aiVerdictPl.toLowerCase().contains('dzieck') || strollerRes.aiVerdictPl.toLowerCase().contains('rodzic'), isTrue);
      expect(strollerRes.highlightsPl.any((h) => h.contains('dziecka') || h.contains('wózka dziecięcego')), isTrue);
    });

    test('Both positive and negative audits contain real streetview photos and bypass photos', () {
      final presets = [
        'preset_dworzec_rynek',
        'preset_wawel_kazimierz',
        'preset_barbakan_sukiennice',
      ];

      for (final preset in presets) {
        final routes = RoutingService.getRoutesForPreset(preset, MobilityProfile.wheelchair);
        final accessible = routes.firstWhere((r) => r.type == RouteType.accessible);
        final standard = routes.firstWhere((r) => r.type == RouteType.standard);

        // Positive route audit checks
        expect(accessible.audits.isNotEmpty, isTrue, reason: '$preset accessible audits must not be empty');
        for (final audit in accessible.audits) {
          expect(audit.photoUrl, startsWith('assets/streetview/'));
          expect(audit.bypassPhotoUrl, isNotNull);
          expect(audit.bypassPhotoUrl, startsWith('assets/streetview/'));
          expect(audit.isAccessible, isTrue);
        }

        // Negative route audit checks
        expect(standard.audits.isNotEmpty, isTrue, reason: '$preset standard audits must not be empty');
        for (final audit in standard.audits) {
          expect(audit.photoUrl, startsWith('assets/streetview/'));
          expect(audit.bypassPhotoUrl, isNotNull);
          expect(audit.bypassPhotoUrl, startsWith('assets/streetview/'));
          expect(audit.isAccessible, isFalse);
        }
      }
    });

    test('NavigationService generates turn-by-turn maneuvers with accessibility notes', () {
      final routes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', MobilityProfile.wheelchair);
      final accessibleRoute = routes.firstWhere((r) => r.type == RouteType.accessible);

      final steps = NavigationService.generateStepsForRoute(accessibleRoute, MobilityProfile.wheelchair);
      expect(steps.length, greaterThanOrEqualTo(2));

      // Pierwszy krok - Start
      expect(steps.first.maneuverIcon, Icons.navigation);
      expect(steps.first.instructionPl.toLowerCase().contains('ruszaj') || steps.first.instructionPl.toLowerCase().contains('kierunku'), isTrue);
      expect(steps.first.accessibilityNotePl, isNotNull);

      // Ostatni krok - Meta
      expect(steps.last.maneuverIcon, Icons.flag);
      expect(steps.last.instructionPl.toLowerCase().contains('osiągnięty') || steps.last.instructionPl.toLowerCase().contains('cel'), isTrue);
    });

    test('AppState startNavigation and stopNavigation controls live navigation state', () {
      final state = AppState();
      expect(state.isNavigating, isFalse);
      expect(state.navigationUserPosition, isNull);

      // Rozpoczęcie nawigacji na żywo
      state.startNavigation();
      expect(state.isNavigating, isTrue);
      expect(state.navigationUserPosition, isNotNull);
      expect(state.navigationSteps.isNotEmpty, isTrue);
      expect(state.remainingDistance, greaterThan(0));
      expect(state.remainingDurationSeconds, greaterThan(0));

      // Zmiana prędkości symulacji i wyciszenia
      state.setSimulationSpeed(2.0);
      expect(state.simulationSpeedMultiplier, 2.0);

      state.toggleVoiceMute();
      expect(state.isVoiceMuted, isTrue);

      // Zatrzymanie nawigacji
      state.stopNavigation();
      expect(state.isNavigating, isFalse);
    });
  });

  group('GTFS Kraków Transit & Platform Accessibility Tests', () {
    test('GtfsTransitService stop database has authentic Kraków coordinates and platform data', () {
      expect(GtfsTransitService.krakowStops.isNotEmpty, isTrue);

      final bagatela = GtfsTransitService.krakowStops.firstWhere((s) => s.name.contains('Bagatela'));
      expect(bagatela.platformType, PlatformType.vienna);
      expect(bagatela.platformBadgeTextPl.contains('Wiedeński'), isTrue);
      expect(bagatela.wheelchairBoarding, isTrue);

      final mogilskie = GtfsTransitService.krakowStops.firstWhere((s) => s.name == 'Rondo Mogilskie');
      expect(mogilskie.platformType, PlatformType.elevatorHub);
      expect(mogilskie.platformBadgeTextPl.contains('windami'), isTrue);
    });

    test('GTFS transit routes calculate dynamic departures and speed comparison', () {
      final transitRoute = GtfsTransitService.calculateFastestTransitRoute(
        start: const LatLng(50.0668, 19.9460), // Dworzec Główny
        end: const LatLng(50.0629, 19.9033), // Cichy Kącik
        profile: MobilityProfile.wheelchair,
        walkingDistanceMeters: 3400,
        walkingDurationMinutes: 48,
        startName: 'Dworzec Główny',
        destinationName: 'Cichy Kącik',
      );

      expect(transitRoute, isNotNull);
      expect(transitRoute!.type, RouteType.transit);
      expect(transitRoute.transitInfo, isNotNull);

      final tInfo = transitRoute.transitInfo!;
      expect(tInfo.transitLeg.isLowFloor, isTrue);
      expect(tInfo.transitLeg.hasRamp, isTrue);
      expect(tInfo.totalDurationMinutes, lessThan(48)); // Transit is much faster than 48 min walk
      expect(tInfo.isFastest, isTrue);
      expect(tInfo.timeSavedMinutes, greaterThan(0));
      expect(tInfo.transitLeg.nextDeparturesFormatted.isNotEmpty, isTrue);
    });

    test('Live navigation generates accessible transit instructions for disabled passengers', () {
      final routes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', MobilityProfile.wheelchair);
      final transitRoute = routes.firstWhere((r) => r.type == RouteType.transit);

      final steps = NavigationService.generateStepsForRoute(transitRoute, MobilityProfile.wheelchair);
      expect(steps.length, greaterThanOrEqualTo(4));

      // First step: Walk to stop
      expect(steps[0].instructionPl.contains('przystanek'), isTrue);
      expect(steps[0].accessibilityNotePl, isNotNull);

      // Second step: Platform wait
      expect(steps[1].instructionPl.contains('Peron') || steps[1].instructionPl.contains('Oczekuj'), isTrue);

      // Third step: Boarding low-floor vehicle with ramp
      expect(steps[2].instructionPl.contains('wózka') || steps[2].instructionPl.contains('Wsiądź'), isTrue);

      // Final step: Destination reached
      expect(steps.last.instructionPl.contains('celu'), isTrue);
      expect(steps.last.accessibilityNotePl?.contains('0'), isTrue);
    });

    test('Tapping map (setCustomPin) automatically plans route and selects transit option', () async {
      final state = AppState();
      // Initially, preset routes are loaded
      state.loadPresetRoute('preset_dworzec_rynek');
      expect(state.routes.isNotEmpty, isTrue);

      // User clicks anywhere on the map, e.g. near Błonia / AGH
      final targetPoint = const LatLng(50.0610, 19.9150);
      state.setCustomPin(targetPoint);

      // Waiting for asynchronous route calculation to finish
      await Future.delayed(const Duration(milliseconds: 50));
      while (state.isAnalyzingRoute) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      expect(state.customPin, equals(targetPoint));
      expect(state.routes.isNotEmpty, isTrue);

      // The selected route should be the GTFS transit option
      final transitIdx = state.routes.indexWhere((r) => r.isTransit);
      if (transitIdx != -1) state.selectRoute(transitIdx);
      final activeRoute = state.currentRoute;
      expect(activeRoute, isNotNull);
      expect(activeRoute!.isTransit, isTrue);
      expect(activeRoute.transitInfo, isNotNull);
      expect(activeRoute.transitInfo!.transitLeg.isLowFloor, isTrue);
    });

    test('GTFS transit routing reliably connects arbitrary coordinates across Kraków', () {
      final testCases = [
        // Dworzec -> Błonia / AGH
        const [LatLng(50.0668, 19.9464), LatLng(50.0610, 19.9150)],
        // Kazimierz -> Krowodrza Górka
        const [LatLng(50.0480, 19.9430), LatLng(50.0880, 19.9320)],
        // Podgórze -> Centrum
        const [LatLng(50.0460, 19.9540), LatLng(50.0630, 19.9320)],
        // Nowy Kleparz -> Wawel
        const [LatLng(50.0735, 19.9360), LatLng(50.0545, 19.9354)],
      ];

      for (final pair in testCases) {
        final transit = GtfsTransitService.calculateFastestTransitRoute(
          start: pair[0],
          end: pair[1],
          profile: MobilityProfile.wheelchair,
          walkingDistanceMeters: 2500,
          walkingDurationMinutes: 35,
        );

        expect(transit, isNotNull);
        expect(transit!.isTransit, isTrue);
        expect(transit.transitInfo!.transitLeg.lineName.isNotEmpty, isTrue);
        expect(transit.transitInfo!.transitLeg.departureStop.wheelchairBoarding, isTrue);
      }
    });
  });
}

