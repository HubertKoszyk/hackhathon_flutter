import 'package:latlong2/latlong.dart';

class KrakowLocation {
  final String id;
  final String namePl;
  final String nameEn;
  final String? nameUk;
  final String address;
  final LatLng point;
  final String category; // 'transport', 'historic', 'culture', 'park'

  const KrakowLocation({
    required this.id,
    required this.namePl,
    required this.nameEn,
    this.nameUk,
    required this.address,
    required this.point,
    required this.category,
  });

  String localizedName(String lang) {
    if (category == 'gps') {
      if (lang == 'uk') return nameUk ?? namePl;
      if (lang == 'en') return nameEn;
      return namePl;
    }
    // Nazwy własne w Krakowie pozostają zawsze oryginalne w języku polskim
    return namePl;
  }
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
    // HOTELE BEZ BARIER
    KrakowLocation(
      id: 'place_hotel_radisson',
      namePl: 'Hotel Radisson Blu Kraków (Bez barier)',
      nameEn: 'Radisson Blu Hotel Krakow (Accessible)',
      address: 'ul. Straszewskiego 17',
      point: LatLng(50.0578, 19.9329),
      category: 'hotel',
    ),
    KrakowLocation(
      id: 'place_hotel_sheraton',
      namePl: 'Hotel Sheraton Grand Kraków (Bez barier)',
      nameEn: 'Sheraton Grand Krakow (Accessible)',
      address: 'ul. Powiśle 7',
      point: LatLng(50.0535, 19.9320),
      category: 'hotel',
    ),
    KrakowLocation(
      id: 'place_hotel_puro_stare_miasto',
      namePl: 'Hotel PURO Stare Miasto (Bez barier)',
      nameEn: 'PURO Hotel Old Town (Accessible)',
      address: 'ul. Ogrodowa 10',
      point: LatLng(50.0678, 19.9442),
      category: 'hotel',
    ),
    KrakowLocation(
      id: 'place_hotel_stary',
      namePl: 'Hotel Stary (Zabytkowy z windą)',
      nameEn: 'Hotel Stary (Historic Accessible)',
      address: 'ul. Szczepańska 5',
      point: LatLng(50.0628, 19.9362),
      category: 'hotel',
    ),
    KrakowLocation(
      id: 'place_hotel_mercure',
      namePl: 'Hotel Mercure Stare Miasto (Dworzec Główny)',
      nameEn: 'Mercure Hotel Old Town (Accessible)',
      address: 'ul. Pawia 18b',
      point: LatLng(50.0692, 19.9460),
      category: 'hotel',
    ),
    KrakowLocation(
      id: 'place_hotel_puro_kazimierz',
      namePl: 'Hotel PURO Kazimierz (Bez barier)',
      nameEn: 'PURO Hotel Kazimierz (Accessible)',
      address: 'ul. Halicka 14a',
      point: LatLng(50.0520, 19.9498),
      category: 'hotel',
    ),
    // BUDYNKI KULTURY I UŻYTECZNOŚCI
    KrakowLocation(
      id: 'place_ice_krakow',
      namePl: 'Centrum Kongresowe ICE Kraków',
      nameEn: 'ICE Krakow Congress Centre',
      address: 'ul. Marii Konopnickiej 17',
      point: LatLng(50.0483, 19.9312),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'place_mocak',
      namePl: 'MOCAK Muzeum Sztuki Współczesnej',
      nameEn: 'MOCAK Museum of Contemporary Art',
      address: 'ul. Lipowa 4',
      point: LatLng(50.0474, 19.9609),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'place_teatr_slowackiego',
      namePl: 'Teatr im. Juliusza Słowackiego',
      nameEn: 'Juliusz Slowacki Theatre',
      address: 'Plac Świętego Ducha 1',
      point: LatLng(50.0638, 19.9427),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'place_cricoteka',
      namePl: 'Cricoteka - Ośrodek T. Kantora',
      nameEn: 'Cricoteka Centre for Art',
      address: 'ul. Nadwiślańska 2-4',
      point: LatLng(50.0453, 19.9525),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'place_mos_rajska',
      namePl: 'Małopolski Ogród Sztuki (MOS)',
      nameEn: 'Malopolska Garden of Arts',
      address: 'ul. Rajska 12',
      point: LatLng(50.0642, 19.9298),
      category: 'culture',
    ),
    KrakowLocation(
      id: 'place_biblioteka_rajska',
      namePl: 'Wojewódzka Biblioteka Publiczna (Dział Tyflologiczny)',
      nameEn: 'Voivodeship Public Library (Braille Dept.)',
      address: 'ul. Rajska 1',
      point: LatLng(50.0645, 19.9312),
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
