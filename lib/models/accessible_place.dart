import 'package:latlong2/latlong.dart';
import '../services/krakow_locations.dart';

enum AccessiblePlaceCategory {
  hotel,
  culture,
  publicBuilding,
  attraction,
}

class AccessiblePlace {
  final String id;
  final String name;
  final AccessiblePlaceCategory category;
  final String categoryLabelPl;
  final String categoryLabelEn;
  final String address;
  final String district;
  final LatLng location;
  final String descriptionPl;
  final String descriptionEn;
  final int accessibilityScore; // 0 - 100
  final List<String> accessibilityHighlightsPl;
  final List<String> accessibilityHighlightsEn;
  final bool hasWheelchairAccess;
  final bool hasHearingLoop;
  final bool hasBrailleOrAudio;
  final bool hasAdaptedRooms; // Pokoje dla niepełnosprawnych w hotelach
  final bool hasAdaptedRestroom;
  final bool hasAssistanceDogWelcome;
  final bool hasDedicatedParking;
  final String websiteUrl;
  final String? instagramUrl;
  final String? instagramHandle;
  final String? facebookUrl;
  final String? facebookName;
  final String? phoneNumber;

  const AccessiblePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryLabelPl,
    required this.categoryLabelEn,
    required this.address,
    required this.district,
    required this.location,
    required this.descriptionPl,
    required this.descriptionEn,
    this.accessibilityScore = 95,
    required this.accessibilityHighlightsPl,
    required this.accessibilityHighlightsEn,
    this.hasWheelchairAccess = true,
    this.hasHearingLoop = true,
    this.hasBrailleOrAudio = true,
    this.hasAdaptedRooms = false,
    this.hasAdaptedRestroom = true,
    this.hasAssistanceDogWelcome = true,
    this.hasDedicatedParking = true,
    required this.websiteUrl,
    this.instagramUrl,
    this.instagramHandle,
    this.facebookUrl,
    this.facebookName,
    this.phoneNumber,
  });

  /// Konwersja do obiektu KrakowLocation w celu integracji z silnikiem tras
  KrakowLocation toKrakowLocation() {
    return KrakowLocation(
      id: id,
      namePl: name,
      nameEn: name,
      address: address,
      point: location,
      category: category == AccessiblePlaceCategory.hotel ? 'hotel' : 'culture',
    );
  }
}
