import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../models/transit_route_info.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'filters_modal.dart';

/// Nowy ekran wyników wyszukiwania trasy łączący nowy design (karty tras ze zdjęcia)
/// oraz bogatą funkcjonalność starego designu (analiza barier, audyty AI, wskaźniki i nawigacja na żywo).
class RouteResultSheet extends StatelessWidget {
  const RouteResultSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final isUK = state.language == 'uk';

    // Podczas przeliczania wyników usuwamy wszystko inne z sheeta,
    // tak aby nie dało się w tym czasie nic zrobić.
    if (state.isAnalyzingRoute) {
      return DraggableScrollableSheet(
        initialChildSize: 0.46,
        minChildSize: 0.28,
        maxChildSize: 0.88,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  blurRadius: 20.0,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kColorGrayScheme.tertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            isPL
                                ? 'Przeliczanie trasy...'
                                : (isUK
                                      ? 'Перерахунок маршруту...'
                                      : 'Recalculating route...'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.analysisStatusText.isNotEmpty
                                ? state.analysisStatusText
                                : (isPL
                                      ? 'Dostosowywanie barier do profilu...'
                                      : (isUK
                                            ? 'Налаштування бар\'єрів під профіль...'
                                            : 'Adjusting barriers for profile...')),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 13.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final routes = state.routes;
    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeRoute = state.currentRoute ?? routes.first;
    final startName = state.startLocation.localizedName(state.language);
    final destName = state.destinationLocation != null
        ? state.destinationLocation!.localizedName(state.language)
        : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.46,
      minChildSize: 0.28,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.28, 0.46, 0.88],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28.0),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                blurRadius: 20.0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Górny uchwyt i nagłówek "Wyniki wyszukiwania"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pasek przeciągania
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kColorGrayScheme.tertiary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Etykieta "Wyniki wyszukiwania"
                      Text(
                        isPL
                            ? 'Wyniki wyszukiwania'
                            : (isUK ? 'Результати пошуку' : 'Search results'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Wiersz: Ikona trasy + Nazwa trasy + Filtry + Ołówek edycji
                      Row(
                        children: [
                          Icon(
                            Icons.alt_route,
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$startName ➔ $destName',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.tune,
                              size: 22,
                              color: theme.colorScheme.onSurface,
                            ),
                            tooltip: isPL
                                ? 'Filtry dostępności'
                                : (isUK
                                      ? 'Фільтри доступності'
                                      : 'Accessibility filters'),
                            onPressed: () =>
                                showAccessibilityFiltersModal(context),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 22,
                              color: theme.colorScheme.onSurface,
                            ),
                            tooltip: isPL
                                ? 'Edytuj wyszukiwanie'
                                : (isUK ? 'Редагувати пошук' : 'Edit search'),
                            onPressed: () {
                              state.clearRoutes();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lista kafelków tras (Nowy design ze zdjęcia)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final route = routes[index];
                    final isSelected = index == state.selectedRouteIndex;
                    return _buildRouteCardItem(
                      context: context,
                      theme: theme,
                      state: state,
                      route: route,
                      index: index,
                      isSelected: isSelected,
                      isPL: isPL,
                      isUK: isUK,
                    );
                  }, childCount: routes.length),
                ),
              ),

              // Dolny przycisk nawigacji na żywo ze starego designu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => state.startNavigation(),
                      icon: Icon(
                        activeRoute.isTransit
                            ? (activeRoute
                                          .transitInfo
                                          ?.transitLeg
                                          .vehicleType ==
                                      TransitVehicleType.tram
                                  ? Icons.tram
                                  : Icons.directions_bus)
                            : Icons.navigation,
                        size: 20,
                      ),
                      label: Text(
                        activeRoute.isTransit
                            ? (isPL
                                  ? 'Rozpocznij trasę (${activeRoute.transitInfo?.transitLeg.lineName ?? "MPK"})'
                                  : (isUK
                                        ? 'Розпочати маршрут (${activeRoute.transitInfo?.transitLeg.lineName ?? "MPK"})'
                                        : 'Start route (${activeRoute.transitInfo?.transitLeg.lineName ?? "MPK"})'))
                            : (isPL
                                  ? 'Rozpocznij trasę (${activeRoute.durationMinutes} min)'
                                  : (isUK
                                        ? 'Розпочати маршрут (${activeRoute.durationMinutes} хв)'
                                        : 'Start navigation (${activeRoute.durationMinutes} min)')),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pojedynczy kafelek trasy odwzorowany z nowego designu ze zdjęcia
  Widget _buildRouteCardItem({
    required BuildContext context,
    required ThemeData theme,
    required AppState state,
    required RouteModel route,
    required int index,
    required bool isSelected,
    required bool isPL,
    required bool isUK,
  }) {
    final isTransit = route.isTransit;
    final isAccessible = route.type == RouteType.accessible;
    final transitLeg = route.transitInfo?.transitLeg;
    final isTram = transitLeg?.vehicleType == TransitVehicleType.tram;

    // Tytuł i ikona w zależności od rodzaju trasy
    final String title;
    final IconData mainIcon;
    if (isTransit) {
      title = isTram
          ? (isPL ? 'Tramwaj' : (isUK ? 'Трамвай' : 'Tram'))
          : (isPL ? 'Autobus' : (isUK ? 'Автобус' : 'Bus'));
      mainIcon = isTram ? Icons.tram : Icons.directions_bus;
    } else if (isAccessible) {
      title = isPL
          ? 'Trasa bez barier'
          : (isUK ? 'Маршрут без бар\'єрів' : 'Step-free route');
      mainIcon = Icons.accessibility_new;
    } else {
      title = isPL
          ? 'Trasa standardowa'
          : (isUK ? 'Стандартний маршрут' : 'Standard route');
      mainIcon = Icons.directions_walk;
    }

    // Czas odjazdu dla komunikacji
    String departureTime = '20:23';
    if (transitLeg != null && transitLeg.nextDeparturesFormatted.isNotEmpty) {
      departureTime = transitLeg.nextDeparturesFormatted.first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : kColorGrayScheme.primary,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.4),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => state.selectRoute(index),
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Duża ikona po lewej stronie
                    Icon(
                      mainIcon,
                      size: 36,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 14),

                    // Kolumna środkowa: Tytuł z linią obok oraz Czas i dystans
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isTransit && transitLeg != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: kColorGrayScheme.tertiary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  child: Text(
                                    isPL
                                        ? 'Linia ${transitLeg.lineName}'
                                        : (isUK
                                              ? 'Лінія ${transitLeg.lineName}'
                                              : 'Line ${transitLeg.lineName}'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${route.durationMinutes} ${isPL ? 'min' : (isUK ? 'хв' : 'min')} • ${route.getDistanceString()}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Prawa strona kafelka: Odjazd z godziną dla komunikacji (brak 3 kropek dla pieszych)
                    if (isTransit)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPL
                                ? 'Odjazd'
                                : (isUK ? 'Відправлення' : 'Departure'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                          Text(
                            departureTime,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Dostępność i parametry pojawiające się pod wybraną opcją
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  _buildSelectedRouteDetails(
                    context: context,
                    theme: theme,
                    state: state,
                    route: route,
                    isPL: isPL,
                    isUK: isUK,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Szczegółowe metryki i analiza wybranej trasy przeniesione ze starego RouteCard
  Widget _buildSelectedRouteDetails({
    required BuildContext context,
    required ThemeData theme,
    required AppState state,
    required RouteModel route,
    required bool isPL,
    required bool isUK,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Wskaźniki dostępności i schodów
          Row(
            children: [
              Icon(
                route.accessibilityScore >= 80
                    ? Icons.verified
                    : Icons.info_outline,
                size: 18,
                color: route.accessibilityScore >= 80
                    ? theme.colorScheme.primary
                    : theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPL
                      ? 'Dostępność: ${route.accessibilityScore}/100'
                      : (isUK
                            ? 'Доступність: ${route.accessibilityScore}/100'
                            : 'Accessibility: ${route.accessibilityScore}/100'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kColorGrayScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  route.stairsAvoided > 0
                      ? (isPL
                            ? 'ominięto ${route.stairsAvoided} st.'
                            : (isUK
                                  ? 'оминуто ${route.stairsAvoided} сх.'
                                  : 'avoided ${route.stairsAvoided} st.'))
                      : (route.stairsCount > 0
                            ? '${route.stairsCount} ${isPL ? "st. schodów" : (isUK ? "сх. сходів" : "stairs")}'
                            : (isPL
                                  ? '0 schodów'
                                  : (isUK ? '0 сходів' : '0 stairs'))),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: route.stairsAvoided > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          // 2. Opis nawierzchni
          if (route.surfaceSummaryPl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.texture,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${isPL ? "Nawierzchnia" : (isUK ? "Покриття" : "Surface")}: ${isPL ? route.surfaceSummaryPl : route.surfaceSummaryEn}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 3. Informacja o barierach i obejściu AI
          if (route.bypassReasonPl != null &&
              route.bypassReasonPl!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPL
                        ? route.bypassReasonPl!
                        : (route.bypassReasonEn ?? route.bypassReasonPl!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 4. Szczegóły przystanków GTFS
          if (route.isTransit && route.transitInfo != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.near_me_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${route.transitInfo!.transitLeg.departureStop.name} ➔ ${route.transitInfo!.transitLeg.arrivalStop.name} (${route.transitInfo!.transitLeg.intermediateStops.length} ${isPL ? "przyst." : (isUK ? "зуп." : "stops")})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 5. Przycisk Audytu Street View AI
          if (route.audits.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () => state.openAudit(route.audits.first),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: Icon(
                  Icons.streetview,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  isPL
                      ? 'Zobacz audyt Street View AI 📸'
                      : (isUK
                            ? 'Переглянути аудит Street View AI 📸'
                            : 'View Street View AI Audit 📸'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
