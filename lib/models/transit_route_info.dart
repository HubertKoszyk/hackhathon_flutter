import 'package:latlong2/latlong.dart';

enum PlatformType {
  vienna, // Peron wiedeński (jezdnia wyniesiona do poziomu chodnika, rampa 0 cm)
  raisedRamp, // Peron wyspowy z krawężnikiem Kassel i rampą najazdową
  elevatorHub, // Węzeł przesiadkowy z windami przystosowanymi dla wózków
  flushCurb, // Zlicowane z chodnikiem przejście bezstopniowe
}

enum TransitVehicleType {
  tram,
  bus,
}

class GtfsStop {
  final String id;
  final String name;
  final String code; // np. 801-01
  final LatLng location;
  final bool wheelchairBoarding; // GTFS wheelchair_boarding = 1
  final PlatformType platformType;
  final String platformDescriptionPl;
  final String platformDescriptionEn;
  final bool hasTactilePaving; // Pasy naprowadzające dla niewidomych
  final bool hasAudioSystem; // Dźwiękowe zapowiedzi odjazdów na peronie

  const GtfsStop({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    this.wheelchairBoarding = true,
    required this.platformType,
    required this.platformDescriptionPl,
    required this.platformDescriptionEn,
    this.hasTactilePaving = true,
    this.hasAudioSystem = true,
  });

  String get platformBadgeTextPl {
    switch (platformType) {
      case PlatformType.vienna:
        return 'Peron Wiedeński (0 cm najazd)';
      case PlatformType.raisedRamp:
        return 'Peron z łagodną rampą (<5%)';
      case PlatformType.elevatorHub:
        return 'Węzeł z windami dla wózków';
      case PlatformType.flushCurb:
        return 'Peron bezprogowy zlicowany';
    }
  }

  String get platformBadgeTextEn {
    switch (platformType) {
      case PlatformType.vienna:
        return 'Vienna Platform (0 cm flush entry)';
      case PlatformType.raisedRamp:
        return 'Platform with gentle ramp (<5%)';
      case PlatformType.elevatorHub:
        return 'Interchange with wheelchair lifts';
      case PlatformType.flushCurb:
        return 'Step-free level platform';
    }
  }
}

class TransitLeg {
  final String lineName; // np. "8", "20", "18", "502"
  final TransitVehicleType vehicleType;
  final String headsign; // np. "Cichy Kącik"
  final GtfsStop departureStop;
  final GtfsStop arrivalStop;
  final List<GtfsStop> intermediateStops;
  final int departureMinutesAway;
  final List<String> nextDeparturesFormatted;
  final int rideDurationMinutes;
  final bool isLowFloor; // 100% taboru niskopodłogowego
  final bool hasRamp; // Rampa wysuwana/odkładana
  final String vehicleName; // np. "Stadler Tango Lajkonik (100% niskopodłogowy z rampą)"
  final List<LatLng> trackGeometry; // Współrzędne trasy szynowej / drogowej

  const TransitLeg({
    required this.lineName,
    required this.vehicleType,
    required this.headsign,
    required this.departureStop,
    required this.arrivalStop,
    required this.intermediateStops,
    required this.departureMinutesAway,
    required this.nextDeparturesFormatted,
    required this.rideDurationMinutes,
    this.isLowFloor = true,
    this.hasRamp = true,
    required this.vehicleName,
    required this.trackGeometry,
  });

  int get stopsCount => intermediateStops.isEmpty ? 1 : intermediateStops.length - 1;
}

class TransitRouteInfo {
  final TransitLeg transitLeg;
  final int walkToStopMeters;
  final int walkToStopMinutes;
  final int walkFromStopMeters;
  final int walkFromStopMinutes;
  final int totalDurationMinutes;
  final int walkingDurationMinutes;
  final int timeSavedMinutes;
  final bool isFastest;
  final List<LatLng> walkToStopPolyline;
  final List<LatLng> walkFromStopPolyline;

  const TransitRouteInfo({
    required this.transitLeg,
    required this.walkToStopMeters,
    required this.walkToStopMinutes,
    required this.walkFromStopMeters,
    required this.walkFromStopMinutes,
    required this.totalDurationMinutes,
    required this.walkingDurationMinutes,
    required this.timeSavedMinutes,
    required this.isFastest,
    required this.walkToStopPolyline,
    required this.walkFromStopPolyline,
  });

  String get summaryDescriptionPl {
    return 'Dojście ${walkToStopMeters}m ($walkToStopMinutes min) ➔ '
        '${transitLeg.vehicleType == TransitVehicleType.tram ? "Tramwaj" : "Autobus"} ${transitLeg.lineName} (${transitLeg.stopsCount} przyst., ${transitLeg.rideDurationMinutes} min) ➔ '
        'Dojście ${walkFromStopMeters}m ($walkFromStopMinutes min)';
  }

  String get summaryDescriptionEn {
    return 'Walk ${walkToStopMeters}m ($walkToStopMinutes min) ➔ '
        '${transitLeg.vehicleType == TransitVehicleType.tram ? "Tram" : "Bus"} ${transitLeg.lineName} (${transitLeg.stopsCount} stops, ${transitLeg.rideDurationMinutes} min) ➔ '
        'Walk ${walkFromStopMeters}m ($walkFromStopMinutes min)';
  }
}
