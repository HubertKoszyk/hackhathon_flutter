import 'package:latlong2/latlong.dart';

class ParkingSpot {
  final String id;
  final String street;
  final String district;
  final LatLng location;
  final int spotsCount;
  final bool isOccupied;
  final String note;

  const ParkingSpot({
    required this.id,
    required this.street,
    required this.district,
    required this.location,
    this.spotsCount = 1,
    this.isOccupied = false,
    this.note = 'Koperta z oznakowaniem P-24 / T-29',
  });
}
