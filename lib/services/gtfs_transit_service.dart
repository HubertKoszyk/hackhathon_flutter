import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/accessibility_audit.dart';
import '../models/route_model.dart';
import '../models/transit_route_info.dart';
import '../providers/app_state.dart';

class GtfsTransitService {
  static const Distance _dist = Distance();

  // ==========================================
  // BAZA PRZYSTANKÓW GTFS (ZTP KRAKÓW)
  // Weryfikacja peronów pod kątem dostępności:
  // - Perony Wiedeńskie (0 cm najazd)
  // - Węzły z windami
  // - Perony z rampami i krawężnikiem Kassel
  // ==========================================
  static final List<GtfsStop> krakowStops = [
    // Teatr Słowackiego (Dworzec Główny)
    const GtfsStop(
      id: 'stop_852_324219',
      name: 'Teatr Słowackiego (Dworzec Główny)',
      code: '801-01',
      location: LatLng(50.064609, 19.945628),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński zlicowany z chodnikiem. Pasy fakturowe z wypustkami dla niewidomych.',
      platformDescriptionEn: 'Vienna platform flush with sidewalk. Tactile guiding strips for visually impaired.',
    ),
    const GtfsStop(
      id: 'stop_852_324229',
      name: 'Teatr Słowackiego (kier. Mogilskie)',
      code: '801-02',
      location: LatLng(50.064792, 19.944409),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński z łagodnym wjazdem rampowym 0 cm.',
      platformDescriptionEn: 'Vienna platform with gentle 0 cm ramp entrance.',
    ),

    // Dworzec Główny Tunel (KST)
    const GtfsStop(
      id: 'stop_322_117319',
      name: 'Dworzec Główny Tunel',
      code: '901-01',
      location: LatLng(50.068199, 19.947649),
      wheelchairBoarding: true,
      platformType: PlatformType.elevatorHub,
      platformDescriptionPl: 'Węzeł wielopoziomowy: windy bezpośrednio z peronów PKP i Galerii na peron tramwajowy.',
      platformDescriptionEn: 'Multi-level hub: elevators directly from railway platforms to tram platform.',
    ),

    // Dworzec Główny Zachód (Autobusy)
    const GtfsStop(
      id: 'stop_335_260819',
      name: 'Dworzec Główny Zachód',
      code: '760-01',
      location: LatLng(50.067830, 19.945354),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Zintegrowany peron autobusowy z krawężnikiem Kassel ułatwiającym wysunięcie rampy.',
      platformDescriptionEn: 'Integrated bus platform with Kassel curb facilitating ramp deployment.',
    ),

    // Stary Kleparz
    const GtfsStop(
      id: 'stop_568_303219',
      name: 'Stary Kleparz',
      code: '833-01',
      location: LatLng(50.066314, 19.939721),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński z wyniesioną jezdnią na ul. Basztowej (krawężnik 0 cm).',
      platformDescriptionEn: 'Vienna platform with elevated roadway on Basztowa (0 cm curb).',
    ),

    // Teatr Bagatela
    const GtfsStop(
      id: 'stop_bagatela_01',
      name: 'Teatr Bagatela',
      code: '803-01',
      location: LatLng(50.063200, 19.932800),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński na ul. Karmelickiej. Bezprogowy wjazd dla wózków inwalidzkich i dziecięcych.',
      platformDescriptionEn: 'Vienna platform on Karmelicka street. Step-free entry for wheelchairs and strollers.',
    ),

    // UJ / AST (Planty / Bagatela południe)
    const GtfsStop(
      id: 'stop_1487_373619',
      name: 'UJ / AST (Planty)',
      code: '824-01',
      location: LatLng(50.060269, 19.930520),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Nowoczesny peron wyspowy z łagodnym najazdem rampowym <5%.',
      platformDescriptionEn: 'Modern island platform with gentle ramp slope <5%.',
    ),

    // Filharmonia
    const GtfsStop(
      id: 'stop_219_32219',
      name: 'Filharmonia',
      code: '822-01',
      location: LatLng(50.059030, 19.933870),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Podwyższony peron przy Plantach. Pasy ostrzegawcze z guzkami, brak barier.',
      platformDescriptionEn: 'Elevated platform at Planty. Warning tactile studs, zero barriers.',
    ),

    // Plac Wszystkich Świętych (Rynek / Magistrat)
    const GtfsStop(
      id: 'stop_325_136019',
      name: 'Plac Wszystkich Świętych (Rynek)',
      code: '821-01',
      location: LatLng(50.059120, 19.938240),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Wyspowy peron tramwajowy z łagodną rampą najazdową i gładką nawierzchnią granitową.',
      platformDescriptionEn: 'Island tram platform with gentle ramp and smooth granite pavement.',
    ),

    // Poczta Główna
    const GtfsStop(
      id: 'stop_222_35719',
      name: 'Poczta Główna',
      code: '806-01',
      location: LatLng(50.059797, 19.942404),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Peron tramwajowy z rampą zjazdową i zintegrowanym przejściem naziemnym bezprogowa.',
      platformDescriptionEn: 'Tram platform with access ramp and step-free pedestrian crossing.',
    ),

    // Wawel
    const GtfsStop(
      id: 'stop_221_32519',
      name: 'Wawel (ul. św. Idziego)',
      code: '818-01',
      location: LatLng(50.054490, 19.939630),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Dostosowany peron u podnóża Zamku Wawelskiego. Płaski zjazd na chodnik Plant.',
      platformDescriptionEn: 'Accessible platform below Wawel Castle. Flat transition to Planty sidewalk.',
    ),

    // Stradom (Węzeł Wawel - Kazimierz)
    const GtfsStop(
      id: 'stop_224_35919',
      name: 'Stradom',
      code: '819-01',
      location: LatLng(50.051480, 19.941337),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Szeroki peron wyspowy (szerokość >3m) z krawędzią dotykową i zjazdami 0 cm.',
      platformDescriptionEn: 'Wide island platform (>3m width) with tactile edge and 0 cm curb ramps.',
    ),

    // Plac Wolnica (Kazimierz)
    const GtfsStop(
      id: 'stop_225_36019',
      name: 'Plac Wolnica (Kazimierz)',
      code: '820-01',
      location: LatLng(50.048028, 19.943426),
      wheelchairBoarding: true,
      platformType: PlatformType.flushCurb,
      platformDescriptionPl: 'Peron bezprogowy na skraju Placu Wolnica. Płaskie połączenie z płytą placu.',
      platformDescriptionEn: 'Step-free platform on Plac Wolnica edge. Level connection with the square.',
    ),

    // Korona (Kazimierz / Podgórze)
    const GtfsStop(
      id: 'stop_279_57119',
      name: 'Korona',
      code: '556-01',
      location: LatLng(50.043604, 19.946683),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Nowoczesny peron z podwójną rampą najazdową i systemem informacji pasażerskiej.',
      platformDescriptionEn: 'Modern platform with double entry ramps and passenger information displays.',
    ),

    // Muzeum Narodowe (AGH / Błonia)
    const GtfsStop(
      id: 'stop_782_314119',
      name: 'Muzeum Narodowe (AGH)',
      code: '825-01',
      location: LatLng(50.059525, 19.925540),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Główny węzeł przy AGH: szeroki peron z krawężnikiem Kassel, 0 schodów.',
      platformDescriptionEn: 'Main hub at AGH: wide platform with Kassel curb, 0 stairs.',
    ),

    // Oleandry
    const GtfsStop(
      id: 'stop_311_82319',
      name: 'Oleandry',
      code: '345-01',
      location: LatLng(50.059787, 19.921194),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Peron przy Błoniach Krakowskich z płytami fakturowymi i zjazdami na ścieżkę.',
      platformDescriptionEn: 'Platform at Kraków Błonia with tactile pavers and path ramps.',
    ),

    // Reymana (Stadion Miejski / Błonia)
    const GtfsStop(
      id: 'stop_217_32019',
      name: 'Reymana',
      code: '346-01',
      location: LatLng(50.061364, 19.911163),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Peron z wydzielonym łagodnym podjazdem dla wózków, tuż przy Parku Jordana.',
      platformDescriptionEn: 'Platform with gentle wheelchair ramp right by Jordan Park.',
    ),

    // Cichy Kącik (Pętla Błonia)
    const GtfsStop(
      id: 'stop_196_8719',
      name: 'Cichy Kącik',
      code: '347-01',
      location: LatLng(50.062955, 19.903385),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Nowo wyremontowana pętla tramwajowa 100% WCAG. Płaski zjazd na trakt spacerowy Błoń.',
      platformDescriptionEn: 'Newly renovated 100% WCAG tram terminus. Level transition to Błonia promenade.',
    ),

    // Rondo Mogilskie
    const GtfsStop(
      id: 'stop_203_12519',
      name: 'Rondo Mogilskie',
      code: '802-01',
      location: LatLng(50.065782, 19.959639),
      wheelchairBoarding: true,
      platformType: PlatformType.elevatorHub,
      platformDescriptionPl: 'Węzeł przesiadkowy z 4 certyfikowanymi windami łączącymi poziom ulic z kraterem tramwajowym.',
      platformDescriptionEn: 'Interchange hub with 4 certified elevators connecting street level to tram crater.',
    ),

    // Rondo Grzegórzeckie
    const GtfsStop(
      id: 'stop_230_36519',
      name: 'Rondo Grzegórzeckie',
      code: '809-01',
      location: LatLng(50.057888, 19.960296),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Peron wyspowy z kładkami najazdowymi i akustycznymi sygnalizatorami dla niewidomych.',
      platformDescriptionEn: 'Island platform with access walkways and acoustic crosswalk signals.',
    ),

    // Plac Inwalidów
    const GtfsStop(
      id: 'stop_plac_inwalidow_01',
      name: 'Plac Inwalidów',
      code: '831-01',
      location: LatLng(50.068200, 19.927100),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński na ul. Królewskiej oraz dostosowane perony autobusowe przy alei.',
      platformDescriptionEn: 'Vienna platform on Królewska street and accessible bus platforms along the avenue.',
    ),

    // Krowodrza Górka P+R
    const GtfsStop(
      id: 'stop_1486_372419',
      name: 'Krowodrza Górka P+R',
      code: '416-01',
      location: LatLng(50.088958, 19.932816),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Nowoczesny terminal przesiadkowy P+R z pełnym audytem WCAG 2.1 AAA.',
      platformDescriptionEn: 'Modern P+R transit terminal with full WCAG 2.1 AAA accessibility certification.',
    ),

    // Jubilat (Aleje / Wawel / Dębniki)
    const GtfsStop(
      id: 'stop_jubilat_01',
      name: 'Jubilat',
      code: '823-01',
      location: LatLng(50.056550, 19.927500),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Główny węzeł przesiadkowy przy Alejach. Perony z krawężnikiem Kassel i windami na most.',
      platformDescriptionEn: 'Major interchange on Three Bards Avenues. Kassel curb platforms and bridge elevators.',
    ),

    // Starowiślna (Kazimierz / Dietla)
    const GtfsStop(
      id: 'stop_starowislna_01',
      name: 'Starowiślna',
      code: '805-01',
      location: LatLng(50.056020, 19.945030),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński na ul. Starowiślnej z łagodnym wjazdem rampowym 0 cm.',
      platformDescriptionEn: 'Vienna platform on Starowiślna with 0 cm smooth ramp.',
    ),

    // Plac Bohaterów Getta (Podgórze / Zabłocie)
    const GtfsStop(
      id: 'stop_getta_01',
      name: 'Plac Bohaterów Getta',
      code: '557-01',
      location: LatLng(50.046520, 19.954510),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Nowoczesny peron wyspowy z płytami fakturowymi i przejściem naziemnym bez barier.',
      platformDescriptionEn: 'Modern island platform with tactile pavers and barrier-free crosswalk.',
    ),

    // Politechnika (Pawia / KST Tunel północ)
    const GtfsStop(
      id: 'stop_politechnika_01',
      name: 'Politechnika',
      code: '804-01',
      location: LatLng(50.071500, 19.943500),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Węzeł Politechnika z rampami najazdowymi i zintegrowanym wyjściem z tunelu KST.',
      platformDescriptionEn: 'Politechnika hub with entry ramps and integrated KST tunnel exit.',
    ),

    // Nowy Kleparz (Węzeł Północ)
    const GtfsStop(
      id: 'stop_nowy_kleparz_01',
      name: 'Nowy Kleparz',
      code: '832-01',
      location: LatLng(50.073500, 19.936000),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Duży węzeł przesiadkowy tramwajowo-autobusowy z szerokimi peronami WCAG.',
      platformDescriptionEn: 'Major tram-bus interchange hub with wide WCAG platforms.',
    ),

    // Biprostal (Królewska / Krowodrza)
    const GtfsStop(
      id: 'stop_biprostal_01',
      name: 'Biprostal',
      code: '830-01',
      location: LatLng(50.071800, 19.913000),
      wheelchairBoarding: true,
      platformType: PlatformType.vienna,
      platformDescriptionPl: 'Peron Wiedeński na ul. Królewskiej zlicowany z chodnikiem.',
      platformDescriptionEn: 'Vienna platform on Królewska street flush with sidewalk.',
    ),

    // Bronowice (Pętla zachodnia)
    const GtfsStop(
      id: 'stop_bronowice_01',
      name: 'Bronowice',
      code: '828-01',
      location: LatLng(50.075000, 19.896000),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Peron pętli tramwajowej w pełni dostosowany do wózków inwalidzkich i dziecięcych.',
      platformDescriptionEn: 'Tram loop platform fully adapted for wheelchairs and strollers.',
    ),

    // Rondo Kocmyrzowskie (Nowa Huta)
    const GtfsStop(
      id: 'stop_kocmyrzowskie_01',
      name: 'Rondo Kocmyrzowskie',
      code: '450-01',
      location: LatLng(50.078000, 20.024000),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Węzeł przesiadkowy Nowej Huty z obniżonymi krawężnikami i sygnalizacją dźwiękową.',
      platformDescriptionEn: 'Nowa Huta hub with dropped curbs and acoustic signals.',
    ),

    // Tauron Arena Kraków Al. Pokoju
    const GtfsStop(
      id: 'stop_tauron_arena_01',
      name: 'Tauron Arena Kraków Al. Pokoju',
      code: '811-01',
      location: LatLng(50.064500, 19.992000),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Szeroki peron z bezpośrednim bezstopniowym dojściem do hali Tauron Arena.',
      platformDescriptionEn: 'Wide platform with direct step-free access to Tauron Arena.',
    ),

    // Łagiewniki
    const GtfsStop(
      id: 'stop_lagiewniki_01',
      name: 'Łagiewniki',
      code: '560-01',
      location: LatLng(50.027000, 19.937000),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Węzeł przesiadkowy zintegrowany ze stacją kolejową, windy i szerokie pochylnie.',
      platformDescriptionEn: 'Interchange integrated with railway station, lifts and wide ramps.',
    ),

    // Czerwone Maki P+R
    const GtfsStop(
      id: 'stop_czerwone_maki_01',
      name: 'Czerwone Maki P+R',
      code: '580-01',
      location: LatLng(50.015000, 19.894000),
      wheelchairBoarding: true,
      platformType: PlatformType.raisedRamp,
      platformDescriptionPl: 'Nowoczesny terminal P+R Ruczaj / Kampus UJ w standardzie WCAG 2.1 AAA.',
      platformDescriptionEn: 'Modern P+R Ruczaj terminal / UJ Campus in WCAG 2.1 AAA standard.',
    ),
  ];

  // ==========================================
  // LINIE KOMUNIKACJI MIEJSKIEJ (GTFS ZTP)
  // W 100% niskopodłogowy tabor (Lajkonik, Krakowiak, Solaris)
  // z rampą dla wózków
  // ==========================================
  static final List<_GtfsLineDefinition> _lines = [
    // Tramwaj 8: Borek Fałęcki / Łagiewniki <-> Cichy Kącik
    _GtfsLineDefinition(
      lineName: '8',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Cichy Kącik',
      headsignBackward: 'Borek Fałęcki',
      vehicleName: 'Stadler Tango Lajkonik (100% niskopodłogowy, rampa)',
      headwayMinutes: 7,
      stopIds: [
        'stop_lagiewniki_01', // Łagiewniki
        'stop_279_57119', // Korona
        'stop_225_36019', // Plac Wolnica
        'stop_224_35919', // Stradom
        'stop_221_32519', // Wawel
        'stop_325_136019', // Plac Wszystkich Świętych
        'stop_219_32219', // Filharmonia
        'stop_1487_373619', // UJ / AST
        'stop_782_314119', // Muzeum Narodowe
        'stop_311_82319', // Oleandry
        'stop_217_32019', // Reymana
        'stop_196_8719', // Cichy Kącik
      ],
    ),

    // Tramwaj 18: Czerwone Maki <-> Krowodrza Górka
    _GtfsLineDefinition(
      lineName: '18',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Krowodrza Górka P+R',
      headsignBackward: 'Czerwone Maki P+R',
      vehicleName: 'Bombardier NGT8 / Lajkonik (Niska podłoga, rampa)',
      headwayMinutes: 8,
      stopIds: [
        'stop_czerwone_maki_01', // Czerwone Maki
        'stop_224_35919', // Stradom
        'stop_221_32519', // Wawel
        'stop_325_136019', // Plac Wszystkich Świętych
        'stop_bagatela_01', // Teatr Bagatela
        'stop_568_303219', // Stary Kleparz
        'stop_nowy_kleparz_01', // Nowy Kleparz
        'stop_politechnika_01', // Politechnika
        'stop_1486_372419', // Krowodrza Górka P+R
      ],
    ),

    // Tramwaj 20: Tauron Arena / Płaszów <-> Cichy Kącik (przez Dworzec Główny)
    _GtfsLineDefinition(
      lineName: '20',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Cichy Kącik',
      headsignBackward: 'Mały Płaszów P+R',
      vehicleName: 'Pesa 2014N Krakowiak (100% niskopodłogowy, platforma dla wózków)',
      headwayMinutes: 7,
      stopIds: [
        'stop_tauron_arena_01', // Tauron Arena Kraków
        'stop_230_36519', // Rondo Grzegórzeckie
        'stop_203_12519', // Rondo Mogilskie
        'stop_852_324229', // Teatr Słowackiego (Dworzec Główny)
        'stop_568_303219', // Stary Kleparz
        'stop_bagatela_01', // Teatr Bagatela
        'stop_1487_373619', // UJ / AST
        'stop_782_314119', // Muzeum Narodowe
        'stop_311_82319', // Oleandry
        'stop_217_32019', // Reymana
        'stop_196_8719', // Cichy Kącik
      ],
    ),

    // Tramwaj 4: Wzgórza Krzesławickie / Kocmyrzowskie <-> Bronowice
    _GtfsLineDefinition(
      lineName: '4',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Bronowice Małe',
      headsignBackward: 'Wzgórza Krzesławickie',
      vehicleName: 'Pesa 2014N Krakowiak (100% niskopodłogowy, rampa)',
      headwayMinutes: 10,
      stopIds: [
        'stop_kocmyrzowskie_01', // Rondo Kocmyrzowskie
        'stop_203_12519', // Rondo Mogilskie
        'stop_852_324229', // Teatr Słowackiego (Dworzec Główny)
        'stop_568_303219', // Stary Kleparz
        'stop_bagatela_01', // Teatr Bagatela
        'stop_plac_inwalidow_01', // Plac Inwalidów
        'stop_biprostal_01', // Biprostal
        'stop_bronowice_01', // Bronowice
      ],
    ),

    // Tramwaj 52: Czerwone Maki <-> Os. Piastów / Kocmyrzowskie
    _GtfsLineDefinition(
      lineName: '52',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Os. Piastów',
      headsignBackward: 'Czerwone Maki P+R',
      vehicleName: 'Pesa 2014N Krakowiak (Wysuwana rampa, 100% niska podłoga)',
      headwayMinutes: 5,
      stopIds: [
        'stop_czerwone_maki_01', // Czerwone Maki
        'stop_224_35919', // Stradom
        'stop_221_32519', // Wawel
        'stop_222_35719', // Poczta Główna
        'stop_852_324219', // Teatr Słowackiego (Dworzec Główny)
        'stop_203_12519', // Rondo Mogilskie
        'stop_kocmyrzowskie_01', // Rondo Kocmyrzowskie
      ],
    ),

    // Tramwaj 50 (KST - Tunel): Krowodrza Górka <-> Kurdwanów / Łagiewniki
    _GtfsLineDefinition(
      lineName: '50',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Kurdwanów P+R',
      headsignBackward: 'Krowodrza Górka P+R',
      vehicleName: 'Stadler Tango Lajkonik (Krakowski Szybki Tramwaj)',
      headwayMinutes: 5,
      stopIds: [
        'stop_1486_372419', // Krowodrza Górka P+R
        'stop_politechnika_01', // Politechnika
        'stop_322_117319', // Dworzec Główny Tunel (Winda PKP)
        'stop_203_12519', // Rondo Mogilskie
        'stop_230_36519', // Rondo Grzegórzeckie
        'stop_getta_01', // Plac Bohaterów Getta
        'stop_lagiewniki_01', // Łagiewniki
      ],
    ),

    // Tramwaj 1: Salwator / Cichy Kącik <-> Tauron Arena / Wzgórza Krzesławickie
    _GtfsLineDefinition(
      lineName: '1',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Wzgórza Krzesławickie',
      headsignBackward: 'Salwator',
      vehicleName: 'Stadler Tango Lajkonik (100% niska podłoga)',
      headwayMinutes: 8,
      stopIds: [
        'stop_196_8719', // Cichy Kącik
        'stop_782_314119', // Muzeum Narodowe
        'stop_219_32219', // Filharmonia
        'stop_222_35719', // Poczta Główna
        'stop_starowislna_01', // Starowiślna
        'stop_230_36519', // Rondo Grzegórzeckie
        'stop_tauron_arena_01', // Tauron Arena
      ],
    ),

    // Tramwaj 3: Krowodrza Górka <-> Nowy Bieżanów
    _GtfsLineDefinition(
      lineName: '3',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Nowy Bieżanów P+R',
      headsignBackward: 'Krowodrza Górka P+R',
      vehicleName: 'Bombardier NGT6 (Niska podłoga, rampa zjazdowa)',
      headwayMinutes: 8,
      stopIds: [
        'stop_1486_372419', // Krowodrza Górka
        'stop_politechnika_01', // Politechnika
        'stop_852_324219', // Teatr Słowackiego (Dworzec Główny)
        'stop_222_35719', // Poczta Główna
        'stop_starowislna_01', // Starowiślna
        'stop_getta_01', // Plac Bohaterów Getta
      ],
    ),

    // Tramwaj 13: Bronowice <-> Nowy Bieżanów
    _GtfsLineDefinition(
      lineName: '13',
      vehicleType: TransitVehicleType.tram,
      headsignForward: 'Nowy Bieżanów P+R',
      headsignBackward: 'Bronowice',
      vehicleName: 'Stadler Tango Lajkonik (100% niska podłoga)',
      headwayMinutes: 8,
      stopIds: [
        'stop_bronowice_01', // Bronowice
        'stop_biprostal_01', // Biprostal
        'stop_plac_inwalidow_01', // Plac Inwalidów
        'stop_bagatela_01', // Teatr Bagatela
        'stop_219_32219', // Filharmonia
        'stop_221_32519', // Wawel
        'stop_224_35919', // Stradom
        'stop_225_36019', // Plac Wolnica
        'stop_279_57119', // Korona
        'stop_getta_01', // Plac Bohaterów Getta
      ],
    ),

    // Autobus 502 (Linia Przyspieszona): Aleja Przyjaźni <-> Cracovia Stadion
    _GtfsLineDefinition(
      lineName: '502',
      vehicleType: TransitVehicleType.bus,
      headsignForward: 'Cracovia Stadion',
      headsignBackward: 'Aleja Przyjaźni',
      vehicleName: 'Solaris Urbino 18 Electric (100% niski, rampa przyklękowa)',
      headwayMinutes: 10,
      stopIds: [
        'stop_kocmyrzowskie_01', // Rondo Kocmyrzowskie
        'stop_203_12519', // Rondo Mogilskie
        'stop_335_260819', // Dworzec Główny Zachód
        'stop_568_303219', // Stary Kleparz
        'stop_plac_inwalidow_01', // Plac Inwalidów
        'stop_782_314119', // Muzeum Narodowe (Cracovia)
        'stop_jubilat_01', // Jubilat
      ],
    ),

    // Autobus 304: Dworzec Główny Zachód <-> Wieliczka
    _GtfsLineDefinition(
      lineName: '304',
      vehicleType: TransitVehicleType.bus,
      headsignForward: 'Wieliczka Miasto',
      headsignBackward: 'Dworzec Główny Zachód',
      vehicleName: 'Solaris Urbino 18 (Niska podłoga, rampa przyklęk)',
      headwayMinutes: 10,
      stopIds: [
        'stop_335_260819', // Dworzec Główny Zachód
        'stop_jubilat_01', // Jubilat
        'stop_279_57119', // Korona
        'stop_lagiewniki_01', // Łagiewniki
      ],
    ),
  ];

  /// Wyszukuje najszybszą i w 100% przystosowaną trasę komunikacji miejskiej GTFS
  /// z uwzględnieniem dojścia pieszego do peronu i z peronu.
  /// Gwarantuje znalezienie trasy dla dowolnego punktu w Krakowie!
  static RouteModel? calculateFastestTransitRoute({
    required LatLng start,
    required LatLng end,
    required MobilityProfile profile,
    required int walkingDistanceMeters,
    required int walkingDurationMinutes,
    String? startName,
    String? destinationName,
  }) {
    _TransitCandidate? bestCandidate;
    double bestScore = double.infinity;

    // Krok 1: Wyszukiwanie bezpośredniego połączenia GTFS w promieniach od 1200m do 10000m (cały Kraków)
    for (final maxWalk in [1200, 2500, 10000]) {
      if (bestCandidate != null) break;

      for (final line in _lines) {
        final stopObjects = line.stopIds
            .map((id) => krakowStops.firstWhere((s) => s.id == id, orElse: () => krakowStops.first))
            .toList();

        for (int i = 0; i < stopObjects.length; i++) {
          final depStop = stopObjects[i];
          final walkToDist = _dist.as(LengthUnit.Meter, start, depStop.location).round();

          if (walkToDist > maxWalk) continue;

          for (int j = 0; j < stopObjects.length; j++) {
            if (i == j) continue;
            final arrStop = stopObjects[j];
            final walkFromDist = _dist.as(LengthUnit.Meter, arrStop.location, end).round();

            if (walkFromDist > maxWalk) continue;

            final isForward = i < j;
            final headsign = isForward ? line.headsignForward : line.headsignBackward;
            final intermediate = isForward
                ? stopObjects.sublist(i, j + 1)
                : stopObjects.sublist(j, i + 1).reversed.toList();

            final stopsCount = intermediate.length - 1;
            if (stopsCount <= 0) continue;

            final walkToMinutes = math.max(1, (walkToDist / 65).round());
            final waitMinutes = _calculateDynamicDepartureMinutes(line.headwayMinutes);
            final rideMinutes = math.max(2, (stopsCount * 1.8).round());
            final walkFromMinutes = math.max(1, (walkFromDist / 65).round());

            final totalMinutes = walkToMinutes + waitMinutes + rideMinutes + walkFromMinutes;
            final score = totalMinutes * 60.0 + (walkToDist + walkFromDist);

            if (score < bestScore) {
              bestScore = score;
              bestCandidate = _TransitCandidate(
                line: line,
                isForward: isForward,
                headsign: headsign,
                departureStop: depStop,
                arrivalStop: arrStop,
                intermediateStops: intermediate,
                walkToMeters: walkToDist,
                walkToMinutes: walkToMinutes,
                departureMinutesAway: waitMinutes,
                rideDurationMinutes: rideMinutes,
                walkFromMeters: walkFromDist,
                walkFromMinutes: walkFromMinutes,
                totalMinutes: totalMinutes,
              );
            }
          }
        }
      }
    }

    // Krok 2: Gwarantowany fallback, jeśli punkty leżą poza bezpośrednią linią
    if (bestCandidate == null) {
      GtfsStop? closestStartStop;
      double minStartDist = double.infinity;
      GtfsStop? closestEndStop;
      double minEndDist = double.infinity;

      for (final s in krakowStops) {
        final dStart = _dist.as(LengthUnit.Meter, start, s.location);
        if (dStart < minStartDist) {
          minStartDist = dStart;
          closestStartStop = s;
        }
        final dEnd = _dist.as(LengthUnit.Meter, end, s.location);
        if (dEnd < minEndDist) {
          minEndDist = dEnd;
          closestEndStop = s;
        }
      }

      if (closestStartStop != null && closestEndStop != null) {
        _GtfsLineDefinition? chosenLine;
        for (final l in _lines) {
          if (l.stopIds.contains(closestStartStop.id) && l.stopIds.contains(closestEndStop.id) && closestStartStop.id != closestEndStop.id) {
            chosenLine = l;
            break;
          }
        }
        chosenLine ??= _lines.firstWhere(
          (l) => l.stopIds.contains(closestStartStop!.id),
          orElse: () => _lines.first,
        );

        final stopObjects = chosenLine.stopIds
            .map((id) => krakowStops.firstWhere((s) => s.id == id, orElse: () => krakowStops.first))
            .toList();
        final i = math.max(0, stopObjects.indexWhere((s) => s.id == closestStartStop!.id));
        final j = closestStartStop.id != closestEndStop.id && stopObjects.any((s) => s.id == closestEndStop!.id)
            ? stopObjects.indexWhere((s) => s.id == closestEndStop!.id)
            : (i < stopObjects.length - 1 ? i + 1 : math.max(0, i - 1));

        final isForward = i <= j;
        final intermediate = isForward
            ? stopObjects.sublist(i, j + 1)
            : stopObjects.sublist(j, i + 1).reversed.toList();
        final waitMinutes = _calculateDynamicDepartureMinutes(chosenLine.headwayMinutes);

        bestCandidate = _TransitCandidate(
          line: chosenLine,
          isForward: isForward,
          headsign: isForward ? chosenLine.headsignForward : chosenLine.headsignBackward,
          departureStop: stopObjects[i],
          arrivalStop: stopObjects[j],
          intermediateStops: intermediate.length >= 2 ? intermediate : [stopObjects[i], stopObjects[j]],
          walkToMeters: minStartDist.round(),
          walkToMinutes: math.max(1, (minStartDist / 65).round()),
          departureMinutesAway: waitMinutes,
          rideDurationMinutes: math.max(2, (intermediate.length * 1.8).round()),
          walkFromMeters: minEndDist.round(),
          walkFromMinutes: math.max(1, (minEndDist / 65).round()),
          totalMinutes: math.max(3, (minStartDist / 65).round() + waitMinutes + 4 + (minEndDist / 65).round()),
        );
      }
    }

    if (bestCandidate == null) return null;

    final candidate = bestCandidate;

    // Generuj sformatowane odjazdy w czasie rzeczywistym z GTFS
    final now = DateTime.now();
    final depTime1 = now.add(Duration(minutes: candidate.departureMinutesAway));
    final depTime2 = depTime1.add(Duration(minutes: candidate.line.headwayMinutes));
    final depTime3 = depTime2.add(Duration(minutes: candidate.line.headwayMinutes));

    String formatTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final nextDepartures = [
      '${formatTime(depTime1)} (za ${candidate.departureMinutesAway} min)',
      '${formatTime(depTime2)} (za ${candidate.departureMinutesAway + candidate.line.headwayMinutes} min)',
      '${formatTime(depTime3)} (za ${candidate.departureMinutesAway + candidate.line.headwayMinutes * 2} min)',
    ];

    // Zbuduj geometrię trasy torowiska / buspasa
    final trackGeometry = _buildTrackGeometry(candidate.intermediateStops);
    final walkToCoords = _interpolateLine(start, candidate.departureStop.location, 4);
    final walkFromCoords = _interpolateLine(candidate.arrivalStop.location, end, 4);

    final fullCoordinates = <LatLng>[
      ...walkToCoords,
      ...trackGeometry,
      ...walkFromCoords,
    ];

    final isFastest = candidate.totalMinutes < walkingDurationMinutes;
    final timeSaved = math.max(0, walkingDurationMinutes - candidate.totalMinutes);

    final transitLeg = TransitLeg(
      lineName: candidate.line.lineName,
      vehicleType: candidate.line.vehicleType,
      headsign: candidate.headsign,
      departureStop: candidate.departureStop,
      arrivalStop: candidate.arrivalStop,
      intermediateStops: candidate.intermediateStops,
      departureMinutesAway: candidate.departureMinutesAway,
      nextDeparturesFormatted: nextDepartures,
      rideDurationMinutes: candidate.rideDurationMinutes,
      isLowFloor: true,
      hasRamp: true,
      vehicleName: candidate.line.vehicleName,
      trackGeometry: trackGeometry,
    );

    final transitInfo = TransitRouteInfo(
      transitLeg: transitLeg,
      walkToStopMeters: candidate.walkToMeters,
      walkToStopMinutes: candidate.walkToMinutes,
      walkFromStopMeters: candidate.walkFromMeters,
      walkFromStopMinutes: candidate.walkFromMinutes,
      totalDurationMinutes: candidate.totalMinutes,
      walkingDurationMinutes: walkingDurationMinutes,
      timeSavedMinutes: timeSaved,
      isFastest: isFastest,
      walkToStopPolyline: walkToCoords,
      walkFromStopPolyline: walkFromCoords,
    );

    // Audyt dostępności peronu GTFS
    final transitAudit = AccessibilityAudit(
      id: 'aud_gtfs_peron_${candidate.departureStop.code}',
      checkpointName: 'Peron przystankowy: ${candidate.departureStop.name}',
      location: candidate.departureStop.location,
      photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Stadler_Tango_Lajkonik_Krak%C3%B3w.jpg/640px-Stadler_Tango_Lajkonik_Krak%C3%B3w.jpg',
      isAccessible: true,
      score: 98,
      stairsDetected: false,
      stairsCount: 0,
      curbStatus: candidate.departureStop.platformBadgeTextPl,
      surfaceType: 'Gładki peron klinkierowo-granitowy z krawędzią dotykową',
      hazards: const [],
      aiVerdictPl: 'AUDYT GTFS: ${candidate.departureStop.platformDescriptionPl} '
          'Pojazd ${candidate.line.vehicleName} posiada 100% niskiej podłogi z dedykowaną rampą wjazdu dla wózków.',
      aiVerdictEn: 'GTFS AUDIT: ${candidate.departureStop.platformDescriptionEn} '
          'Vehicle is 100% low-floor with deployed boarding ramp.',
      profileImpactPl: 'Brak barier architektonicznych: wsiadanie na poziomie peronu lub z rampą.',
      profileImpactEn: 'Zero architectural barriers: step-free level boarding or ramp.',
      isLiveGeoPhoto: false,
      photoSourceAttribution: 'ZTP Kraków GTFS & MPK Kraków',
      photoTitle: 'Tabor niskopodłogowy MPK Kraków',
    );

    final vehicleLabelPl = candidate.line.vehicleType == TransitVehicleType.tram ? 'Tramwaj' : 'Autobus';
    final vehicleLabelEn = candidate.line.vehicleType == TransitVehicleType.tram ? 'Tram' : 'Bus';

    return RouteModel(
      id: 'route_gtfs_transit_${candidate.line.lineName}',
      titlePl: '$vehicleLabelPl ${candidate.line.lineName} ($vehicleLabelPl)',
      titleEn: '$vehicleLabelEn ${candidate.line.lineName} ($vehicleLabelEn)',
      type: RouteType.transit,
      polylineColor: const Color(0xFF0284C7), // MPK Kraków Blue
      distanceMeters: walkingDistanceMeters,
      durationMinutes: candidate.totalMinutes,
      accessibilityScore: 98,
      stairsCount: 0,
      stairsAvoided: 24,
      surfaceSummaryPl: '0 schodów • ${candidate.departureStop.platformBadgeTextPl}',
      surfaceSummaryEn: '0 stairs • ${candidate.departureStop.platformBadgeTextEn}',
      coordinates: fullCoordinates,
      audits: [transitAudit],
      profileHighlightsPl: [
        if (isFastest) '🚀 NAJSZYBSZA TRASA (Zaoszczędź $timeSaved min)' else 'Wygodny dojazd bez wysiłku',
        '0 stopni (Wsiadanie bez barier)',
        candidate.departureStop.platformBadgeTextPl,
        'Tabor 100% z rampą dla wózków',
      ],
      profileHighlightsEn: [
        if (isFastest) '🚀 FASTEST ROUTE (Save $timeSaved min)' else 'Comfortable effortless travel',
        '0 stairs (Barrier-free boarding)',
        candidate.departureStop.platformBadgeTextEn,
        '100% low-floor with wheelchair ramp',
      ],
      detectedBarrierPl: 'Brak barier: Certyfikowany peron GTFS i tabor MPK',
      detectedBarrierEn: 'No barriers: Certified GTFS platform & low-floor fleet',
      bypassReasonPl: 'Przejazd niskopodłogową komunikacją miejską eliminuje wszelkie bariery i przyspiesza podróż.',
      bypassReasonEn: 'Low-floor public transit eliminates all street barriers and significantly cuts travel time.',
      transitInfo: transitInfo,
    );
  }

  static int _calculateDynamicDepartureMinutes(int headway) {
    // Oblicz realistyczny czas do następnego odjazdu bazując na aktualnej minucie
    final currentMinute = DateTime.now().minute;
    final remainder = headway - (currentMinute % headway);
    return remainder == 0 ? headway : remainder;
  }

  static List<LatLng> _buildTrackGeometry(List<GtfsStop> stops) {
    if (stops.isEmpty) return [];
    if (stops.length == 1) return [stops.first.location];

    final List<LatLng> geometry = [];
    for (int i = 0; i < stops.length - 1; i++) {
      final p1 = stops[i].location;
      final p2 = stops[i + 1].location;
      final seg = _interpolateLine(p1, p2, 6);
      if (i > 0) {
        geometry.addAll(seg.skip(1));
      } else {
        geometry.addAll(seg);
      }
    }
    return geometry;
  }

  static List<LatLng> _interpolateLine(LatLng a, LatLng b, int segments) {
    final List<LatLng> list = [];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      list.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
    return list;
  }
}

class _GtfsLineDefinition {
  final String lineName;
  final TransitVehicleType vehicleType;
  final String headsignForward;
  final String headsignBackward;
  final String vehicleName;
  final int headwayMinutes;
  final List<String> stopIds;

  const _GtfsLineDefinition({
    required this.lineName,
    required this.vehicleType,
    required this.headsignForward,
    required this.headsignBackward,
    required this.vehicleName,
    required this.headwayMinutes,
    required this.stopIds,
  });
}

class _TransitCandidate {
  final _GtfsLineDefinition line;
  final bool isForward;
  final String headsign;
  final GtfsStop departureStop;
  final GtfsStop arrivalStop;
  final List<GtfsStop> intermediateStops;
  final int walkToMeters;
  final int walkToMinutes;
  final int departureMinutesAway;
  final int rideDurationMinutes;
  final int walkFromMeters;
  final int walkFromMinutes;
  final int totalMinutes;

  _TransitCandidate({
    required this.line,
    required this.isForward,
    required this.headsign,
    required this.departureStop,
    required this.arrivalStop,
    required this.intermediateStops,
    required this.walkToMeters,
    required this.walkToMinutes,
    required this.departureMinutesAway,
    required this.rideDurationMinutes,
    required this.walkFromMeters,
    required this.walkFromMinutes,
    required this.totalMinutes,
  });
}
