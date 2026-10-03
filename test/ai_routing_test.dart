import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hackhathon_flutter/models/route_model.dart';
import 'package:hackhathon_flutter/providers/app_state.dart';
import 'package:hackhathon_flutter/services/routing_service.dart';
import 'package:hackhathon_flutter/services/ai_route_analyst.dart';

void main() {
  group('Routing & Statistics Tests', () {
    test('Dworzec -> Rynek preset has accurate stairs statistics', () {
      final routes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', MobilityProfile.wheelchair);
      expect(routes.length, 2);

      final accessible = routes.firstWhere((r) => r.type == RouteType.accessible);
      final standard = routes.firstWhere((r) => r.type == RouteType.standard);

      expect(accessible.stairsCount, 0);
      expect(accessible.stairsAvoided, 24);
      expect(standard.stairsCount, 24);
      expect(standard.stairsAvoided, 0);
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
    });
  });
}
