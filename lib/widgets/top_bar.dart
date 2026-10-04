import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/vision_audit_service.dart';
import 'api_key_dialog.dart';
import 'data_sources_dialog.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Górny pasek tytułowy z logo i kompaktowymi przełącznikami
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.96), // Deep navy
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  // Logo / Ikona
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.accessible_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tytuł i miasto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              state.tr('app_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                'KRAKÓW',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          state.tr('app_subtitle'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Grupa kompaktowych przycisków akcji
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Przycisk statusu Gemini AI API
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ApiKeyDialog(),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 16),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: VisionAuditService.hasApiKey
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Przycisk warstwy parkingów
                      InkWell(
                        onTap: state.toggleParkingLayer,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: state.showParkingLayer
                                ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: state.showParkingLayer
                                  ? const Color(0xFF38BDF8)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            Icons.local_parking,
                            size: 18,
                            color: state.showParkingLayer
                                ? const Color(0xFF38BDF8)
                                : Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Przycisk informacji o źródłach danych
                      InkWell(
                        onTap: () {
                          showDataSourcesDialog(context);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Przełącznik języka (PL / EN)
                      InkWell(
                        onTap: state.toggleLanguage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            state.language == 'pl' ? '🇵🇱 PL' : '🇬🇧 EN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Profile mobilności (Wózek, O kuli / Senior, Wózek dziecięcy)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildProfileChip(
                    context,
                    label: state.tr('profile_wheelchair'),
                    icon: Icons.accessible,
                    isSelected: state.profile == MobilityProfile.wheelchair,
                    onTap: () => state.setProfile(MobilityProfile.wheelchair),
                  ),
                  const SizedBox(width: 6),
                  _buildProfileChip(
                    context,
                    label: state.tr('profile_cane'),
                    icon: Icons.elderly,
                    isSelected: state.profile == MobilityProfile.cane,
                    onTap: () => state.setProfile(MobilityProfile.cane),
                  ),
                  const SizedBox(width: 6),
                  _buildProfileChip(
                    context,
                    label: state.tr('profile_stroller'),
                    icon: Icons.baby_changing_station,
                    isSelected: state.profile == MobilityProfile.stroller,
                    onTap: () => state.setProfile(MobilityProfile.stroller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981) // Emerald
              : const Color(0xFF1E293B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF34D399) : Colors.white12,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
