import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/transit_route_info.dart';
import '../providers/app_state.dart';
import '../services/krakow_locations.dart';
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
              // Nowy nagłówek ze zdjęcia:
              // 1. Wiersz: [Lupa] Wyniki wyszukiwania     [Filtry] [X]
              // 2. Punkty: [Pin] Start
              //            [Pionowa linia kropkowana]
              //            [Kółko] Meta
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wiersz 1: Lupa + Wyniki wyszukiwania + Filtry + Zamknij
                      Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPL
                                ? 'Wyniki wyszukiwania'
                                : (isUK ? 'Результати пошуку' : 'Search results'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
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
                          const SizedBox(width: 10),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.close,
                              size: 24,
                              color: theme.colorScheme.onSurface,
                            ),
                            tooltip: isPL
                                ? 'Zamknij trasę'
                                : (isUK ? 'Закрити маршрут' : 'Close route'),
                            onPressed: () {
                              state.clearRoutes();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Wiersz 2: Punkt początkowy (Pin + nazwa) - klikalny do edycji
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openLocationEditor(
                            context,
                            state,
                            isDestination: false,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 28,
                                  child: Center(
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 24,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    startName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Łącznik: Drobna pionowa kropkowana linia
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: SizedBox(
                          width: 24,
                          height: 14,
                          child: Center(
                            child: CustomPaint(
                              size: const Size(3, 14),
                              painter: _DottedLinePainter(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Wiersz 3: Punkt docelowy (Kółko + nazwa) - klikalny do edycji
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openLocationEditor(
                            context,
                            state,
                            isDestination: true,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 2,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 28,
                                  child: Center(
                                    child: Container(
                                      width: 17,
                                      height: 17,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface,
                                          width: 2.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    destName.isNotEmpty
                                        ? destName
                                        : (isPL
                                              ? 'Cel podróży'
                                              : (isUK
                                                    ? 'Пункт призначення'
                                                    : 'Destination')),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.35,
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
                      onPressed: state.selectedRouteIndex >= 0
                          ? () => state.startNavigation()
                          : null,
                      icon: const Icon(
                        Icons.navigation,
                        size: 20,
                      ),
                      label: Text(
                        isPL
                            ? 'Rozpocznij trasę'
                            : (isUK ? 'Розпочати маршрут' : 'Start route'),
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

  void _openLocationEditor(
    BuildContext context,
    AppState state, {
    required bool isDestination,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationSearchModal(
        isDestination: isDestination,
      ),
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
    final isStandard = route.type == RouteType.standard || (!isTransit && !isAccessible);
    final selectionColor = isStandard ? const Color(0xFFDC2626) : theme.colorScheme.primary;
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

    // Czas odjazdu dla komunikacji (< 15 min: za X min, >= 15 min: godzina)
    String departureTime = '20:23';
    if (transitLeg != null) {
      if (transitLeg.departureMinutesAway < 15) {
        departureTime = isPL
            ? 'za ${transitLeg.departureMinutesAway} min'
            : (isUK
                ? 'через ${transitLeg.departureMinutesAway} хв'
                : 'in ${transitLeg.departureMinutesAway} min');
      } else {
        if (transitLeg.nextDeparturesFormatted.isNotEmpty) {
          departureTime =
              transitLeg.nextDeparturesFormatted.first.split(' ').first;
        } else {
          final depTime = DateTime.now().add(
            Duration(minutes: transitLeg.departureMinutesAway),
          );
          departureTime =
              '${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isSelected
            ? (isStandard
                ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.45))
            : kColorGrayScheme.primary,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isSelected
              ? selectionColor
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
                          ? selectionColor
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
                              Flexible(
                                child: Text(
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isTransit && transitLeg != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
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
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
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
                              fontSize: (transitLeg?.departureMinutesAway ?? 99) < 15
                                  ? 15
                                  : 18,
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
    final isStandard = route.type == RouteType.standard ||
        (!route.isTransit && route.type != RouteType.accessible);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isStandard
              ? const Color(0xFFDC2626).withValues(alpha: 0.35)
              : theme.colorScheme.outline.withValues(alpha: 0.4),
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
                isStandard
                    ? Icons.warning_amber_rounded
                    : (route.accessibilityScore >= 80
                        ? Icons.verified
                        : Icons.info_outline),
                size: 18,
                color: isStandard
                    ? const Color(0xFFDC2626)
                    : (route.accessibilityScore >= 80
                        ? theme.colorScheme.primary
                        : theme.colorScheme.tertiary),
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
              // Pokaż informację o schodach tylko wtedy, gdy schody występują lub zostały ominięte (nie pokazuj gdy 0 schodów)
              if (route.stairsAvoided > 0 || route.stairsCount > 0)
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
                        : '${route.stairsCount} ${isPL ? "st. schodów" : (isUK ? "сх. сходів" : "stairs")}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: route.stairsAvoided > 0
                          ? theme.colorScheme.primary
                          : const Color(0xFFDC2626),
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

/// Drobny pionowy kropkowany separator łączący punkt startowy z docelowym
class _DottedLinePainter extends CustomPainter {
  final Color color;
  const _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const dotRadius = 1.3;
    const count = 3;
    final spacing = (size.height - (count * dotRadius * 2)) / (count - 1);

    for (int i = 0; i < count; i++) {
      final cy = dotRadius + i * (dotRadius * 2 + spacing);
      canvas.drawCircle(Offset(size.width / 2, cy), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Modal do zmiany/edycji punktu startowego lub docelowego trasy
class _LocationSearchModal extends StatefulWidget {
  final bool isDestination;

  const _LocationSearchModal({required this.isDestination});

  @override
  State<_LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<_LocationSearchModal> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final initialName = widget.isDestination
        ? (state.destinationLocation != null
            ? state.destinationLocation!.localizedName(state.language)
            : '')
        : state.startLocation.localizedName(state.language);

    _controller = TextEditingController(text: initialName);
    _focusNode = FocusNode();
    _query = initialName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectLocation(
    BuildContext context,
    AppState state, {
    KrakowLocation? loc,
    String? customName,
  }) {
    KrakowLocation targetLoc;
    if (loc != null) {
      targetLoc = loc;
    } else {
      final name = customName?.trim() ?? '';
      if (name.isEmpty) return;
      final matches = KrakowLocationsDatabase.search(name);
      if (matches.isNotEmpty) {
        targetLoc = matches.first;
      } else {
        targetLoc = KrakowLocation(
          id: 'loc_custom_${DateTime.now().millisecondsSinceEpoch}',
          namePl: name,
          nameEn: name,
          address: 'Kraków, $name',
          point: widget.isDestination
              ? const LatLng(50.0617, 19.9373)
              : const LatLng(50.0647, 19.9450),
          category: 'custom',
        );
      }
    }

    if (widget.isDestination) {
      state.setDestinationLocation(targetLoc, calculateRoute: false);
    } else {
      state.setStartLocation(targetLoc, calculateRoute: false);
    }

    Navigator.pop(context);
    state.planRouteBetweenSelectedPoints(showLoader: true);
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'transport':
        return Icons.train_outlined;
      case 'historic':
        return Icons.account_balance_outlined;
      case 'culture':
        return Icons.theater_comedy_outlined;
      case 'park':
        return Icons.park_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'building':
        return Icons.apartment_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final isUK = state.language == 'uk';

    final modalTitle = widget.isDestination
        ? (isPL
            ? 'Zmień cel trasy'
            : (isUK ? 'Змінити пункт призначення' : 'Change destination'))
        : (isPL
            ? 'Zmień punkt startowy'
            : (isUK ? 'Змінити punkt відправлення' : 'Change start point'));

    final searchHint = isPL
        ? 'Wpisz nazwę miejsca lub adres...'
        : (isUK ? 'Введіть назву місця або адресу...' : 'Enter place name or address...');

    final trimmed = _query.trim();
    final suggestions = trimmed.isEmpty
        ? KrakowLocationsDatabase.locations
        : KrakowLocationsDatabase.search(trimmed);

    final showExactCustomOption = trimmed.isNotEmpty &&
        !suggestions.any((loc) =>
            loc.namePl.toLowerCase() == trimmed.toLowerCase() ||
            loc.localizedName(state.language).toLowerCase() ==
                trimmed.toLowerCase());

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Uchwyt przeciągania
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
            const SizedBox(height: 14),

            // Tytuł i Zamknij
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    widget.isDestination
                        ? Icons.circle_outlined
                        : Icons.location_on_outlined,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      modalTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Pole wyszukiwania
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: kColorGrayScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) => setState(() => _query = val),
                  onSubmitted: (val) => _selectLocation(
                    context,
                    state,
                    customName: val,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Opcja "Moja lokalizacja" dla punktu startowego
            if (!widget.isDestination)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.my_location,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    isPL
                        ? 'Moja lokalizacja'
                        : (isUK ? 'Моя локація' : 'My location'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isPL
                        ? 'Użyj bieżącej pozycji GPS'
                        : (isUK
                            ? 'Використовувати поточну позицію GPS'
                            : 'Use current GPS location'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () {
                    state.useCurrentLocationAsStart(calculateRoute: false);
                    Navigator.pop(context);
                    state.planRouteBetweenSelectedPoints(showLoader: true);
                  },
                ),
              ),

            // Lista podpowiedzi
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  if (showExactCustomOption)
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        Icons.pin_drop_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(
                        '${isPL ? "Wybierz" : (isUK ? "Вибрати" : "Select")}: "$trimmed"',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _selectLocation(
                        context,
                        state,
                        customName: trimmed,
                      ),
                    ),
                  ...suggestions.map(
                    (loc) => ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        _categoryIcon(loc.category),
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      title: Text(
                        loc.localizedName(state.language),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        loc.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      onTap: () => _selectLocation(
                        context,
                        state,
                        loc: loc,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

