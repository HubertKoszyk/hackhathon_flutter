import 'package:latlong2/latlong.dart';
import '../models/parking_spot.dart';

class KrakowDataService {
  /// Krakowskie miejsca postojowe dla osób z niepełnosprawnościami (koperty)
  /// Dane oparte o zasoby miejskie Krakowa (MSIP / ZDMK)
  static final List<ParkingSpot> disabledParkingSpots = [
    const ParkingSpot(
      id: 'krk_park_01',
      street: 'ul. Pawia 5 (Dworzec Główny)',
      district: 'Stare Miasto',
      location: LatLng(50.0668, 19.9464),
      spotsCount: 4,
      isOccupied: false,
      note: 'Dedykowany dojazd do peronów i Galerii Krakowskiej. Winda 20m obok.',
    ),
    const ParkingSpot(
      id: 'krk_park_02',
      street: 'Plac Jana Matejki 8',
      district: 'Stare Miasto',
      location: LatLng(50.0662, 19.9423),
      spotsCount: 2,
      isOccupied: false,
      note: 'Płaski zjazd na Planty w stronę Barbakanu.',
    ),
    const ParkingSpot(
      id: 'krk_park_03',
      street: 'ul. Szpitalna 15',
      district: 'Stare Miasto',
      location: LatLng(50.0631, 19.9398),
      spotsCount: 2,
      isOccupied: true,
      note: 'Blisko Teatru Słowackiego. Nawierzchnia asfaltowa.',
    ),
    const ParkingSpot(
      id: 'krk_park_04',
      street: 'Plac Szczepański 3',
      district: 'Stare Miasto',
      location: LatLng(50.0638, 19.9351),
      spotsCount: 3,
      isOccupied: false,
      note: 'Szeroki wjazd, obniżone krawężniki 1.5 cm.',
    ),
    const ParkingSpot(
      id: 'krk_park_05',
      street: 'Plac Wszystkich Świętych (Urząd Miasta)',
      district: 'Stare Miasto',
      location: LatLng(50.0589, 19.9382),
      spotsCount: 4,
      isOccupied: false,
      note: 'Pod samym Magistratem. Bezpośredni podjazd windą dla interesantów.',
    ),
    const ParkingSpot(
      id: 'krk_park_06',
      street: 'ul. Podzamcze 2 (Wawel)',
      district: 'Stare Miasto',
      location: LatLng(50.0545, 19.9354),
      spotsCount: 3,
      isOccupied: false,
      note: 'Dojście do Zamku Królewskiego i Centrum Informacji Turystycznej.',
    ),
    const ParkingSpot(
      id: 'krk_park_07',
      street: 'ul. Szeroka 24 (Kazimierz)',
      district: 'Kazimierz',
      location: LatLng(50.0526, 19.9482),
      spotsCount: 2,
      isOccupied: false,
      note: 'Zmodernizowana nawierzchnia, obniżone krawężniki przy synagodze.',
    ),
    const ParkingSpot(
      id: 'krk_park_08',
      street: 'Plac Wolnica 1',
      district: 'Kazimierz',
      location: LatLng(50.0489, 19.9442),
      spotsCount: 3,
      isOccupied: false,
      note: 'Równa nawierzchnia płytowa, bez barier architektonicznych.',
    ),
    const ParkingSpot(
      id: 'krk_park_09',
      street: 'ul. Poselska 10',
      district: 'Stare Miasto',
      location: LatLng(50.0581, 19.9365),
      spotsCount: 1,
      isOccupied: false,
      note: 'Koperta przy Muzeum Archeologicznym.',
    ),
    const ParkingSpot(
      id: 'krk_park_10',
      street: 'ul. Basztowa 20',
      district: 'Kleparz',
      location: LatLng(50.0674, 19.9405),
      spotsCount: 2,
      isOccupied: false,
      note: 'Przy Urzędzie Wojewódzkim. Podjazd przystosowany pod vany z rampą.',
    ),
  ];

  static List<ParkingSpot> getParkingSpots() {
    return disabledParkingSpots;
  }
}
