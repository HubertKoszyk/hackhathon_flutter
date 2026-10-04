import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'krakow_locations.dart';

class LocationService {
  /// Pobiera bieżącą pozycję GPS użytkownika z obsługą uprawnień i fallbackiem
  static Future<KrakowLocation?> getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackKrakowLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackKrakowLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackKrakowLocation();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final userPoint = LatLng(position.latitude, position.longitude);
      final closestPlace = _getClosestPlaceName(userPoint);

      return KrakowLocation(
        id: 'loc_my_gps',
        namePl: 'Moja lokalizacja ($closestPlace)',
        nameEn: 'My location ($closestPlace)',
        nameUk: 'Моє місцезнаходження ($closestPlace)',
        address: 'Kraków, $closestPlace',
        point: userPoint,
        category: 'gps',
      );
    } catch (_) {
      return _fallbackKrakowLocation();
    }
  }

  static KrakowLocation _fallbackKrakowLocation() {
    const fallbackPoint = LatLng(50.0645, 19.9430);
    const closestPlace = 'Planty / Dworzec Główny';

    return const KrakowLocation(
      id: 'loc_my_gps_fallback',
      namePl: 'Moja lokalizacja ($closestPlace)',
      nameEn: 'My location ($closestPlace)',
      nameUk: 'Моє місцезнаходження ($closestPlace)',
      address: 'Kraków, $closestPlace',
      point: fallbackPoint,
      category: 'gps',
    );
  }

  /// Wyznacza orientacyjną nazwę miejsca w Krakowie (nazwy własne zawsze oryginalne, nietłumaczone)
  static String _getClosestPlaceName(LatLng point) {
    final knownPlaces = [
      (const LatLng(50.0668, 19.9464), 'Dworzec Główny / Galeria Krakowska'),
      (const LatLng(50.0645, 19.9430), 'Planty / Teatr Słowackiego'),
      (const LatLng(50.0617, 19.9373), 'Rynek Główny'),
      (const LatLng(50.0545, 19.9354), 'Wawel'),
      (const LatLng(50.0519, 19.9452), 'Kazimierz / Plac Nowy'),
      (const LatLng(50.0656, 19.9416), 'Barbakan / Brama Floriańska'),
      (const LatLng(50.0602, 19.9234), 'Muzeum Narodowe'),
      (const LatLng(50.0664, 19.9192), 'Miasteczko AGH'),
      (const LatLng(50.0661, 19.9597), 'Rondo Mogilskie'),
      (const LatLng(50.0682, 19.9905), 'Tauron Arena'),
      (const LatLng(50.0531, 19.9333), 'Bulwary Wiślane'),
    ];

    const distanceCalc = Distance();
    double minDistance = double.infinity;
    String best = 'Centrum Krakowa';

    for (final place in knownPlaces) {
      final d = distanceCalc.as(LengthUnit.Meter, point, place.$1);
      if (d < minDistance) {
        minDistance = d;
        best = place.$2;
      }
    }

    return best;
  }
}
