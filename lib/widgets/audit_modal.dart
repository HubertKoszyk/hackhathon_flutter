import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/accessibility_audit.dart';
import '../providers/app_state.dart';
import '../theme.dart';

/// Nowoczesny modal audytu fotograficznego Street View AI
/// w pełni dostosowany do nowego, jasnego stylu z theme.dart
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
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final audit = widget.audit;
    final hasBypassPhoto =
        audit.bypassPhotoUrl != null && audit.bypassPhotoUrl!.isNotEmpty;

    final currentPhoto = (_showBypassPhoto && hasBypassPhoto)
        ? audit.bypassPhotoUrl!
        : audit.photoUrl;

    final bool isShowingBarrier = audit.isAccessible
        ? _showBypassPhoto
        : !_showBypassPhoto;

    final headerTitle =
        (isShowingBarrier && audit.isAccessible && audit.bypassTitlePl != null)
        ? (isPL
              ? audit.bypassTitlePl!
              : (audit.bypassTitleEn ?? audit.bypassTitlePl!))
        : audit.checkpointName;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 480,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isShowingBarrier
                ? theme.colorScheme.error.withValues(alpha: 0.5)
                : theme.colorScheme.outline,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isShowingBarrier
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Górny nagłówek z badge'ami AI i profilem
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isShowingBarrier
                              ? kColorGrayScheme.error
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isShowingBarrier
                              ? Icons.warning_amber_rounded
                              : Icons.verified,
                          color: isShowingBarrier
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          size: 22,
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
                                  isShowingBarrier
                                      ? (audit.isAccessible
                                            ? (isPL
                                                  ? 'OMINIĘTA PRZESZKODA'
                                                  : 'AVOIDED OBSTACLE')
                                            : (isPL
                                                  ? 'WYKRYTA PRZESZKODA'
                                                  : 'OBSTACLE DETECTED'))
                                      : (isPL
                                            ? 'AUDYT STREET VIEW AI'
                                            : 'STREET VIEW AI AUDIT'),
                                  style: TextStyle(
                                    color: isShowingBarrier
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kColorGrayScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: kColorGrayScheme.secondary,
                                      ),
                                    ),
                                    child: Text(
                                      _getProfileLabel(state.profile, isPL),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              headerTitle,
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          size: 22,
                        ),
                        onPressed: state.closeAudit,
                      ),
                    ],
                  ),
                ),

                // 2. Przełącznik "Bariera" vs "Trakt KrakAccess" (jeśli dostępny bypass)
                if (hasBypassPhoto)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: kColorGrayScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kColorGrayScheme.secondary),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _showBypassPhoto = false),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !_showBypassPhoto
                                      ? theme.colorScheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_showBypassPhoto
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                  border: !_showBypassPhoto
                                      ? Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.6),
                                        )
                                      : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        audit.isAccessible
                                            ? Icons.check_circle_outline
                                            : Icons.warning_amber_rounded,
                                        color: audit.isAccessible
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          audit.isAccessible
                                              ? (isPL
                                                    ? 'Droga NavAble (Płasko)'
                                                    : 'NavAble Path (Flat)')
                                              : (isPL
                                                    ? 'Bariera na trasie'
                                                    : 'Barrier on route'),
                                          style: TextStyle(
                                            color: !_showBypassPhoto
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.55),
                                            fontSize: 12,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _showBypassPhoto = true),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _showBypassPhoto
                                      ? theme.colorScheme.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _showBypassPhoto
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                  border: _showBypassPhoto
                                      ? Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.6),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      audit.isAccessible
                                          ? Icons.visibility_outlined
                                          : Icons.check_circle_outline,
                                      color: audit.isAccessible
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      audit.isAccessible
                                          ? (isPL
                                                ? 'Ominięta przeszkoda'
                                                : 'Avoided Obstacle')
                                          : (isPL
                                                ? 'Objazd NavAble'
                                                : 'NavAble Bypass'),
                                      style: TextStyle(
                                        color: _showBypassPhoto
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.55),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: SizedBox(
                          height: 205,
                          width: double.infinity,
                          child: _buildStreetViewImage(
                            currentPhoto,
                            isShowingBarrier,
                          ),
                        ),
                      ),

                      // Overlay z delikatnym gradientem dla czytelności etykiet
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Znacznik zweryfikowanej dostępności
                      if (!isShowingBarrier)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPL
                                      ? 'DROGA BEZ BARIER'
                                      : 'BARRIER-FREE ROUTE',
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
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isShowingBarrier
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isShowingBarrier
                                    ? Icons.block
                                    : Icons.check_circle,
                                color: isShowingBarrier
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isShowingBarrier
                                    ? (audit.isAccessible
                                          ? (isPL
                                                ? 'Bariera na trasie prostej: 25/100'
                                                : 'Direct path barrier: 25/100')
                                          : '${audit.score}/100 ${isPL ? 'Wskaźnik dostępności' : 'Score'}')
                                    : (isPL
                                          ? 'Wskaźnik dostępności: 98%'
                                          : 'Wskaźnik dostępności: 98%'),
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
                ),

                // 4. Parametry architektoniczne punktu
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kColorGrayScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kColorGrayScheme.secondary),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              theme: theme,
                              icon: Icons.stairs,
                              label: isPL ? 'Schody' : 'Stairs',
                              value: isShowingBarrier
                                  ? (audit.stairsCount > 0
                                        ? (isPL
                                              ? 'Wykryto ${audit.stairsCount} stopni (Brak windy / rampy!)'
                                              : '${audit.stairsCount} steps detected (No ramp / lift!)')
                                        : (isPL
                                              ? '0 stopni (Bariera krawężnikowa / nawierzchnia)'
                                              : '0 steps (Curbs & surface barrier)'))
                                  : (isPL
                                        ? '0 stopni (Płasko)'
                                        : '0 steps (Flat)'),
                              isPositive: !isShowingBarrier,
                            ),
                            const Divider(height: 14, thickness: 0.8),
                            _buildFeatureRow(
                              theme: theme,
                              icon: Icons.straighten,
                              label: isPL ? 'Krawężnik' : 'Curb Height',
                              value: isShowingBarrier
                                  ? (audit.curbStatus.isNotEmpty
                                        ? audit.curbStatus
                                        : (isPL
                                              ? 'Krawężnik 12-14 cm'
                                              : '12-14 cm curb'))
                                  : (isPL
                                        ? 'Zjazd 0-1 cm zlicowany z jezdnią'
                                        : 'Dropped curb 0-1 cm flush'),
                              isPositive: !isShowingBarrier,
                            ),
                            const Divider(height: 14, thickness: 0.8),
                            _buildFeatureRow(
                              theme: theme,
                              icon: Icons.texture,
                              label: isPL ? 'Nawierzchnia' : 'Surface Type',
                              value: isShowingBarrier
                                  ? (audit.surfaceType.isNotEmpty
                                        ? audit.surfaceType
                                        : (isPL
                                              ? 'Nierówna kostka / schody'
                                              : 'Uneven cobblestone / stairs'))
                                  : (isPL
                                        ? 'Gładkie płyty granitowe / asfalt szlifowany'
                                        : 'Smooth granite slabs / asphalt'),
                              isPositive: !isShowingBarrier,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Wpływ na wybrany profil mobilności
                      if (audit.profileImpactPl != null &&
                          isShowingBarrier) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getProfileIcon(state.profile),
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isPL
                                      ? audit.profileImpactPl!
                                      : (audit.profileImpactEn ??
                                            audit.profileImpactPl!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 12,
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.travel_explore,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPL
                                          ? 'ZDJĘCIE POBRANE NA ŻYWO (GPS)'
                                          : 'LIVE GEOSEARCH PHOTO (GPS)',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isPL
                                          ? 'Fotografia pobrana w czasie rzeczywistym z Wikimedia Commons GeoSearch dla współrzędnych tej przeszkody (${audit.location.latitude.toStringAsFixed(4)}°N, ${audit.location.longitude.toStringAsFixed(4)}°E)\nObiekt: ${audit.photoTitle ?? "Okolice punktu"}\nAutor: ${audit.photoSourceAttribution ?? "Creative Commons"}'
                                          : 'Real-time photograph fetched from Wikimedia Commons GeoSearch for obstacle coordinates (${audit.location.latitude.toStringAsFixed(4)}°N, ${audit.location.longitude.toStringAsFixed(4)}°E)\nSubject: ${audit.photoTitle ?? "Location"}\nAuthor: ${audit.photoSourceAttribution ?? "Creative Commons"}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 10.5,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
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
                          color: isShowingBarrier
                              ? kColorGrayScheme.error.withValues(alpha: 0.5)
                              : theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.6,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isShowingBarrier
                                ? theme.colorScheme.error.withValues(alpha: 0.4)
                                : theme.colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.psychology,
                              color: isShowingBarrier
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPL ? 'Werdykt AI:' : 'AI Verdict:',
                                    style: TextStyle(
                                      color: isShowingBarrier
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isShowingBarrier
                                        ? (audit.isAccessible
                                              ? (isPL
                                                    ? 'Ominięto tę barierę dzięki alternatywnej trasie NavAble.'
                                                    : 'This barrier is avoided via the NavAble route.')
                                              : (isPL
                                                    ? audit.aiVerdictPl
                                                    : audit.aiVerdictEn))
                                        : (isPL
                                              ? (audit.isAccessible
                                                    ? audit.aiVerdictPl
                                                    : 'NavAble skierował Cię bezpiecznym obejściem naziemnym bez barier architektonicznych.')
                                              : (audit.isAccessible
                                                    ? audit.aiVerdictEn
                                                    : 'NavAble routed you through a flat, barrier-free path.')),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Przycisk zamknij
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: state.closeAudit,
                          child: Text(
                            isPL ? 'Wróć do mapy' : 'Back to map',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary,
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
          color: kColorGrayScheme.primary,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(ctx).colorScheme.primary,
            ),
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
    required ThemeData theme,
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
          color: isPositive
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.error,
              fontSize: 12,
              fontWeight: isPositive ? FontWeight.w600 : FontWeight.w700,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
