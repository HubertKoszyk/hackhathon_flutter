import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_translations.dart';
import '../models/accessibility_audit.dart';
import '../models/parking_spot.dart';
import '../models/route_model.dart';
import '../services/krakow_data_service.dart';
import '../services/routing_service.dart';

enum MobilityProfile { wheelchair, cane, stroller }

class AppState extends ChangeNotifier {
  String _language = 'pl';
  MobilityProfile _profile = MobilityProfile.wheelchair;
  bool _showParkingLayer = true;
  String _selectedPresetId = 'preset_dworzec_rynek';
  int _selectedRouteIndex = 0; // 0 = Accessible, 1 = Standard
  ParkingSpot? _selectedParking;
  AccessibilityAudit? _activeAudit;
  LatLng? _customPin;
  bool _isLoadingDynamicRoute = false;

  late List<ParkingSpot> _parkingSpots;
  late List<RouteModel> _routes;

  AppState() {
    _parkingSpots = KrakowDataService.getParkingSpots();
    _routes = RoutingService.getRoutesForPreset(_selectedPresetId, _profile);
  }

  // Getters
  String get language => _language;
  MobilityProfile get profile => _profile;
  bool get showParkingLayer => _showParkingLayer;
  String get selectedPresetId => _selectedPresetId;
  int get selectedRouteIndex => _selectedRouteIndex;
  ParkingSpot? get selectedParking => _selectedParking;
  AccessibilityAudit? get activeAudit => _activeAudit;
  LatLng? get customPin => _customPin;
  bool get isLoadingDynamicRoute => _isLoadingDynamicRoute;

  List<ParkingSpot> get parkingSpots => _parkingSpots;
  List<RouteModel> get routes => _routes;
  RouteModel? get currentRoute => _routes.isNotEmpty ? _routes[_selectedRouteIndex] : null;

  String tr(String key) => AppTranslations.tr(key, _language);

  // Actions
  void toggleLanguage() {
    _language = _language == 'pl' ? 'en' : 'pl';
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setProfile(MobilityProfile newProfile) {
    if (_profile != newProfile) {
      _profile = newProfile;
      // Natychmiast przelicz trasy, wskaźniki i bariery pod nowy profil!
      if (_customPin != null) {
        routeToCustomPoint(_customPin!);
      } else {
        _routes = RoutingService.getRoutesForPreset(_selectedPresetId, _profile);
      }
      notifyListeners();
    }
  }

  void toggleParkingLayer() {
    _showParkingLayer = !_showParkingLayer;
    notifyListeners();
  }

  void selectPreset(String presetId) {
    _selectedPresetId = presetId;
    _customPin = null;
    _routes = RoutingService.getRoutesForPreset(presetId, _profile);
    _selectedRouteIndex = 0;
    _selectedParking = null;
    notifyListeners();
  }

  void selectRoute(int index) {
    if (index >= 0 && index < _routes.length) {
      _selectedRouteIndex = index;
      notifyListeners();
    }
  }

  void selectParking(ParkingSpot? spot) {
    _selectedParking = spot;
    notifyListeners();
  }

  void setCustomPin(LatLng point) {
    _customPin = point;
    _selectedParking = null;
    notifyListeners();
  }

  void clearCustomPin() {
    _customPin = null;
    notifyListeners();
  }

  Future<void> routeToCustomPoint(LatLng destination, [String? targetName]) async {
    _isLoadingDynamicRoute = true;
    _customPin = destination;
    _selectedParking = null;
    notifyListeners();

    // Start z aktualnej lokalizacji / Dworca Głównego w Krakowie
    const startPoint = LatLng(50.0668, 19.9464);

    final dynamicRoutes = await RoutingService.calculateDynamicRoute(
      start: startPoint,
      end: destination,
      profile: _profile,
      destinationName: targetName ?? 'Wybrany punkt w Krakowie',
    );

    _routes = dynamicRoutes;
    _selectedRouteIndex = 0;
    _isLoadingDynamicRoute = false;
    notifyListeners();
  }

  void openAudit(AccessibilityAudit audit) {
    _activeAudit = audit;
    notifyListeners();
  }

  void closeAudit() {
    _activeAudit = null;
    notifyListeners();
  }

  void planRouteFromParking(ParkingSpot spot) {
    _selectedParking = null;
    _customPin = null;
    final start = spot.location;
    const dest = LatLng(50.0617, 19.9373); // Rynek Sukiennice

    final customAccessibleRoute = RouteModel(
      id: 'route_from_${spot.id}',
      titlePl: 'Trasa z koperty: ${spot.street}',
      titleEn: 'Route from spot: ${spot.street}',
      type: RouteType.accessible,
      polylineColor: const Color(0xFF10B981),
      distanceMeters: 620,
      durationMinutes: 8,
      accessibilityScore: _profile == MobilityProfile.wheelchair ? 98 : (_profile == MobilityProfile.cane ? 96 : 97),
      stairsAvoided: 12,
      surfaceSummaryPl: 'Nawierzchnia sprawdzona przez AI. 100% obniżonych krawężników.',
      surfaceSummaryEn: 'AI-verified surface. 100% dropped curbs.',
      coordinates: [
        start,
        LatLng(
          start.latitude + (dest.latitude - start.latitude) * 0.4,
          start.longitude + (dest.longitude - start.longitude) * 0.2,
        ),
        LatLng(
          start.latitude + (dest.latitude - start.latitude) * 0.7,
          start.longitude + (dest.longitude - start.longitude) * 0.8,
        ),
        dest,
      ],
      audits: [
        AccessibilityAudit(
          id: 'aud_custom_${spot.id}',
          checkpointName: 'Wyjazd z koperty (${spot.street})',
          location: start,
          photoUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
          isAccessible: true,
          score: 97,
          stairsDetected: false,
          curbStatus: 'Zjazd 0cm bezpośrednio na chodnik',
          surfaceType: 'Płyty gładkie',
          hazards: const [],
          aiVerdictPl: 'Bezpieczny zjazd z koperty bezpośrednio do strefy pieszej.',
          aiVerdictEn: 'Safe curb cut directly connecting parking to pedestrian zone.',
        ),
      ],
      profileHighlightsPl: RoutingService.presets.first.titlePl.isNotEmpty
          ? (_profile == MobilityProfile.wheelchair
              ? ['Bezpośredni zjazd z koperty', '100% ramp']
              : ['Krótki dystans do Rynku', 'Brak schodów'])
          : [],
    );

    _routes = [customAccessibleRoute];
    _selectedRouteIndex = 0;
    notifyListeners();
  }
}
