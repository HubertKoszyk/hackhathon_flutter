import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/accessibility_audit.dart';
import '../providers/app_state.dart';

class AuditModal extends StatelessWidget {
  final AccessibilityAudit audit;

  const AuditModal({super.key, required this.audit});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: audit.isAccessible
                ? const Color(0xFF10B981).withOpacity(0.5)
                : const Color(0xFFEF4444).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (audit.isAccessible
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444))
                  .withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nagłówek z badge'em AI
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: audit.isAccessible
                            ? const Color(0xFF10B981).withOpacity(0.2)
                            : const Color(0xFFEF4444).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        audit.isAccessible ? Icons.verified : Icons.warning_rounded,
                        color: audit.isAccessible
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isPL ? 'AUDYT AI VISION' : 'AI VISION AUDIT',
                                style: TextStyle(
                                  color: audit.isAccessible
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Gemini 1.5/2.0',
                                  style: TextStyle(color: Colors.white70, fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            audit.checkpointName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: state.closeAudit,
                    ),
                  ],
                ),
              ),

              // Zdjęcie Street View z HUDem analitycznym AI
              Stack(
                children: [
                  ClipRRect(
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        audit.photoUrl,
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

                  // Overlay z siatką skanu AI
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Etykieta wyniku na zdjęciu
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: audit.isAccessible
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF87171),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: audit.isAccessible
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${audit.score}/100 ${isPL ? 'Wskaźnik dostępności' : 'Accessibility Score'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Szczegóły wykrytych barier / udogodnień
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureRow(
                      icon: Icons.stairs,
                      label: isPL ? 'Schody / Stopnie' : 'Stairs / Steps',
                      value: audit.stairsDetected
                          ? (isPL
                              ? 'Wykryto ${audit.stairsCount} stopni (Brak windy!)'
                              : '${audit.stairsCount} steps detected (No lift!)')
                          : (isPL ? 'Brak stopni (Płasko)' : 'Zero steps (Flat)'),
                      isPositive: !audit.stairsDetected,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureRow(
                      icon: Icons.straighten,
                      label: isPL ? 'Krawężnik' : 'Curb Height',
                      value: audit.curbStatus,
                      isPositive: audit.isAccessible,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureRow(
                      icon: Icons.texture,
                      label: isPL ? 'Nawierzchnia' : 'Surface Type',
                      value: audit.surfaceType,
                      isPositive: !audit.surfaceType.contains('kocie łby') &&
                          !audit.surfaceType.contains('Schody'),
                    ),

                    const SizedBox(height: 16),

                    // Werdykt AI
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (audit.isAccessible
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (audit.isAccessible
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: audit.isAccessible
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPL ? audit.aiVerdictPl : audit.aiVerdictEn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

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
                          isPL ? 'Rozumiem, kontynuuj nawigację' : 'Got it, continue navigation',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
          size: 18,
          color: isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
