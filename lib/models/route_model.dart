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
  final int stairsCount;
  final String surfaceSummaryPl;
  final String surfaceSummaryEn;
  final List<AccessibilityAudit> audits;
  final Color polylineColor;
  final List<String> profileHighlightsPl;
  final List<String> profileHighlightsEn;
  final String? detectedBarrierPl;
  final String? detectedBarrierEn;
  final String? bypassReasonPl;
  final String? bypassReasonEn;

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
    this.stairsCount = 0,
    required this.surfaceSummaryPl,
    required this.surfaceSummaryEn,
    required this.audits,
    required this.polylineColor,
    this.profileHighlightsPl = const [],
    this.profileHighlightsEn = const [],
    this.detectedBarrierPl,
    this.detectedBarrierEn,
    this.bypassReasonPl,
    this.bypassReasonEn,
  });

  String getDistanceString() {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }
}
