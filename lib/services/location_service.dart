import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'krakow_locations.dart';

class LocationService {
  /// Pobiera bieżącą pozycję GPS użytkownika z obsługą uprawnień i fallbackiem
  static Future<KrakowLocation?> getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Jeśli GPS wyłączony w systemie
        return _fallbackKrakowLocation('Lokalizacja GPS wyłączona - użyto centrum Krakowa');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackKrakowLocation('Brak uprawnień GPS - użyto punktu startowego Kraków');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackKrakowLocation('Uprawnienia GPS zablokowane - użyto punktu startowego Kraków');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return KrakowLocation(
        id: 'loc_my_gps',
        namePl: 'Moja bieżąca lokalizacja (GPS)',
        nameEn: 'My Current Location (GPS)',
        address: 'Kraków (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        point: LatLng(position.latitude, position.longitude),
        category: 'gps',
      );
    } catch (_) {
      return _fallbackKrakowLocation('Pozycja startowa Kraków');
    }
  }

  static KrakowLocation _fallbackKrakowLocation(String addressNote) {
    return KrakowLocation(
      id: 'loc_my_gps_fallback',
      namePl: 'Moja lokalizacja (Centrum Krakowa)',
      nameEn: 'My Location (Kraków Center)',
      address: addressNote,
      point: const LatLng(50.0645, 19.9430), // Planty / Dworzec Główny
      category: 'gps',
    );
  }
}
