import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_translations.dart';
import '../models/accessibility_audit.dart';
import '../models/parking_spot.dart';
import '../models/route_model.dart';
import '../services/krakow_data_service.dart';
import '../services/krakow_locations.dart';
import '../services/location_service.dart';
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

  // GPS i bieżąca lokalizacja
  bool _isLocatingUser = false;
  LatLng? _userCurrentGpsPoint;

  // Wyszukiwanie punktu A i B
  KrakowLocation _startLocation = KrakowLocationsDatabase.locations[0]; // Dworzec Główny
  KrakowLocation _destinationLocation = KrakowLocationsDatabase.locations[1]; // Sukiennice
  bool _isAnalyzingRoute = false;
  String _analysisStatusText = '';

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
  bool get isLocatingUser => _isLocatingUser;
  LatLng? get userCurrentGpsPoint => _userCurrentGpsPoint;
  KrakowLocation get startLocation => _startLocation;
  KrakowLocation get destinationLocation => _destinationLocation;
  bool get isAnalyzingRoute => _isAnalyzingRoute;
  String get analysisStatusText => _analysisStatusText;

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
      planRouteBetweenSelectedPoints(showLoader: false);
      notifyListeners();
    }
  }

  void toggleParkingLayer() {
    _showParkingLayer = !_showParkingLayer;
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

  void setStartLocation(KrakowLocation loc) {
    _startLocation = loc;
    notifyListeners();
  }

  void setDestinationLocation(KrakowLocation loc) {
    _destinationLocation = loc;
    notifyListeners();
  }

  void swapLocations() {
    final temp = _startLocation;
    _startLocation = _destinationLocation;
    _destinationLocation = temp;
    planRouteBetweenSelectedPoints(showLoader: true);
  }

  void setCustomPin(LatLng point) {
    _customPin = point;
    _destinationLocation = KrakowLocation(
      id: 'loc_custom_${DateTime.now().millisecondsSinceEpoch}',
      namePl: 'Punkt wskazany na mapie',
      nameEn: 'Point chosen on map',
      address: 'Kraków (współrzędne GPS)',
      point: point,
      category: 'map',
    );
    notifyListeners();
  }

  void clearCustomPin() {
    _customPin = null;
    notifyListeners();
  }

  /// Pobiera pozycję GPS i ustawia ją jako punkt startowy
  Future<void> useCurrentLocationAsStart() async {
    _isLocatingUser = true;
    notifyListeners();

    final userLoc = await LocationService.getCurrentUserLocation();
    if (userLoc != null) {
      _startLocation = userLoc;
      _userCurrentGpsPoint = userLoc.point;
      _isLocatingUser = false;
      notifyListeners();
      await planRouteBetweenSelectedPoints(showLoader: true);
    } else {
      _isLocatingUser = false;
      notifyListeners();
    }
  }

  /// Główna metoda kalkulacji trasy z symulacją myślenia AI i wykrywania przeszkód
  Future<void> planRouteBetweenSelectedPoints({bool showLoader = true}) async {
    _selectedParking = null;

    if (showLoader) {
      _isAnalyzingRoute = true;
      _analysisStatusText = _language == 'pl'
          ? 'Pobieranie geometrii pieszej Krakowa...'
          : 'Fetching pedestrian geometry...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 400));
      _analysisStatusText = _language == 'pl'
          ? 'Skanowanie schodów i krawężników dla profilu ${_getProfileName()}...'
          : 'Scanning stairs and curbs for ${_getProfileName()}...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      _analysisStatusText = _language == 'pl'
          ? 'Kalkulacja bezpiecznego obejścia KrakAccess...'
          : 'Calculating accessible KrakAccess bypass...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));
    }

    // Sprawdź czy to jeden ze znanych presetów, aby zachować najwyższą precyzję, lub wylicz dynamicznie OSRM
    if (_startLocation.id == 'loc_dworzec' && _destinationLocation.id == 'loc_sukiennice') {
      _routes = RoutingService.getRoutesForPreset('preset_dworzec_rynek', _profile);
    } else if (_startLocation.id == 'loc_wawel' && _destinationLocation.id == 'loc_kazimierz') {
      _routes = RoutingService.getRoutesForPreset('preset_wawel_kazimierz', _profile);
    } else if (_startLocation.id == 'loc_barbakan' && _destinationLocation.id == 'loc_sukiennice') {
      _routes = RoutingService.getRoutesForPreset('preset_barbakan_sukiennice', _profile);
    } else {
      _routes = await RoutingService.calculateDynamicRoute(
        start: _startLocation.point,
        end: _destinationLocation.point,
        profile: _profile,
        startName: _startLocation.namePl,
        destinationName: _destinationLocation.namePl,
      );
    }

    _selectedRouteIndex = 0;
    _isAnalyzingRoute = false;
    notifyListeners();
  }

  String _getProfileName() {
    switch (_profile) {
      case MobilityProfile.wheelchair:
        return _language == 'pl' ? 'Wózek inwalidzki' : 'Wheelchair';
      case MobilityProfile.cane:
        return _language == 'pl' ? 'O kuli / Senior' : 'Cane / Senior';
      case MobilityProfile.stroller:
        return _language == 'pl' ? 'Wózek dziecięcy' : 'Stroller';
    }
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
    _startLocation = KrakowLocation(
      id: spot.id,
      namePl: 'Koperta: ${spot.street}',
      nameEn: 'Disabled spot: ${spot.street}',
      address: spot.street,
      point: spot.location,
      category: 'parking',
    );
    planRouteBetweenSelectedPoints(showLoader: true);
  }
}
