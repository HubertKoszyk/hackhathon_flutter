import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'accessibility_audit.dart';

enum RouteType {
  standard,
  accessible,
}

class RouteModel {
  final String id;
  final String titlePl;
  final String titleEn;
  final RouteType type;
  final List<LatLng> coordinates;
  final int distanceMeters;
  final int durationMinutes;
  final int accessibilityScore; // 0 - 100
  final int stairsAvoided;
  final String surfaceSummaryPl;
  final String surfaceSummaryEn;
  final List<AccessibilityAudit> audits;
  final Color polylineColor;

  const RouteModel({
    required this.id,
    required this.titlePl,
    required this.titleEn,
    required this.type,
    required this.coordinates,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.accessibilityScore,
    required this.stairsAvoided,
    required this.surfaceSummaryPl,
    required this.surfaceSummaryEn,
    required this.audits,
    required this.polylineColor,
  });

  String getDistanceString() {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }
}
