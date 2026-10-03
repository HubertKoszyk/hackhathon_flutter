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

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(50.0635, 19.9405), // Centrum Krakowa (między Dworcem a Rynkiem)
        initialZoom: 15.2,
        minZoom: 12.0,
        maxZoom: 18.5,
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
                  : route.polylineColor.withOpacity(0.35),
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
                            color: Colors.black.withOpacity(0.3),
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
                        color: const Color(0xFF10B981).withOpacity(0.4),
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
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
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

            // 3. Punkty kontrolne AI Vision (Checkpoints)
            if (activeRoute != null)
              ...activeRoute.audits.map(
                (audit) => Marker(
                  point: audit.location,
                  width: 46,
                  height: 46,
                  child: GestureDetector(
                    onTap: () => state.openAudit(audit),
                    child: Container(
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
                                .withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          audit.isAccessible ? Icons.verified : Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
