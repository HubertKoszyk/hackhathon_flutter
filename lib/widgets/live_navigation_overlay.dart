import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transit_route_info.dart';
import '../providers/app_state.dart';

class LiveNavigationOverlay extends StatelessWidget {
  const LiveNavigationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final currentStep = state.currentStep;
    final nextStep = state.nextStep;
    final isTransit = state.currentRoute?.isTransit == true;
    final transitInfo = state.currentRoute?.transitInfo;

    return Stack(
      children: [
        // 1. GÓRNY PASEK MANEWRU (GOOGLE MAPS STYLE HUD)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Główny kafelek manewru (Google Maps / MPK GTFS style)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isTransit
                            ? const [Color(0xFF0369A1), Color(0xFF0284C7)]
                            : const [Color(0xFF064E3B), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTransit
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.8)
                            : const Color(0xFF34D399).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isTransit
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF064E3B))
                                  .withValues(alpha: 0.5),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Ikona najbliższego manewru z opcjonalnym badge linii MPK
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Icon(
                                    currentStep?.maneuverIcon ??
                                        (isTransit
                                            ? Icons.tram
                                            : Icons.navigation),
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                if (isTransit && transitInfo != null)
                                  Positioned(
                                    bottom: -5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: const Color(0xFF38BDF8),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        transitInfo.transitLeg.lineName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Dystans i instrukcja skrętu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _formatDistance(
                                          state.distanceToNextStep,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isPL ? 'do manewru' : 'to turn',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentStep != null
                                        ? (isPL
                                              ? currentStep.instructionPl
                                              : currentStep.instructionEn)
                                        : (isPL
                                              ? 'Podążaj wyznaczoną trasą'
                                              : 'Follow the route'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Wskazówka dostępności (WCAG Accessibility cue)
                        if (currentStep?.accessibilityNotePl != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getProfileIcon(state.profile),
                                  color: const Color(0xFF34D399),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isPL
                                        ? currentStep!.accessibilityNotePl!
                                        : (currentStep!.accessibilityNoteEn ??
                                              currentStep.accessibilityNotePl ??
                                              ''),
                                    style: const TextStyle(
                                      color: Color(0xFFD1FAE5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Podgląd następnego manewru
                        if (nextStep != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.subdirectory_arrow_right,
                                color: Colors.white60,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPL ? 'Następnie: ' : 'Then: ',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isPL
                                      ? nextStep.instructionPl
                                      : nextStep.instructionEn,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. Alert zbliżania się do przeszkody / objazdu (Hazard Proximity Warning)
                  if (state.approachingHazardAlert != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF991B1B).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF87171)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.approachingHazardAlert!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
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
        ),

        // 3. BOCZNE KONTROLKI PŁYWAJĄCE (Centrowanie, Dźwięk, Prędkość symulacji)
        Positioned(
          right: 14,
          bottom: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Przycisk ponownego wycentrowania mapy na użytkowniku
              FloatingActionButton.small(
                heroTag: 'nav_recenter_btn',
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: const Color(0xFF38BDF8),
                elevation: 4,
                tooltip: isPL ? 'Centruj na mnie' : 'Recenter',
                onPressed: state.triggerRecenterMap,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 10),

              // Przycisk wyciszenia wskazówek głosowych
              FloatingActionButton.small(
                heroTag: 'nav_voice_btn',
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: state.isVoiceMuted
                    ? Colors.white54
                    : const Color(0xFF10B981),
                elevation: 4,
                tooltip: isPL ? 'Wskazówki głosowe' : 'Voice cues',
                onPressed: state.toggleVoiceMute,
                child: Icon(
                  state.isVoiceMuted ? Icons.volume_off : Icons.volume_up,
                ),
              ),
              const SizedBox(height: 10),

              // Pigułka kontroli symulacji Live Demo (Play / Pause & Speed)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        state.isSimulatingNavigation
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: const Color(0xFF38BDF8),
                        size: 26,
                      ),
                      tooltip: state.isSimulatingNavigation
                          ? 'Wstrzymaj symulację'
                          : 'Wznów symulację',
                      onPressed: state.toggleSimulationPlayPause,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        // Cykliczna zmiana prędkości: 1x -> 2x -> 4x -> 1x
                        final current = state.simulationSpeedMultiplier;
                        final next = current == 1.0
                            ? 2.0
                            : (current == 2.0 ? 4.0 : 1.0);
                        state.setSimulationSpeed(next);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${state.simulationSpeedMultiplier.toInt()}x',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. DOLNY PANEL NAWIGACJI (GOOGLE MAPS STYLE DASHBOARD)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pasek postępu trasy
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _calculateProgress(state),
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Czas do celu
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _formatDurationMinutes(
                                    state.remainingDurationSeconds,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPL ? 'min' : 'min',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatDistance(state.remainingDistance),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(color: Colors.white38),
                                ),
                                Text(
                                  'ETA ${_calculateEta(state.remainingDurationSeconds)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Wskaźnik prędkości marszu / trybu podróży (Pieszo vs GTFS)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTransit
                                  ? const Color(
                                      0xFF38BDF8,
                                    ).withValues(alpha: 0.4)
                                  : Colors.white12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                isTransit && transitInfo != null
                                    ? '${transitInfo.transitLeg.vehicleType == TransitVehicleType.tram ? "Tram" : "Bus"} ${transitInfo.transitLeg.lineName}'
                                    : '${state.currentWalkingSpeedKmh.toStringAsFixed(1)} km/h',
                                style: TextStyle(
                                  color: isTransit
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isTransit
                                    ? 'GTFS Live'
                                    : (isPL ? 'Prędkość' : 'Speed'),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Przycisk Zakończ (Czerwony okrągły X)
                        ElevatedButton.icon(
                          onPressed: () {
                            state.stopNavigation();
                            state.clearRoutes();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(
                            isPL ? 'Zakończ' : 'Exit',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 5. DIALOG OSIĄGNIĘCIA CELU (CELEBRATION OVERLAY)
        if (state.hasReachedDestination)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPL ? 'Dotarłeś do celu!' : 'You have arrived!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPL
                            ? 'Trasa bez barier NavAble pokonana pomyślnie.'
                            : 'NavAble barrier-free route completed.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              '0',
                              isPL ? 'Schodów' : 'Stairs',
                              const Color(0xFF34D399),
                            ),
                            _buildStatItem(
                              '100%',
                              isPL ? 'Rampy 0cm' : '0cm curbs',
                              const Color(0xFF38BDF8),
                            ),
                            _buildStatItem(
                              '${state.currentRoute?.stairsAvoided ?? 0}',
                              isPL ? 'Ominiętych' : 'Avoided',
                              const Color(0xFFFBBF24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            state.stopNavigation();
                            state.clearRoutes();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isPL ? 'Wróć do mapy Krakowa' : 'Back to map',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildStatItem(String val, String lbl, Color col) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: col,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(lbl, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  static String _formatDurationMinutes(int totalSeconds) {
    final mins = (totalSeconds / 60).ceil();
    return '$mins';
  }

  static String _calculateEta(int remainingSeconds) {
    final now = DateTime.now().add(Duration(seconds: remainingSeconds));
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static double _calculateProgress(AppState state) {
    final total = state.currentRoute?.distanceMeters.toDouble() ?? 1.0;
    if (total <= 0) return 0.0;
    final walked = (total - state.remainingDistance).clamp(0.0, total);
    return walked / total;
  }

  static IconData _getProfileIcon(MobilityProfile p) {
    switch (p) {
      case MobilityProfile.wheelchair:
        return Icons.accessible;
      case MobilityProfile.cane:
        return Icons.elderly;
      case MobilityProfile.stroller:
        return Icons.baby_changing_station;
    }
  }
}
