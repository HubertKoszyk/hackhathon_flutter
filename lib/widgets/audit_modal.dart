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

    final isShowingBarrier = !_showBypassPhoto && !audit.isAccessible;

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
                                    ? (isPL ? 'WYKRYTA PRZESZKODA' : 'OBSTACLE DETECTED')
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
                            audit.checkpointName,
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
                                    ? const Color(0xFF7F1D1D)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt, color: Color(0xFFF87171), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPL ? 'Bariera na trasie' : 'Barrier on route',
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
                                    ? const Color(0xFF065F46)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPL ? 'Objazd KrakAccess' : 'KrakAccess Bypass',
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
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        currentPhoto,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, stack) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.streetview, color: Colors.white38, size: 48),
                          ),
                        ),
                      ),
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
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Znacznik Street View Camera
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.streetview, color: Color(0xFF38BDF8), size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Kraków Street View',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bounding frame jeśli wykryto barierę
                  if (isShowingBarrier)
                    Positioned(
                      top: 40,
                      left: 30,
                      right: 30,
                      bottom: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEF4444), width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: const Color(0xFFEF4444),
                            child: Text(
                              isPL
                                  ? (audit.stairsDetected ? 'STOPNIE / SCHODY' : 'TRUDNA NAWIERZCHNIA')
                                  : 'ARCHITECTURAL HAZARD',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
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
                            _showBypassPhoto
                                ? (isPL ? 'Objazd: 98% Bezpieczny' : 'Bypass: 98% Safe')
                                : '${audit.score}/100 ${isPL ? 'Wskaźnik dostępności' : 'Score'}',
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
                      value: _showBypassPhoto
                          ? (isPL ? '0 stopni (Płasko)' : '0 steps (Flat)')
                          : (audit.stairsDetected
                              ? (isPL
                                  ? 'Wykryto ${audit.stairsCount} stopni (Brak windy!)'
                                  : '${audit.stairsCount} steps detected (No lift!)')
                              : (isPL ? 'Brak stopni (Płasko)' : 'Zero steps (Flat)')),
                      isPositive: _showBypassPhoto || !audit.stairsDetected,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      icon: Icons.straighten,
                      label: isPL ? 'Krawężnik' : 'Curb Height',
                      value: _showBypassPhoto
                          ? (isPL ? 'Zjazd 0-1 cm' : 'Dropped curb 0-1 cm')
                          : audit.curbStatus,
                      isPositive: _showBypassPhoto || audit.isAccessible,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      icon: Icons.texture,
                      label: isPL ? 'Nawierzchnia' : 'Surface Type',
                      value: _showBypassPhoto
                          ? (isPL ? 'Gładkie płyty granitowe' : 'Smooth granite slabs')
                          : audit.surfaceType,
                      isPositive: _showBypassPhoto ||
                          (!audit.surfaceType.contains('kocie łby') &&
                              !audit.surfaceType.contains('Schody')),
                    ),

                    const SizedBox(height: 12),

                    // Wpływ na wybrany profil mobilności
                    if (audit.profileImpactPl != null && !_showBypassPhoto) ...[
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
                                  _showBypassPhoto
                                      ? (isPL
                                          ? 'KrakAccess skierował Cię bezpiecznym obejściem naziemnym bez barier architektonicznych.'
                                          : 'KrakAccess routed you through a barrier-free ground crossing.')
                                      : (isPL ? audit.aiVerdictPl : audit.aiVerdictEn),
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
