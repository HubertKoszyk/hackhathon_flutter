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

    if (activeRoute == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.96), // Slate 900
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector presetów tras (Dworzec -> Rynek / Wawel -> Kazimierz)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.explore, color: Color(0xFF38BDF8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.selectedPresetId,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                      items: RoutingService.presets.map((preset) {
                        return DropdownMenuItem<String>(
                          value: preset.id,
                          child: Text(
                            state.language == 'pl' ? preset.titlePl : preset.titleEn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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

          // Zakładki tras: Dostępna (Zielona) vs Standardowa (Czerwona)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      margin: EdgeInsets.only(right: idx == 0 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isAccessible
                                ? const Color(0xFF065F46)
                                : const Color(0xFF7F1D1D))
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
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
                                size: 14,
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
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route.accessibilityScore}% ${state.tr('route_score')}',
                            style: TextStyle(
                              color: isAccessible
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                              fontSize: 14,
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

          // Szczegóły aktywnej trasy (dystans, czas, ominięte schody, nawierzchnia)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

          // Przycisk Audytu AI Street View
          if (activeRoute.audits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => state.openAudit(activeRoute.audits.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: Text(
                    '${state.tr('audit_ai_title')} (${activeRoute.audits.length} punkty)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
        Icon(icon, size: 18, color: highlightColor ?? Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
