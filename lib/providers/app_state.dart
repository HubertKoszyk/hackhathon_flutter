import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_translations.dart';
import '../models/accessibility_audit.dart';
import '../models/accessible_place.dart';
import '../models/navigation_step.dart';
import '../models/parking_spot.dart';
import '../models/route_model.dart';
import '../services/krakow_data_service.dart';
import '../services/krakow_locations.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/routing_service.dart';

enum MobilityProfile { wheelchair, cane, stroller }

class AppState extends ChangeNotifier {
  String _language = 'pl';
  MobilityProfile _profile = MobilityProfile.wheelchair;
  bool _showParkingLayer = true;
  bool _showAccessiblePlacesLayer = true;
  String _placeCategoryFilter = 'all'; // 'all', 'hotel', 'building'
  final String _selectedPresetId = 'preset_dworzec_rynek';
  int _selectedRouteIndex = 0; // 0 = Accessible, 1 = Standard
  ParkingSpot? _selectedParking;
  AccessiblePlace? _selectedAccessiblePlace;
  AccessibilityAudit? _activeAudit;
  LatLng? _customPin;

  // GPS i bieżąca lokalizacja
  bool _isLocatingUser = false;
  LatLng? _userCurrentGpsPoint;

  // Wyszukiwanie punktu A i B
  KrakowLocation _startLocation = const KrakowLocation(
    id: 'loc_my_gps',
    namePl: 'Moja lokalizacja (Planty / Dworzec Główny)',
    nameEn: 'My location (Planty / Dworzec Główny)',
    nameUk: 'Моє місцезнаходження (Planty / Dworzec Główny)',
    address: 'Kraków, Planty / Dworzec Główny',
    point: LatLng(50.0645, 19.9430),
    category: 'gps',
  );
  KrakowLocation? _destinationLocation; // Puste przy starcie aplikacji
  bool _isAnalyzingRoute = false;
  String _analysisStatusText = '';

  // --- NAWIGACJA NA ŻYWO (Google Maps Turn-by-Turn Live) ---
  bool _isNavigating = false;
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  LatLng? _navigationUserPosition;
  double _navigationBearing = 0.0;
  double _distanceToNextStep = 0.0;
  double _remainingDistance = 0.0;
  int _remainingDurationSeconds = 0;
  bool _hasReachedDestination = false;
  bool _isSimulatingNavigation = true;
  double _simulationSpeedMultiplier = 1.0;
  bool _isVoiceMuted = false;
  double _currentWalkingSpeedKmh = 4.2;
  String? _approachingHazardAlert;
  Timer? _navigationTimer;
  int _simCoordIndex = 0;
  double _simSegmentFraction = 0.0;
  bool _shouldRecenterMap = false;

  late List<ParkingSpot> _parkingSpots;
  late List<AccessiblePlace> _accessiblePlaces;
  List<RouteModel> _routes = [];

  AppState() {
    _parkingSpots = KrakowDataService.getParkingSpots();
    _accessiblePlaces = KrakowDataService.getAccessiblePlaces();
    _routes = [];
    useCurrentLocationAsStart(calculateRoute: false);
  }

  // Getters
  String get language => _language;
  MobilityProfile get profile => _profile;
  bool get showParkingLayer => _showParkingLayer;
  bool get showAccessiblePlacesLayer => _showAccessiblePlacesLayer;
  String get placeCategoryFilter => _placeCategoryFilter;
  String get selectedPresetId => _selectedPresetId;
  int get selectedRouteIndex => _selectedRouteIndex;
  ParkingSpot? get selectedParking => _selectedParking;
  AccessiblePlace? get selectedAccessiblePlace => _selectedAccessiblePlace;
  AccessibilityAudit? get activeAudit => _activeAudit;
  LatLng? get customPin => _customPin;
  bool get isLocatingUser => _isLocatingUser;
  LatLng? get userCurrentGpsPoint => _userCurrentGpsPoint;
  KrakowLocation get startLocation => _startLocation;
  KrakowLocation? get destinationLocation => _destinationLocation;
  bool get isAnalyzingRoute => _isAnalyzingRoute;
  String get analysisStatusText => _analysisStatusText;

  // Getters Nawigacji na żywo
  bool get isNavigating => _isNavigating;
  List<NavigationStep> get navigationSteps => _navigationSteps;
  int get currentStepIndex => _currentStepIndex;
  NavigationStep? get currentStep =>
      (_navigationSteps.isNotEmpty &&
          _currentStepIndex < _navigationSteps.length)
      ? _navigationSteps[_currentStepIndex]
      : null;
  NavigationStep? get nextStep =>
      (_navigationSteps.isNotEmpty &&
          _currentStepIndex + 1 < _navigationSteps.length)
      ? _navigationSteps[_currentStepIndex + 1]
      : null;
  LatLng? get navigationUserPosition => _navigationUserPosition;
  double get navigationBearing => _navigationBearing;
  double get distanceToNextStep => _distanceToNextStep;
  double get remainingDistance => _remainingDistance;
  int get remainingDurationSeconds => _remainingDurationSeconds;
  bool get hasReachedDestination => _hasReachedDestination;
  bool get isSimulatingNavigation => _isSimulatingNavigation;
  double get simulationSpeedMultiplier => _simulationSpeedMultiplier;
  bool get isVoiceMuted => _isVoiceMuted;
  double get currentWalkingSpeedKmh => _currentWalkingSpeedKmh;
  String? get approachingHazardAlert => _approachingHazardAlert;
  bool get shouldRecenterMap => _shouldRecenterMap;

  List<ParkingSpot> get parkingSpots => _parkingSpots;
  List<AccessiblePlace> get accessiblePlaces {
    if (_placeCategoryFilter == 'hotel') {
      return _accessiblePlaces
          .where((p) => p.category == AccessiblePlaceCategory.hotel)
          .toList();
    } else if (_placeCategoryFilter == 'building') {
      return _accessiblePlaces
          .where((p) => p.category != AccessiblePlaceCategory.hotel)
          .toList();
    }
    return _accessiblePlaces;
  }
  List<AccessiblePlace> get allAccessiblePlaces => _accessiblePlaces;
  List<RouteModel> get routes => _routes;
  RouteModel? get currentRoute =>
      _routes.isNotEmpty ? _routes[_selectedRouteIndex] : null;

  String tr(String key) => AppTranslations.tr(key, _language);

  // Actions
  void toggleLanguage() {
    if (_language == 'pl') {
      _language = 'en';
    } else if (_language == 'en') {
      _language = 'uk';
    } else {
      _language = 'pl';
    }
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  Future<void> setProfile(MobilityProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();

    // Jeśli punkt docelowy jest wybrany lub trasa została wyznaczona,
    // natychmiast przeliczamy trasę z widocznym ekranem ładowania pod nowy profil!
    if (_destinationLocation != null || _routes.isNotEmpty) {
      await planRouteBetweenSelectedPoints(showLoader: true);
    }
  }

  void toggleParkingLayer() {
    _showParkingLayer = !_showParkingLayer;
    notifyListeners();
  }

  void toggleAccessiblePlacesLayer() {
    _showAccessiblePlacesLayer = !_showAccessiblePlacesLayer;
    notifyListeners();
  }

  void setPlaceCategoryFilter(String filter) {
    _placeCategoryFilter = filter;
    notifyListeners();
  }

  void selectRoute(int index) {
    if (index >= 0 && index < _routes.length) {
      _selectedRouteIndex = index;
      notifyListeners();
    }
  }

  void clearRoutes() {
    _routes = [];
    _selectedRouteIndex = 0;
    _isAnalyzingRoute = false;
    notifyListeners();
  }

  void selectParking(ParkingSpot? spot) {
    _selectedParking = spot;
    if (spot != null) {
      _selectedAccessiblePlace = null;
    }
    notifyListeners();
  }

  void selectAccessiblePlace(AccessiblePlace? place) {
    _selectedAccessiblePlace = place;
    if (place != null) {
      _selectedParking = null;
    }
    notifyListeners();
  }

  void setStartLocation(KrakowLocation loc, {bool calculateRoute = false}) {
    _startLocation = loc;
    notifyListeners();
    if (calculateRoute && _destinationLocation != null) {
      planRouteBetweenSelectedPoints(showLoader: true);
    }
  }

  void setDestinationLocation(
    KrakowLocation? loc, {
    bool calculateRoute = false,
  }) {
    _destinationLocation = loc;
    notifyListeners();
    if (calculateRoute && loc != null) {
      planRouteBetweenSelectedPoints(showLoader: true);
    }
  }

  void swapLocations({bool calculateRoute = false}) {
    if (_destinationLocation == null) return;
    final temp = _startLocation;
    _startLocation = _destinationLocation!;
    _destinationLocation = temp;
    notifyListeners();
    if (calculateRoute) {
      planRouteBetweenSelectedPoints(showLoader: true);
    }
  }

  void setCustomPin(LatLng point) {
    _customPin = point;
    _destinationLocation = KrakowLocation(
      id: 'loc_custom_${DateTime.now().millisecondsSinceEpoch}',
      namePl:
          'Punkt na mapie (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})',
      nameEn:
          'Map point (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})',
      address: 'Kraków (współrzędne GPS)',
      point: point,
      category: 'map',
    );
    notifyListeners();
    planRouteBetweenSelectedPoints(showLoader: true);
  }

  void clearCustomPin() {
    _customPin = null;
    notifyListeners();
  }

  /// Pobiera pozycję GPS i ustawia ją jako punkt startowy
  Future<void> useCurrentLocationAsStart({bool calculateRoute = false}) async {
    _isLocatingUser = true;
    notifyListeners();

    final userLoc = await LocationService.getCurrentUserLocation();
    if (userLoc != null) {
      _startLocation = userLoc;
      _userCurrentGpsPoint = userLoc.point;
      _isLocatingUser = false;
      notifyListeners();
      if (calculateRoute && _destinationLocation != null) {
        await planRouteBetweenSelectedPoints(showLoader: true);
      }
    } else {
      _isLocatingUser = false;
      notifyListeners();
    }
  }

  /// Główna metoda kalkulacji trasy z analizą AI Gemini i wykrywaniem barier
  Future<void> planRouteBetweenSelectedPoints({bool showLoader = true}) async {
    if (_destinationLocation == null) {
      _routes = [];
      _isAnalyzingRoute = false;
      notifyListeners();
      return;
    }

    _selectedParking = null;

    if (showLoader) {
      _isAnalyzingRoute = true;
      _analysisStatusText = _language == 'uk'
          ? 'Gemini 3.8 AI: Сканування бар’єрів для профілю: ${_getProfileName()}...'
          : (_language == 'pl'
                ? 'Gemini 3.8 AI: Skanowanie barier dla profilu: ${_getProfileName()}...'
                : 'Gemini 3.8 AI: Scanning barriers for profile: ${_getProfileName()}...');
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 350));
      _analysisStatusText = _language == 'uk'
          ? 'Прокладання оптимального безбар’єрного маршруту...'
          : (_language == 'pl'
                ? 'Wyznaczanie optymalnej trasy bez przeszkód...'
                : 'Calculating optimal barrier-free route...');
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final sId = _startLocation.id;
    final dId = _destinationLocation!.id;

    if (sId == 'loc_dworzec' && dId == 'loc_sukiennice') {
      _routes = RoutingService.getRoutesForPreset(
        'preset_dworzec_rynek',
        _profile,
      );
    } else if (sId == 'loc_sukiennice' && dId == 'loc_dworzec') {
      _routes = RoutingService.getRoutesForPreset(
        'preset_dworzec_rynek',
        _profile,
        reversed: true,
      );
    } else if (sId == 'loc_wawel' && dId == 'loc_kazimierz') {
      _routes = RoutingService.getRoutesForPreset(
        'preset_wawel_kazimierz',
        _profile,
      );
    } else if (sId == 'loc_kazimierz' && dId == 'loc_wawel') {
      _routes = RoutingService.getRoutesForPreset(
        'preset_wawel_kazimierz',
        _profile,
        reversed: true,
      );
    } else if (sId == 'loc_barbakan' && dId == 'loc_sukiennice') {
      _routes = RoutingService.getRoutesForPreset(
        'preset_barbakan_sukiennice',
        _profile,
      );
    } else if (sId == 'loc_sukiennice' && dId == 'loc_barbakan') {
      _routes = RoutingService.getRoutesForPreset(
        'preset_barbakan_sukiennice',
        _profile,
        reversed: true,
      );
    } else {
      if (showLoader) {
        _analysisStatusText = _language == 'uk'
            ? 'Калькуляція пологого обходу та GTFS...'
            : (_language == 'pl'
                  ? 'Kalkulacja płaskiego obejścia i GTFS...'
                  : 'Calculating accessible bypass & GTFS...');
        notifyListeners();
      }
      _routes = await RoutingService.calculateDynamicRoute(
        start: _startLocation.point,
        end: _destinationLocation!.point,
        profile: _profile,
        startName: _startLocation.localizedName(_language),
        destinationName: _destinationLocation!.localizedName(_language),
      );
    }

    if (showLoader) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Domyślnie zaznaczamy trasę komunikacji miejskiej GTFS (tramwaj/autobus),
    // jeśli jest dostępna, aby użytkownik od razu widział opcję tramwajową!
    final transitIdx = _routes.indexWhere((r) => r.isTransit);
    if (transitIdx != -1) {
      _selectedRouteIndex = transitIdx;
    } else {
      _selectedRouteIndex = 0;
    }
    _isAnalyzingRoute = false;
    notifyListeners();
  }

  String _getProfileName() {
    switch (_profile) {
      case MobilityProfile.wheelchair:
        if (_language == 'uk') return 'Крісло колісне';
        return _language == 'pl' ? 'Wózek inwalidzki' : 'Wheelchair';
      case MobilityProfile.cane:
        if (_language == 'uk') return 'З тростиною';
        return _language == 'pl' ? 'O kuli / Senior' : 'Cane / Senior';
      case MobilityProfile.stroller:
        if (_language == 'uk') return 'Дитячий візок';
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

  void planRouteToAccessiblePlace(AccessiblePlace place) {
    _selectedAccessiblePlace = null;
    _destinationLocation = place.toKrakowLocation();
    planRouteBetweenSelectedPoints(showLoader: true);
  }

  void planRouteToParking(ParkingSpot spot) {
    _selectedParking = null;
    _destinationLocation = KrakowLocation(
      id: spot.id,
      namePl: 'Koperta: ${spot.street}',
      nameEn: 'Disabled spot: ${spot.street}',
      address: spot.street,
      point: spot.location,
      category: 'parking',
    );
    planRouteBetweenSelectedPoints(showLoader: true);
  }

  // ==========================================
  // NAWIGACJA NA ŻYWO (LIVE TURN-BY-TURN ENGINE)
  // ==========================================

  void startNavigation() {
    final route = currentRoute;
    if (route == null || route.coordinates.isEmpty) return;

    _isNavigating = true;
    _hasReachedDestination = false;
    _navigationSteps = NavigationService.generateStepsForRoute(route, _profile);
    _currentStepIndex = 0;
    _simCoordIndex = 0;
    _simSegmentFraction = 0.0;
    _navigationUserPosition = route.coordinates.first;
    _remainingDistance = route.distanceMeters.toDouble();
    _remainingDurationSeconds = route.durationMinutes * 60;
    _currentWalkingSpeedKmh = 4.2;
    _shouldRecenterMap = true;
    _approachingHazardAlert = null;

    if (route.coordinates.length > 1) {
      _navigationBearing = NavigationService.calculateBearing(
        route.coordinates[0],
        route.coordinates[1],
      );
      _distanceToNextStep = const Distance()
          .as(
            LengthUnit.Meter,
            _navigationUserPosition!,
            _navigationSteps.isNotEmpty
                ? _navigationSteps[0].point
                : route.coordinates[1],
          )
          .toDouble();
    }

    _startNavigationTicker();
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _approachingHazardAlert = null;
    _hasReachedDestination = false;
    notifyListeners();
  }

  void toggleSimulationPlayPause() {
    _isSimulatingNavigation = !_isSimulatingNavigation;
    notifyListeners();
  }

  void setSimulationSpeed(double speed) {
    _simulationSpeedMultiplier = speed;
    notifyListeners();
  }

  void toggleVoiceMute() {
    _isVoiceMuted = !_isVoiceMuted;
    notifyListeners();
  }

  void triggerRecenterMap() {
    _shouldRecenterMap = true;
    notifyListeners();
  }

  void clearRecenterMapFlag() {
    _shouldRecenterMap = false;
  }

  void _startNavigationTicker() {
    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(milliseconds: 650), (
      timer,
    ) {
      if (!_isNavigating || currentRoute == null) {
        timer.cancel();
        return;
      }

      if (!_isSimulatingNavigation) return; // pauza symulacji marszu

      final coords = currentRoute!.coordinates;
      if (coords.length < 2) return;

      const dist = Distance();
      // Ruch pieszego: prędkość marszu ~1.2 m/s * mnożnik (1x, 2x, 4x) * dt (0.65s)
      final stepDistanceMeters = 1.35 * _simulationSpeedMultiplier * 0.65;

      // Płynna interpolacja pozycji wzdłuż krawędzi polyline
      final p1 = coords[_simCoordIndex];
      final p2 = coords[_simCoordIndex + 1];
      final segmentLength = dist.as(LengthUnit.Meter, p1, p2).toDouble();

      final fractionIncrement = (segmentLength > 0.5)
          ? (stepDistanceMeters / segmentLength)
          : 1.0;
      _simSegmentFraction += fractionIncrement;

      if (_simSegmentFraction >= 1.0) {
        _simSegmentFraction = 0.0;
        _simCoordIndex++;

        if (_simCoordIndex >= coords.length - 1) {
          // Dotarto do celu!
          _navigationUserPosition = coords.last;
          _hasReachedDestination = true;
          _remainingDistance = 0;
          _remainingDurationSeconds = 0;
          _currentStepIndex = _navigationSteps.length - 1;
          _navigationTimer?.cancel();
          notifyListeners();
          return;
        }
      }

      // Oblicz bieżącą pozycję użytkownika (interpolowaną w czasie rzeczywistym)
      final curP1 = coords[_simCoordIndex];
      final curP2 = coords[_simCoordIndex + 1];
      _navigationUserPosition = LatLng(
        curP1.latitude +
            (curP2.latitude - curP1.latitude) * _simSegmentFraction,
        curP1.longitude +
            (curP2.longitude - curP1.longitude) * _simSegmentFraction,
      );

      // Oblicz bearing (kierunek nawigacyjny strzałki)
      _navigationBearing = NavigationService.calculateBearing(curP1, curP2);

      // Oblicz dystans do najbliższego manewru
      if (_currentStepIndex < _navigationSteps.length) {
        final targetStepPoint = _navigationSteps[_currentStepIndex].point;
        _distanceToNextStep = dist
            .as(LengthUnit.Meter, _navigationUserPosition!, targetStepPoint)
            .toDouble();

        // Jeśli zbliżyliśmy się na mniej niż 16m do manewru, przejdź do kolejnego manewru
        if (_distanceToNextStep < 16 &&
            _currentStepIndex < _navigationSteps.length - 1) {
          _currentStepIndex++;
        }
      }

      // Oblicz pozostały dystans do mety
      double remaining = 0;
      for (int i = _simCoordIndex; i < coords.length - 1; i++) {
        if (i == _simCoordIndex) {
          remaining += dist.as(
            LengthUnit.Meter,
            _navigationUserPosition!,
            coords[i + 1],
          );
        } else {
          remaining += dist.as(LengthUnit.Meter, coords[i], coords[i + 1]);
        }
      }
      _remainingDistance = remaining;
      _remainingDurationSeconds = (remaining / 1.15).round().clamp(0, 9999);
      _currentWalkingSpeedKmh =
          (3.8 +
                  (_simulationSpeedMultiplier > 1
                      ? _simulationSpeedMultiplier * 1.5
                      : 0))
              .clamp(2.5, 18.0);

      // Sprawdź czy zbliżamy się do przeszkody / objazdu (alert HUD)
      final audits = currentRoute!.audits;
      String? alert;
      for (final a in audits) {
        final dAudit = dist.as(
          LengthUnit.Meter,
          _navigationUserPosition!,
          a.location,
        );
        if (dAudit < 60) {
          if (a.isAccessible) {
            alert = _language == 'pl'
                ? 'PŁASKI OBJAZD: Za ${dAudit.round()} m zjedź zlicowaną rampą 0 cm'
                : 'FLAT BYPASS: In ${dAudit.round()} m take flush 0 cm ramp';
          } else {
            alert = _language == 'pl'
                ? 'UWAGA NA PRZESZKODĘ: Za ${dAudit.round()} m ${a.checkpointName}'
                : 'OBSTACLE AHEAD: In ${dAudit.round()} m ${a.checkpointName}';
          }
          break;
        }
      }
      _approachingHazardAlert = alert;

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }
}
