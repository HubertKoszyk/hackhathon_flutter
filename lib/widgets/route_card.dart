import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../models/transit_route_info.dart';
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
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.5),
          ),
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
                        isPL
                            ? 'NavAble AI w toku...'
                            : 'NavAble AI analyzing...',
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
                        onTap: () =>
                            _openSearchSheet(context, LocationPickMode.start),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.trip_origin,
                                color: Color(0xFF10B981),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isPL
                                      ? state.startLocation.namePl
                                      : state.startLocation.nameEn,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF38BDF8),
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: state.useCurrentLocationAsStart,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0284C7,
                                      ).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF38BDF8,
                                        ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.my_location,
                                          color: Color(0xFF38BDF8),
                                          size: 11,
                                        ),
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
                              const Icon(
                                Icons.search,
                                color: Colors.white38,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Punkt docelowy (B)
                      InkWell(
                        onTap: () => _openSearchSheet(
                          context,
                          LocationPickMode.destination,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFEF4444),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.destinationLocation != null
                                      ? (isPL
                                            ? state.destinationLocation!.namePl
                                            : state.destinationLocation!.nameEn)
                                      : (isPL
                                            ? 'Wybierz cel...'
                                            : 'Choose destination...'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.search,
                                color: Colors.white38,
                                size: 14,
                              ),
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
                    child: const Icon(
                      Icons.swap_vert,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // 2. Zakładki tras: Dostępna Pieszo vs GTFS Komunikacja vs Standardowa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: state.routes.asMap().entries.map((entry) {
                final idx = entry.key;
                final route = entry.value;
                final isSelected = idx == state.selectedRouteIndex;
                final isAccessible = route.type == RouteType.accessible;
                final isTransit = route.type == RouteType.transit;

                // Styl i kolory kafelka
                final Color activeColor = isTransit
                    ? const Color(0xFF0369A1) // Sky / Blue MPK
                    : (isAccessible
                          ? const Color(0xFF065F46) // Emerald
                          : const Color(0xFF7F1D1D)); // Red

                final Color activeBorder = isTransit
                    ? const Color(0xFF38BDF8)
                    : (isAccessible
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171));

                final IconData tabIcon = isTransit
                    ? (route.transitInfo?.transitLeg.vehicleType ==
                              TransitVehicleType.tram
                          ? Icons.tram
                          : Icons.directions_bus)
                    : (isAccessible
                          ? Icons.check_circle
                          : Icons.warning_rounded);

                final String tabTitle = isTransit
                    ? '${route.transitInfo?.transitLeg.vehicleType == TransitVehicleType.tram ? (isPL ? "Tram" : "Tram") : (isPL ? "Bus" : "Bus")} ${route.transitInfo?.transitLeg.lineName ?? ""}'
                    : (isAccessible
                          ? (isPL ? 'Pieszo (WCAG)' : 'Walk (WCAG)')
                          : (isPL ? 'Pieszo std.' : 'Standard'));

                return Expanded(
                  child: GestureDetector(
                    onTap: () => state.selectRoute(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: idx < state.routes.length - 1 ? 5 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? activeBorder : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                tabIcon,
                                size: 12.5,
                                color: isSelected ? Colors.white : activeBorder,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  tabTitle,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
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
                                '${route.durationMinutes} min',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : activeBorder,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isTransit
                                      ? const Color(
                                          0xFF0284C7,
                                        ).withValues(alpha: 0.35)
                                      : (isAccessible
                                            ? const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.3)
                                            : const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  isTransit
                                      ? (route.transitInfo?.isFastest == true
                                            ? '🚀 Szybka'
                                            : '0 st.')
                                      : (isAccessible
                                            ? (route.stairsAvoided > 0
                                                  ? '-${route.stairsAvoided} st.'
                                                  : '0 st.')
                                            : (route.stairsCount > 0
                                                  ? '${route.stairsCount} st.'
                                                  : '0 st.')),
                                  style: TextStyle(
                                    color: isTransit
                                        ? const Color(0xFFBAE6FD)
                                        : (isAccessible
                                              ? const Color(0xFF34D399)
                                              : (route.stairsCount > 0
                                                    ? const Color(0xFFFCA5A5)
                                                    : Colors.white70)),
                                    fontSize: 8.5,
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

          // 2.5 Dedykowana sekcja trasy Komunikacji Miejskiej GTFS (MPK Kraków)
          if (activeRoute.isTransit && activeRoute.transitInfo != null)
            _buildTransitInfoCard(
              context,
              activeRoute,
              activeRoute.transitInfo!,
              isPL,
            ),

          // 2.8 Podpowiedź o dostępnej komunikacji miejskiej GTFS (tramwaj/autobus)
          if (!activeRoute.isTransit &&
              state.routes.any((r) => r.isTransit)) ...[
            Builder(
              builder: (ctx) {
                final tRoute = state.routes.firstWhere((r) => r.isTransit);
                final tLeg = tRoute.transitInfo?.transitLeg;
                final tIdx = state.routes.indexOf(tRoute);
                final timeDiff =
                    activeRoute.durationMinutes - tRoute.durationMinutes;
                final isTram = tLeg?.vehicleType == TransitVehicleType.tram;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  child: InkWell(
                    onTap: () => state.selectRoute(tIdx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0369A1).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTram ? Icons.tram : Icons.directions_bus,
                            color: const Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isPL
                                  ? 'Dostępny ${isTram ? "tramwaj" : "autobus"} ${tLeg?.lineName ?? ""} (${tRoute.durationMinutes} min)${timeDiff > 0 ? " • $timeDiff min szybciej!" : " • 0 schodów"}'
                                  : 'Available ${isTram ? "tram" : "bus"} ${tLeg?.lineName ?? ""} (${tRoute.durationMinutes} min)${timeDiff > 0 ? " • $timeDiff min faster!" : " • 0 stairs"}',
                              style: const TextStyle(
                                color: Color(0xFFBAE6FD),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isPL ? 'Wybierz' : 'Switch',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          // 3. Pasek ostrzeżenia o przeszkodzie z przyciskiem do zdjęcia
          if (!activeRoute.isTransit && activeRoute.detectedBarrierPl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (activeRoute.type == RouteType.accessible
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
                            isPL
                                ? activeRoute.detectedBarrierPl!
                                : (activeRoute.detectedBarrierEn ??
                                      activeRoute.detectedBarrierPl!),
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
                              isPL
                                  ? activeRoute.bypassReasonPl!
                                  : (activeRoute.bypassReasonEn ??
                                        activeRoute.bypassReasonPl!),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                              ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF38BDF8)),
                          ),
                          child: Text(
                            isPL ? 'Audyt AI 📸' : 'AI Audit 📸',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
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
                  children:
                      (isPL
                              ? activeRoute.profileHighlightsPl
                              : activeRoute.profileHighlightsEn)
                          .map((badge) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: activeRoute.type == RouteType.accessible
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.15)
                                    : const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      activeRoute.type == RouteType.accessible
                                      ? const Color(
                                          0xFF34D399,
                                        ).withValues(alpha: 0.3)
                                      : const Color(
                                          0xFFF87171,
                                        ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color:
                                      activeRoute.type == RouteType.accessible
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          })
                          .toList(),
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
                      : (activeRoute.stairsCount > 0
                            ? const Color(0xFFF87171)
                            : const Color(0xFF34D399)),
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
                      isPL
                          ? activeRoute.surfaceSummaryPl
                          : activeRoute.surfaceSummaryEn,
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

          // 6. Przyciski akcji: "Rozpocznij trasę (Live Navigation)" oraz "Audyt Street View"
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                // Główny przycisk nawigacji Live Google Maps
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: state.startNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeRoute.isTransit
                          ? const Color(0xFF0284C7) // MPK Blue
                          : const Color(0xFF10B981), // Emerald Google Maps
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor:
                          (activeRoute.isTransit
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF10B981))
                              .withValues(alpha: 0.5),
                    ),
                    icon: Icon(
                      activeRoute.isTransit
                          ? (activeRoute.transitInfo?.transitLeg.vehicleType ==
                                    TransitVehicleType.tram
                                ? Icons.tram
                                : Icons.directions_bus)
                          : Icons.navigation,
                      size: 18,
                    ),
                    label: Text(
                      activeRoute.isTransit
                          ? (isPL
                                ? 'Rozpocznij trasę (${activeRoute.transitInfo?.transitLeg.vehicleType == TransitVehicleType.tram ? "Tramwaj" : "Autobus"} ${activeRoute.transitInfo?.transitLeg.lineName})'
                                : 'Start Route (${activeRoute.transitInfo?.transitLeg.vehicleType == TransitVehicleType.tram ? "Tram" : "Bus"} ${activeRoute.transitInfo?.transitLeg.lineName})')
                          : (isPL ? 'Rozpocznij trasę' : 'Start Navigation'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (activeRoute.audits.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // Przycisk Audytu Street View
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          state.openAudit(activeRoute.audits.first),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.streetview, size: 16),
                      label: Text(
                        isPL ? 'Street View' : 'Street View',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitInfoCard(
    BuildContext context,
    RouteModel route,
    TransitRouteInfo tInfo,
    bool isPL,
  ) {
    final leg = tInfo.transitLeg;
    final isTram = leg.vehicleType == TransitVehicleType.tram;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF0C243B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Linia, kierunek i odjazd GTFS Live
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isTram
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTram ? Icons.tram : Icons.directions_bus,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      leg.lineName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '➔ ${leg.headsign}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Przystanek: ${leg.departureStop.name}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'za ${leg.departureMinutesAway} min',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Banner zysku czasowego
          if (tInfo.isFastest) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      isPL
                          ? 'NAJSZYBSZA TRASA: Oszczędzasz ${tInfo.timeSavedMinutes} min vs marsz pieszy!'
                          : 'FASTEST ROUTE: Save ${tInfo.timeSavedMinutes} min vs walking!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 6),

          // 3. Weryfikacja peronu i taboru GTFS
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.accessible_forward,
                      color: Color(0xFF38BDF8),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isPL
                            ? leg.departureStop.platformBadgeTextPl
                            : leg.departureStop.platformBadgeTextEn,
                        style: const TextStyle(
                          color: Color(0xFFBAE6FD),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '0 schodów',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPL
                      ? leg.departureStop.platformDescriptionPl
                      : leg.departureStop.platformDescriptionEn,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF34D399),
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        leg.vehicleName,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 8.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // 4. Dojście ➔ Przejazd ➔ Dojście
          Row(
            children: [
              const Icon(Icons.alt_route, color: Color(0xFF94A3B8), size: 12),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isPL
                      ? tInfo.summaryDescriptionPl
                      : tInfo.summaryDescriptionEn,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ),
            ],
          ),

          // 5. Kolejne kursy z rozkładu GTFS
          if (leg.nextDeparturesFormatted.length > 1) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white38, size: 11),
                const SizedBox(width: 4),
                Text(
                  isPL ? 'Kolejne odjazdy GTFS: ' : 'Next departures: ',
                  style: const TextStyle(color: Colors.white38, fontSize: 8.5),
                ),
                Expanded(
                  child: Text(
                    leg.nextDeparturesFormatted.skip(1).join('  •  '),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 8.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}
