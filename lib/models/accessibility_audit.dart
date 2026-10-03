import 'package:latlong2/latlong.dart';

class AccessibilityAudit {
  final String id;
  final String checkpointName;
  final LatLng location;
  final String photoUrl;
  final bool isAccessible;
  final int score; // 0 - 100
  final bool stairsDetected;
  final int stairsCount;
  final String curbStatus;
  final String surfaceType;
  final List<String> hazards;
  final String aiVerdictPl;
  final String aiVerdictEn;
  final String? bypassPhotoUrl;
  final String? bypassTitlePl;
  final String? bypassTitleEn;
  final String? bypassDescriptionPl;
  final String? bypassDescriptionEn;
  final String? profileImpactPl;
  final String? profileImpactEn;
  final bool isLiveGeoPhoto;
  final String? photoSourceAttribution;
  final String? photoTitle;

  const AccessibilityAudit({
    required this.id,
    required this.checkpointName,
    required this.location,
    required this.photoUrl,
    required this.isAccessible,
    required this.score,
    required this.stairsDetected,
    this.stairsCount = 0,
    required this.curbStatus,
    required this.surfaceType,
    required this.hazards,
    required this.aiVerdictPl,
    required this.aiVerdictEn,
    this.bypassPhotoUrl,
    this.bypassTitlePl,
    this.bypassTitleEn,
    this.bypassDescriptionPl,
    this.bypassDescriptionEn,
    this.profileImpactPl,
    this.profileImpactEn,
    this.isLiveGeoPhoto = false,
    this.photoSourceAttribution,
    this.photoTitle,
  });
}
