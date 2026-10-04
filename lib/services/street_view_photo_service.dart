import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class StreetViewPhotos {
  final String barrierPhoto;
  final String bypassPhoto;
  final bool isLive;
  final String? photoTitle;
  final String? attribution;

  const StreetViewPhotos({
    required this.barrierPhoto,
    required this.bypassPhoto,
    this.isLive = false,
    this.photoTitle,
    this.attribution,
  });
}

class StreetViewPhotoService {
  /// Pobiera synchronicznie zweryfikowane krakowskie zdjęcia Street View
  /// na podstawie analizy nazwy bariery i odległości od znanych punktów.
  static StreetViewPhotos getPhotosSync({
    required LatLng location,
    required String barrierName,
    required int stairsCount,
    String? startName,
    String? destinationName,
  }) {
    final bLower = barrierName.toLowerCase();
    const dist = Distance();
    final dLubicz = dist.as(
      LengthUnit.Meter,
      location,
      const LatLng(50.0652, 19.9442),
    );
    final dWawel = dist.as(
      LengthUnit.Meter,
      location,
      const LatLng(50.0538, 19.9372),
    );
    final dFlorianska = dist.as(
      LengthUnit.Meter,
      location,
      const LatLng(50.0645, 19.9405),
    );
    final dMogilskie = dist.as(
      LengthUnit.Meter,
      location,
      const LatLng(50.0660, 19.9595),
    );
    final dRynek = dist.as(
      LengthUnit.Meter,
      location,
      const LatLng(50.0617, 19.9373),
    );
    final dKazimierz = dist.as(
      LengthUnit.Meter,
      location,
      const LatLng(50.0519, 19.9452),
    );

    // 1. Schody i tunel pod ul. Lubicz (tylko gdy bariera leży przy Lubicz/tunelu)
    if (bLower.contains('lubicz') ||
        (bLower.contains('tunel') && dLubicz < 280) ||
        dLubicz < 180) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/lubicz_barrier.jpg',
        bypassPhoto: 'assets/streetview/planty_bypass.jpg',
        isLive: false,
        photoTitle: 'Tunel podziemny pod ul. Lubicz',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 2. Schody na Wawelu
    if (bLower.contains('wawel') ||
        bLower.contains('bernardyń') ||
        dWawel < 260) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/wawel_stairs_barrier.jpg',
        bypassPhoto: 'assets/streetview/bernardynska_bypass.jpg',
        isLive: false,
        photoTitle: 'Zejście ze Wzgórza Wawelskiego',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 3. Ulica Floriańska / Brama Floriańska
    if (bLower.contains('floriań') ||
        (bLower.contains('brama') && dFlorianska < 250) ||
        dFlorianska < 180) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/florianska_barrier.jpg',
        bypassPhoto: 'assets/streetview/slawkowska_bypass.jpg',
        isLive: false,
        photoTitle: 'Zabytkowa ul. Floriańska (Bruk)',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 4. Rondo Mogilskie
    if (bLower.contains('mogilsk') || dMogilskie < 300) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/mogilskie_barrier.jpg',
        bypassPhoto: 'assets/streetview/mogilskie_bypass.jpg',
        isLive: false,
        photoTitle: 'Krater Ronda Mogilskiego (-1)',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 5. Rynek Główny / Sukiennice
    if (bLower.contains('sukiennice') ||
        (bLower.contains('rynek') && dRynek < 250) ||
        dRynek < 200) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/sukiennice_barrier.jpg',
        bypassPhoto: 'assets/streetview/sukiennice_bypass.jpg',
        isLive: false,
        photoTitle: 'Podcienia arkad Sukiennic',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 6. Kazimierz / Plac Nowy
    if (bLower.contains('kazimierz') ||
        bLower.contains('plac nowy') ||
        bLower.contains('estery') ||
        dKazimierz < 350) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/kazimierz_barrier.jpg',
        bypassPhoto: 'assets/streetview/kazimierz_bypass.jpg',
        isLive: false,
        photoTitle: 'Zabytkowy Kazimierz (Kocie łby)',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 7. Generyczne schody
    if (stairsCount > 0 ||
        bLower.contains('schod') ||
        bLower.contains('stopn')) {
      return const StreetViewPhotos(
        barrierPhoto: 'assets/streetview/generic_stairs_barrier.jpg',
        bypassPhoto: 'assets/streetview/generic_flat_bypass.jpg',
        isLive: false,
        photoTitle: 'Schody terenowe w Krakowie',
        attribution: 'NavAble Street View Archive',
      );
    }

    // 8. Płaska bariera (krawężnik / nierówna nawierzchnia)
    return const StreetViewPhotos(
      barrierPhoto: 'assets/streetview/kazimierz_barrier.jpg',
      bypassPhoto: 'assets/streetview/generic_flat_bypass.jpg',
      isLive: false,
      photoTitle: 'Nawierzchnia miejska w Krakowie',
      attribution: 'NavAble Street View Archive',
    );
  }

  /// Pobiera w czasie rzeczywistym zdjęcie z Wikimedia Commons GeoSearch
  /// dla dokładnych współrzędnych GPS przeszkody.
  /// W razie braku połączenia lub braku zdjęcia natychmiast używa bazy lokalnej.
  static Future<StreetViewPhotos> getPhotosForLocation({
    required LatLng location,
    required String barrierName,
    required int stairsCount,
    String? startName,
    String? destinationName,
  }) async {
    final localMatch = getPhotosSync(
      location: location,
      barrierName: barrierName,
      stairsCount: stairsCount,
      startName: startName,
      destinationName: destinationName,
    );

    try {
      final geoUrl = Uri.parse(
        'https://commons.wikimedia.org/w/api.php?action=query&generator=geosearch&ggscoord=${location.latitude}|${location.longitude}&ggsradius=450&ggsnamespace=6&ggslimit=5&prop=imageinfo&iiprop=url|extmetadata&format=json',
      );

      final response = await http
          .get(
            geoUrl,
            headers: {'User-Agent': 'NavAble/2.0 (hackathon@krakow.pl)'},
          )
          .timeout(const Duration(milliseconds: 3200));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          for (final page in pages.values) {
            final rawTitle = page['title'] as String? ?? '';
            final imgInfo = (page['imageinfo'] as List?)?.first;
            final realPhotoUrl = imgInfo?['url'] as String?;

            if (realPhotoUrl != null &&
                (realPhotoUrl.endsWith('.jpg') ||
                    realPhotoUrl.endsWith('.jpeg') ||
                    realPhotoUrl.endsWith('.png') ||
                    realPhotoUrl.contains('.jpg?') ||
                    realPhotoUrl.contains('.png?'))) {
              // Czytelny tytuł zdjęcia
              final cleanTitle = rawTitle
                  .replaceFirst('File:', '')
                  .replaceAll('_', ' ')
                  .trim();

              // Autor / fotograf
              String cleanArtist = 'Wikimedia Commons (CC-BY-SA)';
              final ext = imgInfo?['extmetadata'] as Map<String, dynamic>?;
              final artistRaw = ext?['Artist']?['value'] as String?;
              if (artistRaw != null && artistRaw.isNotEmpty) {
                final stripped = artistRaw
                    .replaceAll(RegExp(r'<[^>]*>'), '')
                    .trim();
                if (stripped.isNotEmpty) {
                  cleanArtist = stripped;
                }
              }

              return StreetViewPhotos(
                barrierPhoto: realPhotoUrl,
                bypassPhoto: localMatch.bypassPhoto,
                isLive: true,
                photoTitle: cleanTitle,
                attribution: cleanArtist,
              );
            }
          }
        }
      }
    } catch (_) {
      // Przy braku sieci lub timeout natychmiast użyj zweryfikowanego zdjęcia lokalnego
    }

    return localMatch;
  }
}
