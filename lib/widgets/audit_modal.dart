import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/accessibility_audit.dart';
import '../providers/app_state.dart';

class AuditModal extends StatefulWidget {
  final AccessibilityAudit audit;

  const AuditModal({super.key, required this.audit});

  @override
  State<AuditModal> createState() => _AuditModalState();
}

class _AuditModalState extends State<AuditModal> {
  bool _showBypassPhoto = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final audit = widget.audit;
    final hasBypassPhoto = audit.bypassPhotoUrl != null && audit.bypassPhotoUrl!.isNotEmpty;

    final currentPhoto = (_showBypassPhoto && hasBypassPhoto)
        ? audit.bypassPhotoUrl!
        : audit.photoUrl;

    // Jeżeli jesteśmy na trasie dostępnej (audit.isAccessible == true):
    // _showBypassPhoto == false -> pokazujemy zdjęcie trasy dostępnej (isShowingBarrier = false)
    // _showBypassPhoto == true -> pokazujemy zdjęcie ominiętej bariery (isShowingBarrier = true)
    // Jeżeli jesteśmy na trasie ze schodami/barierą (audit.isAccessible == false):
    // _showBypassPhoto == false -> pokazujemy zdjęcie bariery (isShowingBarrier = true)
    // _showBypassPhoto == true -> pokazujemy zdjęcie objazdu (isShowingBarrier = false)
    final bool isShowingBarrier = audit.isAccessible
        ? _showBypassPhoto
        : !_showBypassPhoto;

    final headerTitle = (isShowingBarrier && audit.isAccessible && audit.bypassTitlePl != null)
        ? (isPL ? audit.bypassTitlePl! : (audit.bypassTitleEn ?? audit.bypassTitlePl!))
        : audit.checkpointName;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isShowingBarrier
                ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                : const Color(0xFF10B981).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isShowingBarrier
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981))
                  .withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Górny nagłówek z badge'ami AI i profilem
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isShowingBarrier
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isShowingBarrier ? Icons.warning_rounded : Icons.verified,
                        color: isShowingBarrier
                            ? const Color(0xFFF87171)
                            : const Color(0xFF34D399),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isShowingBarrier
                                    ? (audit.isAccessible
                                        ? (isPL ? 'OMINIĘTA PRZESZKODA' : 'AVOIDED OBSTACLE')
                                        : (isPL ? 'WYKRYTA PRZESZKODA' : 'OBSTACLE DETECTED'))
                                    : (isPL ? 'AUDYT STREET VIEW' : 'STREET VIEW AUDIT'),
                                style: TextStyle(
                                  color: isShowingBarrier
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFF34D399),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getProfileLabel(state.profile, isPL),
                                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: state.closeAudit,
                    ),
                  ],
                ),
              ),

              // 2. Przełącznik "Bariera (Street View)" vs "Objazd KrakAccess" (jeśli dostępny)
              if (hasBypassPhoto)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showBypassPhoto = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showBypassPhoto
                                    ? (audit.isAccessible
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF7F1D1D))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    audit.isAccessible
                                        ? Icons.check_circle
                                        : Icons.camera_alt,
                                    color: audit.isAccessible
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFF87171),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    audit.isAccessible
                                        ? (isPL ? 'Trakt KrakAccess (Płasko)' : 'KrakAccess Path (Flat)')
                                        : (isPL ? 'Bariera na trasie' : 'Barrier on route'),
                                    style: TextStyle(
                                      color: !_showBypassPhoto ? Colors.white : Colors.white60,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showBypassPhoto = true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _showBypassPhoto
                                    ? (audit.isAccessible
                                        ? const Color(0xFF7F1D1D)
                                        : const Color(0xFF065F46))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    audit.isAccessible
                                        ? Icons.visibility
                                        : Icons.check_circle,
                                    color: audit.isAccessible
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFF34D399),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    audit.isAccessible
                                        ? (isPL ? 'Ominięta przeszkoda' : 'Avoided Obstacle')
                                        : (isPL ? 'Objazd KrakAccess' : 'KrakAccess Bypass'),
                                    style: TextStyle(
                                      color: _showBypassPhoto ? Colors.white : Colors.white60,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Widok zdjęcia Street View z HUDem analitycznym AI
              Stack(
                children: [
                  ClipRRect(
                    child: SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: _buildStreetViewImage(currentPhoto, isShowingBarrier),
                    ),
                  ),

                  // Overlay z gradientem i siatką
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // HUD: Koordynaty GPS na żywo
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${audit.location.latitude.toStringAsFixed(4)}°N, ${audit.location.longitude.toStringAsFixed(4)}°E',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Znacznik Street View Camera lub Live GeoSearch
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isShowingBarrier && audit.isLiveGeoPhoto)
                            ? const Color(0xFF0369A1).withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isShowingBarrier && audit.isLiveGeoPhoto)
                              ? const Color(0xFF38BDF8)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (isShowingBarrier && audit.isLiveGeoPhoto)
                                ? Icons.public
                                : Icons.streetview,
                            color: const Color(0xFF38BDF8),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (isShowingBarrier && audit.isLiveGeoPhoto)
                                ? (isPL ? 'Pobrane na żywo • GeoSearch' : 'Live GeoPhoto • GeoSearch')
                                : 'Kraków Street View • HD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bounding frame jeśli wykryto barierę
                  if (isShowingBarrier)
                    Positioned(
                      top: 45,
                      left: 25,
                      right: 25,
                      bottom: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEF4444), width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              isPL
                                  ? (audit.stairsDetected || audit.stairsCount > 0
                                      ? 'STOPNIE / SCHODY'
                                      : 'TRUDNA NAWIERZCHNIA')
                                  : 'ARCHITECTURAL HAZARD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Znacznik zweryfikowanej dostępności
                  if (!isShowingBarrier)
                    Positioned(
                      top: 45,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF34D399)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF34D399), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              isPL ? 'TRAKT BEZ BARIER (WCAG)' : 'BARRIER-FREE ROUTE (WCAG)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Wskaźnik punktacji na dole zdjęcia
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isShowingBarrier
                              ? const Color(0xFFF87171)
                              : const Color(0xFF34D399),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isShowingBarrier ? Icons.block : Icons.check_circle,
                            color: isShowingBarrier
                                ? const Color(0xFFF87171)
                                : const Color(0xFF34D399),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isShowingBarrier
                                ? (audit.isAccessible
                                    ? (isPL ? 'Bariera na trasie prostej: 25/100' : 'Direct path barrier: 25/100')
                                    : '${audit.score}/100 ${isPL ? 'Wskaźnik dostępności' : 'Score'}')
                                : (isPL ? 'Trakt KrakAccess: 98% Bezpieczny' : 'KrakAccess Path: 98% Safe (WCAG)'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 4. Parametry architektoniczne punktu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureRow(
                      icon: Icons.stairs,
                      label: isPL ? 'Schody' : 'Stairs',
                      value: isShowingBarrier
                          ? (audit.stairsCount > 0
                              ? (isPL
                                  ? 'Wykryto ${audit.stairsCount} stopni (Brak windy / rampy!)'
                                  : '${audit.stairsCount} steps detected (No ramp / lift!)')
                              : (isPL ? '0 stopni (Bariera krawężnikowa / nawierzchnia)' : '0 steps (Curbs & surface barrier)'))
                          : (isPL ? '0 stopni (Płasko)' : '0 steps (Flat)'),
                      isPositive: !isShowingBarrier,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      icon: Icons.straighten,
                      label: isPL ? 'Krawężnik' : 'Curb Height',
                      value: isShowingBarrier
                          ? (audit.curbStatus.isNotEmpty
                              ? audit.curbStatus
                              : (isPL ? 'Krawężnik 12-14 cm' : '12-14 cm curb'))
                          : (isPL ? 'Zjazd 0-1 cm zlicowany z jezdnią' : 'Dropped curb 0-1 cm flush'),
                      isPositive: !isShowingBarrier,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      icon: Icons.texture,
                      label: isPL ? 'Nawierzchnia' : 'Surface Type',
                      value: isShowingBarrier
                          ? (audit.surfaceType.isNotEmpty
                              ? audit.surfaceType
                              : (isPL ? 'Nierówna kostka / schody' : 'Uneven cobblestone / stairs'))
                          : (isPL ? 'Gładkie płyty granitowe / asfalt szlifowany' : 'Smooth granite slabs / asphalt'),
                      isPositive: !isShowingBarrier,
                    ),

                    const SizedBox(height: 12),

                    // Wpływ na wybrany profil mobilności
                    if (audit.profileImpactPl != null && isShowingBarrier) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getProfileIcon(state.profile),
                              color: const Color(0xFF38BDF8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isPL ? audit.profileImpactPl! : (audit.profileImpactEn ?? audit.profileImpactPl!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Informacja o pobraniu zdjęcia w czasie rzeczywistym z Wikimedia Commons
                    if (isShowingBarrier && audit.isLiveGeoPhoto) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0369A1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.travel_explore, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPL ? 'ZDJĘCIE POBRANE NA ŻYWO (GPS)' : 'LIVE GEOSEARCH PHOTO (GPS)',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPL
                                        ? 'Fotografia pobrana w czasie rzeczywistym z Wikimedia Commons GeoSearch dla współrzędnych tej przeszkody (${audit.location.latitude.toStringAsFixed(4)}°N, ${audit.location.longitude.toStringAsFixed(4)}°E)\nObiekt: ${audit.photoTitle ?? "Okolice punktu"}\nAutor: ${audit.photoSourceAttribution ?? "Creative Commons"}'
                                        : 'Real-time photograph fetched from Wikimedia Commons GeoSearch for obstacle coordinates (${audit.location.latitude.toStringAsFixed(4)}°N, ${audit.location.longitude.toStringAsFixed(4)}°E)\nSubject: ${audit.photoTitle ?? "Location"}\nAuthor: ${audit.photoSourceAttribution ?? "Creative Commons"}',
                                    style: const TextStyle(
                                      color: Color(0xFFBAE6FD),
                                      fontSize: 10,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Werdykt AI Gemini Vision
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isShowingBarrier
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isShowingBarrier
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: isShowingBarrier
                                ? const Color(0xFFF87171)
                                : const Color(0xFF34D399),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPL ? 'Werdykt Gemini AI:' : 'Gemini AI Verdict:',
                                  style: TextStyle(
                                    color: isShowingBarrier
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFF34D399),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isShowingBarrier
                                      ? (audit.isAccessible
                                          ? (isPL
                                              ? 'Ominięto tę barierę dzięki alternatywnej trasie KrakAccess.'
                                              : 'This barrier is avoided via the KrakAccess route.')
                                          : (isPL ? audit.aiVerdictPl : audit.aiVerdictEn))
                                      : (isPL
                                          ? (audit.isAccessible
                                              ? audit.aiVerdictPl
                                              : 'KrakAccess skierował Cię bezpiecznym obejściem naziemnym bez barier architektonicznych.')
                                          : (audit.isAccessible ? audit.aiVerdictEn : 'KrakAccess routed you through a flat, barrier-free path.')),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Przycisk zamknij
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.closeAudit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        child: Text(
                          isPL ? 'Wróć do mapy Krakowa' : 'Back to Kraków Map',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreetViewImage(String photoPath, bool isBarrier) {
    if (photoPath.startsWith('assets/')) {
      return Image.asset(
        photoPath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackPhoto(isBarrier),
      );
    }

    return Image.network(
      photoPath,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF0F172A),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
          ),
        );
      },
      errorBuilder: (ctx, err, stack) => _buildFallbackPhoto(isBarrier),
    );
  }

  Widget _buildFallbackPhoto(bool isBarrier) {
    return Image.asset(
      isBarrier
          ? 'assets/streetview/generic_stairs_barrier.jpg'
          : 'assets/streetview/generic_flat_bypass.jpg',
      fit: BoxFit.cover,
    );
  }

  String _getProfileLabel(MobilityProfile p, bool isPL) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return isPL ? 'Wózek inwalidzki' : 'Wheelchair';
      case MobilityProfile.cane:
        return isPL ? 'O kuli / Senior' : 'Cane / Senior';
      case MobilityProfile.stroller:
        return isPL ? 'Wózek dziecięcy' : 'Stroller';
    }
  }

  IconData _getProfileIcon(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return Icons.accessible;
      case MobilityProfile.cane:
        return Icons.elderly;
      case MobilityProfile.stroller:
        return Icons.baby_changing_station;
    }
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
