import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/app_state.dart';
import 'route_search_sheet.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({super.key});

  void _openSearchSheet(BuildContext context, LocationPickMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RouteSearchSheet(pickMode: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeRoute = state.currentRoute;
    final isPL = state.language == 'pl';

    // 1. Widok analizy i "myślenia" systemu AI
    if (state.isAnalyzingRoute) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPL ? 'KrakAccess AI w toku...' : 'KrakAccess AI analyzing...',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        state.analysisStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (activeRoute == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.97), // Slate 900
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Elegancki selektor punktu A i B (Skąd ➔ Dokąd)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Punkt startowy (A)
                      InkWell(
                        onTap: () => _openSearchSheet(context, LocationPickMode.start),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isPL ? state.startLocation.namePl : state.startLocation.nameEn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (state.isLocatingUser)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                                )
                              else
                                InkWell(
                                  onTap: state.useCurrentLocationAsStart,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.my_location, color: Color(0xFF38BDF8), size: 11),
                                        SizedBox(width: 3),
                                        Text(
                                          'GPS',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(Icons.search, color: Colors.white38, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Punkt docelowy (B)
                      InkWell(
                        onTap: () => _openSearchSheet(context, LocationPickMode.destination),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isPL ? state.destinationLocation.namePl : state.destinationLocation.nameEn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.search, color: Colors.white38, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Przycisk zamiany Start/Koniec (Swap)
                InkWell(
                  onTap: state.swapLocations,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_vert, color: Color(0xFF38BDF8), size: 20),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // 2. Zakładki tras: Dostępna (Zielona) vs Standardowa (Czerwona) - MAJĄ RÓŻNE WSPÓŁRZĘDNE!
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: state.routes.asMap().entries.map((entry) {
                final idx = entry.key;
                final route = entry.value;
                final isSelected = idx == state.selectedRouteIndex;
                final isAccessible = route.type == RouteType.accessible;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => state.selectRoute(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: idx == 0 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isAccessible
                                ? const Color(0xFF065F46)
                                : const Color(0xFF7F1D1D))
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isAccessible
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171))
                              : Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isAccessible ? Icons.check_circle : Icons.warning_rounded,
                                size: 13,
                                color: isAccessible
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFF87171),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  isAccessible
                                      ? state.tr('route_accessible')
                                      : state.tr('route_standard'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${route.accessibilityScore}% ${state.tr('route_score')}',
                                style: TextStyle(
                                  color: isAccessible
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isAccessible
                                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAccessible
                                      ? (route.stairsAvoided > 0
                                          ? '-${route.stairsAvoided} st.'
                                          : '0 st.')
                                      : (route.stairsCount > 0
                                          ? '${route.stairsCount} st.'
                                          : '0 st.'),
                                  style: TextStyle(
                                    color: isAccessible
                                        ? const Color(0xFF34D399)
                                        : (route.stairsCount > 0 ? const Color(0xFFFCA5A5) : Colors.white70),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Pasek ostrzeżenia o przeszkodzie z przyciskiem do zdjęcia
          if (activeRoute.detectedBarrierPl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (activeRoute.type == RouteType.accessible
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeRoute.type == RouteType.accessible
                          ? Icons.shield_outlined
                          : Icons.warning_amber_rounded,
                      color: activeRoute.type == RouteType.accessible
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPL ? activeRoute.detectedBarrierPl! : (activeRoute.detectedBarrierEn ?? activeRoute.detectedBarrierPl!),
                            style: TextStyle(
                              color: activeRoute.type == RouteType.accessible
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFFFCA5A5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (activeRoute.bypassReasonPl != null)
                            Text(
                              isPL ? activeRoute.bypassReasonPl! : (activeRoute.bypassReasonEn ?? activeRoute.bypassReasonPl!),
                              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (activeRoute.audits.isNotEmpty)
                      InkWell(
                        onTap: () => state.openAudit(activeRoute.audits.first),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF38BDF8)),
                          ),
                          child: Text(
                            isPL ? 'Audyt AI 📸' : 'AI Audit 📸',
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 4. Cechy pod wybrany profil mobilności (Wózek, Senior, Wózek dziecięcy)
          if (activeRoute.profileHighlightsPl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (isPL ? activeRoute.profileHighlightsPl : activeRoute.profileHighlightsEn).map((badge) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: activeRoute.type == RouteType.accessible
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeRoute.type == RouteType.accessible
                              ? const Color(0xFF34D399).withValues(alpha: 0.3)
                              : const Color(0xFFF87171).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: activeRoute.type == RouteType.accessible
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF87171),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 5. Metryki trasy (czas, schody, wskaźnik)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric(
                  icon: Icons.timer_outlined,
                  value: '${activeRoute.durationMinutes} min',
                  label: activeRoute.getDistanceString(),
                ),
                _buildMetric(
                  icon: activeRoute.type == RouteType.accessible
                      ? Icons.task_alt
                      : Icons.stairs_outlined,
                  value: activeRoute.type == RouteType.accessible
                      ? '0'
                      : '${activeRoute.stairsCount}',
                  label: activeRoute.type == RouteType.accessible
                      ? (activeRoute.stairsAvoided > 0
                          ? '${isPL ? "ominięto" : "avoided"} ${activeRoute.stairsAvoided} st.'
                          : (isPL ? 'brak stopni' : 'zero stairs'))
                      : (activeRoute.stairsCount > 0
                          ? '${isPL ? "stopni" : "stairs"} (brak rampy)'
                          : (isPL ? 'brak stopni' : 'zero stairs')),
                  highlightColor: activeRoute.type == RouteType.accessible
                      ? const Color(0xFF34D399)
                      : (activeRoute.stairsCount > 0 ? const Color(0xFFF87171) : const Color(0xFF34D399)),
                ),
                _buildMetric(
                  icon: Icons.speed,
                  value: '${activeRoute.accessibilityScore}/100',
                  label: state.tr('smoothness'),
                  highlightColor: activeRoute.accessibilityScore >= 80
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                ),
              ],
            ),
          ),

          // 5.5 Opis nawierzchni
          if (activeRoute.surfaceSummaryPl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 1, 14, 3),
              child: Row(
                children: [
                  Icon(
                    Icons.texture,
                    size: 12,
                    color: activeRoute.type == RouteType.accessible
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF87171),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isPL ? activeRoute.surfaceSummaryPl : activeRoute.surfaceSummaryEn,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // 6. Przycisk Audytu Street View
          if (activeRoute.audits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => state.openAudit(activeRoute.audits.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.streetview, size: 16),
                  label: Text(
                    isPL
                        ? 'Audyt Street View AI (${activeRoute.audits.length} punkty ze zdjęciem)'
                        : 'AI Street View Audit (${activeRoute.audits.length} photo points)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
    Color? highlightColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: highlightColor ?? Colors.white70),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
