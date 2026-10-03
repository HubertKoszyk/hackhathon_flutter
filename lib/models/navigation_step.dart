import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class NavigationStep {
  final LatLng point;
  final String instructionPl;
  final String instructionEn;
  final String streetName;
  final IconData maneuverIcon;
  final double distanceMeters;
  final String? accessibilityNotePl;
  final String? accessibilityNoteEn;

  const NavigationStep({
    required this.point,
    required this.instructionPl,
    required this.instructionEn,
    required this.streetName,
    required this.maneuverIcon,
    required this.distanceMeters,
    this.accessibilityNotePl,
    this.accessibilityNoteEn,
  });
}
