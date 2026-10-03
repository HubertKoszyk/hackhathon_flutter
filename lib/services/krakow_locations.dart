import 'package:latlong2/latlong.dart';

class KrakowLocation {
  final String id;
  final String namePl;
  final String nameEn;
  final String address;
  final LatLng point;
  final String category; // 'transport', 'historic', 'culture', 'park'

  const KrakowLocation({
    required this.id,
    required this.namePl,
    required this.nameEn,
    required this.address,
    required this.point,
    required this.category,
  });
}

class KrakowLocationsDatabase {
  static const List<KrakowLocation> locations = [
    KrakowLocation(
      id: 'loc_dworzec',
      namePl: 'Dworzec Główny PKP',
      nameEn: 'Main Train Station (Kraków Główny)',
      address: 'ul. Pawia 5a',
      point: LatLng(50.0668, 19.9464),
      category: 'transport',
    ),
    KrakowLocation(
      id: 'loc_sukiennice',
      namePl: 'Sukiennice (Rynek Główny)',
      nameEn: 'Cloth Hall (Main Market Square)',
      address: 'Rynek Główny 1',
      point: LatLng(50.0617, 19.9373),
      category: 'historic',
    ),
    KrakowLocation(
      id: 'loc_wawel',
      namePl: 'Zamek Królewski na Wawelu',
      nameEn: 'Wawel Royal Castle',
      address: 'Wawel 5 / ul. Podzamcze',
      point: LatLng(50.0545, 19.9354),
      category: 'historic',
    ),
    KrakowLocation(
      id: 'loc_kazimierz',
      namePl: 'Plac Nowy (Kazimierz)',
      nameEn: 'Plac Nowy (Jewish Quarter)',
      address: 'Plac Nowy',
      point: LatLng(50.0519, 19.9452),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'loc_barbakan',
      namePl: 'Barbakan i Brama Floriańska',
      nameEn: 'Barbican & St. Florian Gate',
      address: 'ul. Basztowa / Planty',
      point: LatLng(50.0656, 19.9416),
      category: 'historic',
    ),
    KrakowLocation(
      id: 'loc_muzeum_narodowe',
      namePl: 'Muzeum Narodowe w Krakowie',
      nameEn: 'National Museum in Kraków',
      address: 'Al. 3 Maja 1',
      point: LatLng(50.0602, 19.9234),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'loc_blonia',
      namePl: 'Błonia Krakowskie (Park)',
      nameEn: 'Błonia Park',
      address: 'Al. 3 Maja',
      point: LatLng(50.0594, 19.9125),
      category: 'park',
    ),
    KrakowLocation(
      id: 'loc_agh',
      namePl: 'AGH (Miasteczko Studenckie)',
      nameEn: 'AGH University of Science and Technology',
      address: 'Al. Mickiewicza 30',
      point: LatLng(50.0664, 19.9192),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'loc_rondo_mogilskie',
      namePl: 'Rondo Mogilskie (Węzeł przesiadkowy)',
      nameEn: 'Rondo Mogilskie (Transit Hub)',
      address: 'Rondo Mogilskie',
      point: LatLng(50.0661, 19.9597),
      category: 'transport',
    ),
    KrakowLocation(
      id: 'loc_urzad_miasta',
      namePl: 'Urząd Miasta Krakowa (Magistrat)',
      nameEn: 'Kraków City Hall',
      address: 'Plac Wszystkich Świętych 3-4',
      point: LatLng(50.0589, 19.9382),
      category: 'historic',
    ),
    KrakowLocation(
      id: 'loc_bulwary',
      namePl: 'Bulwary Wiślane (Smok Wawelski)',
      nameEn: 'Vistula Boulevards (Wawel Dragon)',
      address: 'Bulwar Czerwieński',
      point: LatLng(50.0531, 19.9333),
      category: 'park',
    ),
    KrakowLocation(
      id: 'loc_tauron_arena',
      namePl: 'Tauron Arena Kraków',
      nameEn: 'Tauron Arena Kraków',
      address: 'ul. Stanisława Lema 7',
      point: LatLng(50.0682, 19.9905),
      category: 'culture',
    ),
  ];

  static List<KrakowLocation> search(String query) {
    if (query.trim().isEmpty) return locations;
    final q = query.toLowerCase().trim();
    return locations.where((loc) {
      return loc.namePl.toLowerCase().contains(q) ||
          loc.nameEn.toLowerCase().contains(q) ||
          loc.address.toLowerCase().contains(q);
    }).toList();
  }
}
