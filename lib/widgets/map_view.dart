import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hackhathon_flutter/theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/accessible_place.dart';
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
    final isUK = state.language == 'uk';
    final wysiadkaLabel = isPL
        ? 'Wysiadka: '
        : (isUK ? 'Висадка: ' : 'Get off: ');
    final hasRoute = state.routes.isNotEmpty || state.isNavigating;

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
        onLongPress: (tapPosition, latLng) {
          state.setCustomPin(latLng);
        },
      ),
      children: [
        // Podkład mapy miejskiej (CartoDB Voyager z fallbackiem do OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: NetworkTileProvider(
            headers: {
              'User-Agent': 'NavAbleKrakowApp/1.0 (Android; contact@navable.pl)',
            },
          ),
          maxZoom: 19,
        ),

        // Warstwa tras (Polylines)
        PolylineLayer(
          polylines: [
            for (final entry in state.routes.asMap().entries) ...[
              // Jeśli wybrano konkretną trasę (selectedRouteIndex >= 0),
              // ukrywamy pozostałe trasy (brak „duchów”).
              if (state.selectedRouteIndex == -1 ||
                  entry.key == state.selectedRouteIndex) ...[
                if (entry.value.isTransit &&
                    entry.value.transitInfo != null &&
                    entry.key == state.selectedRouteIndex) ...[
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
                    strokeWidth: entry.key == state.selectedRouteIndex ? 6.5 : 5.0,
                    color: entry.value.polylineColor,
                  ),
                ],
              ],
            ],
          ],
        ),

        // 1. Warstwa markerów podkładowych (Parkingi, Obiekty bez barier, Kropki przystanków pośrednich, AI Audyty, Custom Pin)
        MarkerLayer(
          markers: [
            // 1. Miejsca parkingowe dla niepełnosprawnych ("Koperty")
            if (state.showParkingLayer && !hasRoute)
              ...state.parkingSpots.map((spot) {
                final isSelected = state.selectedParking?.id == spot.id;
                return Marker(
                  point: spot.location,
                  width: isSelected ? 44 : 36,
                  height: isSelected ? 44 : 36,
                  child: GestureDetector(
                    onTap: () => state.selectParking(spot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 94, 255), // Blue
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : const Color.fromARGB(255, 0, 77, 209),
                          width: isSelected ? 3.0 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: isSelected ? 0.6 : 0.3),
                            blurRadius: isSelected ? 10 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.accessible,
                          color: Colors.white,
                          size: isSelected ? 22 : 18,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // 1.5 Hotele i obiekty kultury / użyteczności bez barier
            if (state.showAccessiblePlacesLayer && !hasRoute)
              ...state.accessiblePlaces.map((place) {
                final isSelected = state.selectedAccessiblePlace?.id == place.id;
                final isHotel = place.category == AccessiblePlaceCategory.hotel;
                final primaryColor = isHotel
                    ? const Color(0xFFD97706) // Warm Amber for hotels
                    : const Color(0xFF7C3AED); // Purple / Violet for cultural venues
                final borderColor = isHotel
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFA78BFA);

                return Marker(
                  point: place.location,
                  width: isSelected ? 48 : 40,
                  height: isSelected ? 48 : 40,
                  child: GestureDetector(
                    onTap: () => state.selectAccessiblePlace(place),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : borderColor,
                          width: isSelected ? 3.0 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: isSelected ? 0.65 : 0.35),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isHotel
                                ? Icons.hotel
                                : (place.category == AccessiblePlaceCategory.publicBuilding
                                    ? Icons.apartment
                                    : Icons.account_balance),
                            color: Colors.white,
                            size: isSelected ? 22 : 18,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Icon(
                                Icons.accessible,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            // 2. Przystanki pośrednie na trasie tranzytowej (drobne kropki)
            if (activeRoute != null &&
                activeRoute.isTransit &&
                activeRoute.transitInfo != null &&
                activeRoute.transitInfo!.transitLeg.intermediateStops.length > 2)
              for (final stop in activeRoute.transitInfo!.transitLeg.intermediateStops.sublist(
                1,
                activeRoute.transitInfo!.transitLeg.intermediateStops.length - 1,
              ))
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
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

            // 3. Punkty kontrolne / Audyty AI Street View - dyskretne, małe (24x24)
            if (activeRoute != null)
              ...activeRoute.audits.map(
                (audit) => Marker(
                  point: audit.location,
                  width: 26,
                  height: 26,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => state.openAudit(audit),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: audit.isAccessible
                            ? const Color(0xFF1E293B).withValues(alpha: 0.82)
                            : const Color(0xFFDC2626).withValues(alpha: 0.88),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          audit.isAccessible
                              ? Icons.verified
                              : Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 4. Dotknięty punkt docelowy na mapie (Custom Pin)
            if (state.customPin != null && !hasRoute)
              Marker(
                point: state.customPin!,
                width: 190,
                height: 75,
                child: GestureDetector(
                  onTap: () =>
                      state.planRouteBetweenSelectedPoints(showLoader: true),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kColorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kColorScheme.tertiary),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPL
                                  ? 'Wyznaczam trasę tutaj'
                                  : (isUK ? 'Маршрут сюди' : 'Route here'),
                              style: TextStyle(
                                color: kColorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.location_pin,
                        color: kColorScheme.primary,
                        size: 34,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // 2. Warstwa markerów wierzchnich (Zawsze na wierzchu! Start/Meta, Pozycja GPS oraz Etykiety przystanków)
        MarkerLayer(
          markers: [
            // Start Marker
            if (state.routes.isNotEmpty)
              Marker(
                point: activeRoute?.coordinates.first ?? state.startLocation.point,
                width: 42,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(255, 6, 139, 95),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.trip_origin,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

            // Meta Marker
            if (state.routes.isNotEmpty)
              Marker(
                point: activeRoute?.coordinates.last ??
                    (state.destinationLocation?.point ??
                        state.routes.first.coordinates.last),
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 76, 0, 255), // Purple
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(255, 49, 0, 163),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Bieżąca pozycja użytkownika (GPS poza nawigacją)
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

            // Marker użytkownika w trybie nawigacji na żywo (Google Maps Navigation Arrow)
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
                            colors: [kColorScheme.inverseSurface],
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
                          border: Border.all(
                            color: const Color.fromARGB(255, 6, 139, 95),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
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

            // ETYKIETY PRZYSTANKÓW (Zawsze na samym szczycie wszystkich warstw)
            if (activeRoute != null &&
                activeRoute.isTransit &&
                activeRoute.transitInfo != null) ...[
              // Przystanek początkowy (Wsiadanie)
              Marker(
                point:
                    activeRoute.transitInfo!.transitLeg.departureStop.location,
                width: 160,
                height: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF38BDF8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activeRoute.transitInfo!.transitLeg.vehicleType ==
                                    TransitVehicleType.tram
                                ? Icons.tram
                                : Icons.directions_bus,
                            size: 12,
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${activeRoute.transitInfo!.transitLeg.lineName} • ${activeRoute.transitInfo!.transitLeg.departureStop.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.departure_board,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Przystanek docelowy (Wysiadka) - ZAWSZE NA SAMEJ GÓRZE!
              Marker(
                point: activeRoute.transitInfo!.transitLeg.arrivalStop.location,
                width: 160,
                height: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$wysiadkaLabel${activeRoute.transitInfo!.transitLeg.arrivalStop.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
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
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.transfer_within_a_station,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
