import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/transit_route_info.dart';
import '../providers/app_state.dart';

class KrakMapView extends StatefulWidget {
  const KrakMapView({super.key});

  @override
  State<KrakMapView> createState() => _KrakMapViewState();
}

class _KrakMapViewState extends State<KrakMapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeRoute = state.currentRoute;
    final isPL = state.language == 'pl';

    // Auto-recenter mapy w trybie nawigacji na żywo
    if (state.isNavigating && state.navigationUserPosition != null) {
      if (state.shouldRecenterMap) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && state.navigationUserPosition != null) {
            _mapController.move(state.navigationUserPosition!, 17.5);
            state.clearRecenterMapFlag();
          }
        });
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(50.0635, 19.9405), // Centrum Krakowa
        initialZoom: 15.2,
        minZoom: 12.0,
        maxZoom: 18.5,
        onTap: (tapPosition, latLng) {
          state.setCustomPin(latLng);
        },
      ),
      children: [
        // Podkład mapy OpenStreetMap (Kraków)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pl.krakow.krakaccess',
        ),

        // Warstwa tras (Polylines)
        PolylineLayer(
          polylines: [
            for (final entry in state.routes.asMap().entries) ...[
              if (entry.value.isTransit && entry.value.transitInfo != null && entry.key == state.selectedRouteIndex) ...[
                // Dojście piesze do przystanku początkowego (Zielona linia)
                Polyline(
                  points: entry.value.transitInfo!.walkToStopPolyline,
                  strokeWidth: 4.5,
                  color: const Color(0xFF10B981),
                ),
                // Przejazd tramwajem / autobusem (Błękit MPK Kraków)
                Polyline(
                  points: entry.value.transitInfo!.transitLeg.trackGeometry,
                  strokeWidth: 7.0,
                  color: const Color(0xFF0284C7),
                ),
                // Dojście piesze z przystanku docelowego (Zielona linia)
                Polyline(
                  points: entry.value.transitInfo!.walkFromStopPolyline,
                  strokeWidth: 4.5,
                  color: const Color(0xFF10B981),
                ),
              ] else ...[
                Polyline(
                  points: entry.value.coordinates,
                  strokeWidth: entry.key == state.selectedRouteIndex ? 6.5 : 3.5,
                  color: entry.key == state.selectedRouteIndex
                      ? entry.value.polylineColor
                      : entry.value.polylineColor.withValues(alpha: 0.35),
                ),
              ],
            ],
          ],
        ),

        // Warstwa markerów
        MarkerLayer(
          markers: [
            // 1. Miejsca parkingowe dla niepełnosprawnych ("Koperty")
            if (state.showParkingLayer)
              ...state.parkingSpots.map(
                (spot) => Marker(
                  point: spot.location,
                  width: 38,
                  height: 38,
                  child: GestureDetector(
                    onTap: () => state.selectParking(spot),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7), // Blue
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.accessible,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Punkty startu i mety aktywnej trasy
            if (activeRoute != null && activeRoute.coordinates.isNotEmpty) ...[
              // Start Marker
              Marker(
                point: activeRoute.coordinates.first,
                width: 42,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.trip_origin, color: Colors.white, size: 22),
                  ),
                ),
              ),
              // Meta Marker
              Marker(
                point: activeRoute.coordinates.last,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6), // Purple
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],

            // 2.3 Marker użytkownika w trybie nawigacji na żywo (Google Maps Navigation Arrow)
            if (state.isNavigating && state.navigationUserPosition != null)
              Marker(
                point: state.navigationUserPosition!,
                width: 56,
                height: 56,
                child: Transform.rotate(
                  angle: (state.navigationBearing * math.pi / 180),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Poświata kierunkowa / radar radaru
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.45),
                              const Color(0xFF10B981).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      // Wskaźnik pozycji Google Maps z białą obwódką
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2.5 Bieżąca pozycja użytkownika (GPS poza nawigacją)
            if (!state.isNavigating && state.userCurrentGpsPoint != null)
              Marker(
                point: state.userCurrentGpsPoint!,
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),

            // 2.7 Przystanki komunikacji miejskiej GTFS (dla aktywnej trasy tranzytowej)
            if (activeRoute != null && activeRoute.isTransit && activeRoute.transitInfo != null) ...[
              // Przystanek początkowy (Wsiadanie)
              Marker(
                point: activeRoute.transitInfo!.transitLeg.departureStop.location,
                width: 140,
                height: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activeRoute.transitInfo!.transitLeg.vehicleType == TransitVehicleType.tram
                                ? Icons.tram
                                : Icons.directions_bus,
                            size: 11,
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${activeRoute.transitInfo!.transitLeg.lineName} • ${activeRoute.transitInfo!.transitLeg.departureStop.name}',
                              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.departure_board, color: Colors.white, size: 10),
                    ),
                  ],
                ),
              ),

              // Przystanek docelowy (Wysiadanie)
              Marker(
                point: activeRoute.transitInfo!.transitLeg.arrivalStop.location,
                width: 140,
                height: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981), width: 1),
                      ),
                      child: Text(
                        'Wysiadka: ${activeRoute.transitInfo!.transitLeg.arrivalStop.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.transfer_within_a_station, color: Colors.white, size: 10),
                    ),
                  ],
                ),
              ),

              // Przystanki pośrednie na trasie
              if (activeRoute.transitInfo!.transitLeg.intermediateStops.length > 2)
                for (final stop in activeRoute.transitInfo!.transitLeg.intermediateStops
                    .sublist(1, activeRoute.transitInfo!.transitLeg.intermediateStops.length - 1))
                  Marker(
                    point: stop.location,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
            ],

            // 3. Punkty kontrolne / Przeszkody AI Street View
            if (activeRoute != null)
              ...activeRoute.audits.map(
                (audit) => Marker(
                  point: audit.location,
                  width: 52,
                  height: 52,
                  child: GestureDetector(
                    onTap: () => state.openAudit(audit),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: audit.isAccessible
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: (audit.isAccessible
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))
                                    .withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              audit.isAccessible ? Icons.verified : Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        // Badge aparatu Street View
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.streetview,
                              color: Color(0xFF38BDF8),
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. Dotknięty punkt docelowy na mapie (Custom Pin)
            if (state.customPin != null)
              Marker(
                point: state.customPin!,
                width: 190,
                height: 75,
                child: GestureDetector(
                  onTap: () => state.planRouteBetweenSelectedPoints(showLoader: true),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isPL ? 'Wyznacz trasę tutaj' : 'Route here',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.location_pin,
                        color: Color(0xFFF59E0B),
                        size: 34,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
