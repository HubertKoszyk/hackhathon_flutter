import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/app_state.dart';
import '../services/routing_service.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeRoute = state.currentRoute;
    final isPL = state.language == 'pl';

    if (state.isLoadingDynamicRoute) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isPL
                    ? 'KrakAccess AI: Wyznaczanie trasy bez barier z OSRM...'
                    : 'KrakAccess AI: Calculating accessible route with OSRM...',
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (activeRoute == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          // 1. Selector presetów lub informacja o trasie z mapy
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                const Icon(Icons.explore, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: state.customPin != null
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                isPL ? 'Dynamiczna trasa do wybranego punktu' : 'Dynamic route to chosen pin',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: state.clearCustomPin,
                              child: const Icon(Icons.close, color: Colors.white60, size: 16),
                            ),
                          ],
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: state.selectedPresetId,
                            dropdownColor: const Color(0xFF1E293B),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                            items: RoutingService.presets.map((preset) {
                              return DropdownMenuItem<String>(
                                value: preset.id,
                                child: Text(
                                  isPL ? preset.titlePl : preset.titleEn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) state.selectPreset(newId);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // 2. Zakładki tras: Dostępna (Zielona) vs Standardowa (Czerwona)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
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
                          const SizedBox(height: 3),
                          Text(
                            '${route.accessibilityScore}% ${state.tr('route_score')}',
                            style: TextStyle(
                              color: isAccessible
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Informacja o wykrytej barierze i ominięciu przez AI (The "WOW" Street View prompt)
          if (activeRoute.detectedBarrierPl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.streetview, color: Color(0xFFF87171), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPL ? activeRoute.detectedBarrierPl! : (activeRoute.detectedBarrierEn ?? activeRoute.detectedBarrierPl!),
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (activeRoute.bypassReasonPl != null)
                            Text(
                              isPL ? activeRoute.bypassReasonPl! : (activeRoute.bypassReasonEn ?? activeRoute.bypassReasonPl!),
                              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 9.5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPL ? 'Zdjęcie 📸' : 'Photo 📸',
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 4. Cechy dostosowane pod wybrany profil (Wózek, Senior, Wózek dziecięcy)
          if (activeRoute.profileHighlightsPl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (isPL ? activeRoute.profileHighlightsPl : activeRoute.profileHighlightsEn).map((badge) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

          // 5. Metryki trasy (czas, schody, gładkość)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric(
                  icon: Icons.timer_outlined,
                  value: '${activeRoute.durationMinutes} min',
                  label: activeRoute.getDistanceString(),
                ),
                _buildMetric(
                  icon: Icons.stairs_outlined,
                  value: activeRoute.type == RouteType.accessible
                      ? '0'
                      : '${activeRoute.stairsAvoided}',
                  label: activeRoute.type == RouteType.accessible
                      ? '${activeRoute.stairsAvoided} ${state.tr('steps_avoided')}'
                      : 'schodów',
                  highlightColor: activeRoute.type == RouteType.accessible
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                ),
                _buildMetric(
                  icon: Icons.speed,
                  value: '${activeRoute.accessibilityScore}/100',
                  label: state.tr('smoothness'),
                ),
              ],
            ),
          ),

          // 6. Przycisk Audytu AI Street View
          if (activeRoute.audits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => state.openAudit(activeRoute.audits.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.streetview, size: 17),
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
        Icon(icon, size: 16, color: highlightColor ?? Colors.white70),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
