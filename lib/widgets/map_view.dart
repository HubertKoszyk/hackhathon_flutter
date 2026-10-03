import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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
          polylines: state.routes.asMap().entries.map((entry) {
            final idx = entry.key;
            final route = entry.value;
            final isSelected = idx == state.selectedRouteIndex;

            return Polyline(
              points: route.coordinates,
              strokeWidth: isSelected ? 6.5 : 3.5,
              color: isSelected
                  ? route.polylineColor
                  : route.polylineColor.withValues(alpha: 0.35),
            );
          }).toList(),
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

            // 2.5 Bieżąca pozycja użytkownika (GPS)
            if (state.userCurrentGpsPoint != null)
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
