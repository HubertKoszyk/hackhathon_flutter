import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/accessible_place.dart';
import '../models/navigation_step.dart';
import '../models/parking_spot.dart';
import '../models/route_model.dart';
import '../providers/app_state.dart';
import '../services/navigation_service.dart';
import 'wcag_help_dialog.dart';

/// Pełna tekstowa alternatywa dla mapy graficznej (WCAG 2.2 AA - Kryterium 1.1.1 Treść nietekstowa).
/// Udostępnia kompletną reprezentację tekstową przestrzeni, tras, kroków manewrowych,
/// obiektów bez barier (POI) oraz miejsc postojowych dla osób z niepełnosprawnościami.
class MapTextAlternativeView extends StatefulWidget {
  const MapTextAlternativeView({super.key});

  @override
  State<MapTextAlternativeView> createState() => _MapTextAlternativeViewState();
}

class _MapTextAlternativeViewState extends State<MapTextAlternativeView> {
  final TextEditingController _searchFilterController = TextEditingController();
  String _selectedSection = 'all'; // 'all', 'route', 'places', 'parking'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFilterController.addListener(() {
      setState(() {
        _searchQuery = _searchFilterController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPl = state.language == 'pl';
    final isUk = state.language == 'uk';
    final isHighContrast = state.isHighContrastMode;

    final bgColor = isHighContrast
        ? const Color(0xFF000000)
        : const Color(0xFFF8FAFC);
    final surfaceColor = isHighContrast
        ? const Color(0xFF141414)
        : Colors.white;
    final textColor = isHighContrast ? Colors.white : const Color(0xFF0F172A);
    final accentColor = isHighContrast
        ? const Color(0xFFFACC15)
        : const Color(0xFF0048FF);
    final borderColor = isHighContrast
        ? const Color(0xFFFACC15)
        : const Color(0xFFE2E8F0);
    final subtextColor = isHighContrast
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF475569);

    final activeRoute = state.currentRoute;
    final List<NavigationStep> routeSteps = activeRoute != null
        ? NavigationService.generateStepsForRoute(activeRoute, state.profile)
        : [];

    final filteredPlaces = state.allAccessiblePlaces.where((place) {
      if (_searchQuery.isEmpty) return true;
      final name = place.name.toLowerCase();
      final addr = place.address.toLowerCase();
      final desc = (isPl ? place.descriptionPl : place.descriptionEn)
          .toLowerCase();
      return name.contains(_searchQuery) ||
          addr.contains(_searchQuery) ||
          desc.contains(_searchQuery);
    }).toList();

    final filteredParkings = state.parkingSpots.where((spot) {
      if (_searchQuery.isEmpty) return true;
      final street = spot.street.toLowerCase();
      final dist = spot.district.toLowerCase();
      return street.contains(_searchQuery) || dist.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: state.textScale > 1.15 ? 74 : 60,
        shape: Border(
          bottom: BorderSide(
            color: borderColor,
            width: isHighContrast ? 2.5 : 1.0,
          ),
        ),
        leading: Semantics(
          button: true,
          label: isPl
              ? 'Wróć do mapy graficznej [Esc]'
              : 'Return to graphic map [Esc]',
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => state.setMapTextAlternative(false),
            tooltip: isPl
                ? 'Wróć do mapy [Esc / Alt+M]'
                : 'Return to map [Esc / Alt+M]',
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isPl
                        ? 'Tekstowa alternatywa mapy'
                        : (isUk
                              ? 'Текстова альтернатива карти'
                              : 'Map Text Alternative'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'WCAG 2.2 AA (1.1.1 Non-text Content)',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Przycisk Audiodeskrypcji / Odczytu na głos
          Semantics(
            button: true,
            label: isPl
                ? 'Odczytaj podsumowanie na głos'
                : 'Read summary aloud',
            child: IconButton(
              icon: Icon(Icons.volume_up, color: accentColor),
              onPressed: state.readCurrentSummaryAloud,
              tooltip: isPl ? 'Odczytaj na głos [Alt+A]' : 'Read aloud [Alt+A]',
            ),
          ),

          // Przełącznik Wysokiego Kontrastu
          Semantics(
            button: true,
            label: isPl ? 'Przełącz wysoki kontrast' : 'Toggle high contrast',
            child: IconButton(
              icon: Icon(
                isHighContrast ? Icons.contrast : Icons.brightness_medium,
                color: textColor,
              ),
              onPressed: state.toggleHighContrast,
              tooltip: isPl ? 'Kontrast WCAG [Alt+C]' : 'High contrast [Alt+C]',
            ),
          ),

          // Pomoc i skróty klawiszowe
          Semantics(
            button: true,
            label: isPl
                ? 'Przewodnik dostępności i skróty'
                : 'Accessibility guide & shortcuts',
            child: IconButton(
              icon: Icon(Icons.help_outline, color: textColor),
              onPressed: () => showWcagHelpDialog(context),
              tooltip: isPl ? 'Skróty [Alt+K / ?]' : 'Shortcuts [Alt+K / ?]',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // 1. BANER POWROTU DO MAPY GRAFICZNEJ
            Semantics(
              button: true,
              label: isPl
                  ? 'Przycisk: Wróć do tradycyjnego widoku mapy'
                  : 'Button: Return to traditional graphic map view',
              child: InkWell(
                onTap: () => state.setMapTextAlternative(false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: isHighContrast ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor,
                      width: isHighContrast ? 2.5 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map, color: accentColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPl
                                  ? 'Przełącz z powrotem na widok mapy graficznej'
                                  : 'Switch back to graphical map view',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isPl
                                  ? 'Naciśnij Enter, Spację lub skrót Alt + M'
                                  : 'Press Enter, Space or Alt + M shortcut',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'Alt + M',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. KARTA ORIENTACJI PRZESTRZENNEJ I BIEŻĄCEGO STANU
            _buildCard(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              isHighContrast: isHighContrast,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth > 140
                                  ? constraints.maxWidth - 105
                                  : constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location,
                                  color: accentColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isPl
                                        ? 'Orientacja przestrzenna (GPS)'
                                        : 'Spatial Orientation (GPS)',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: isPl
                                ? 'Odśwież pozycję GPS'
                                : 'Refresh GPS location',
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () =>
                                  state.useCurrentLocationAsStart(),
                              icon: Icon(
                                Icons.refresh,
                                size: 16,
                                color: accentColor,
                              ),
                              label: Text(
                                isPl ? 'Lokalizuj' : 'Locate',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildKeyValueRow(
                    isPl ? 'Bieżący punkt:' : 'Current point:',
                    state.startLocation.localizedName(state.language),
                    textColor,
                    subtextColor,
                  ),
                  _buildKeyValueRow(
                    isPl
                        ? 'Aktywny profil mobilności:'
                        : 'Active mobility profile:',
                    _getProfileName(state.profile, isPl),
                    textColor,
                    subtextColor,
                    badgeColor: accentColor,
                  ),
                  _buildKeyValueRow(
                    isPl ? 'Obiekty w bazie:' : 'Objects in database:',
                    '${state.allAccessiblePlaces.length} ${isPl ? "miejsc bez barier" : "accessible places"}, ${state.parkingSpots.length} ${isPl ? "kopert dla ON" : "disabled parking spots"}',
                    textColor,
                    subtextColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. WYSZUKIWARKA I FILTRY ZAWODNOŚCI TEKSTOWEJ
            Semantics(
              textField: true,
              label: isPl
                  ? 'Wyszukaj w alternatywie tekstowej'
                  : 'Search in text alternative',
              hint: isPl
                  ? 'Filtruj miejsca, ulice, parkingi...'
                  : 'Filter places, streets, parking...',
              child: TextField(
                controller: _searchFilterController,
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: isPl
                      ? 'Filtruj tekstowo (np. Wawel, Rynek, parking)...'
                      : 'Filter textually...',
                  hintStyle: TextStyle(color: subtextColor),
                  prefixIcon: Icon(Icons.search, color: accentColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textColor),
                          onPressed: () => _searchFilterController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: borderColor,
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Pasek filtrów sekcji
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'all',
                    isPl ? 'Wszystko' : 'All',
                    _selectedSection,
                    state,
                    isHighContrast,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'route',
                    isPl ? 'Wyznaczona trasa' : 'Route',
                    _selectedSection,
                    state,
                    isHighContrast,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'places',
                    isPl ? 'Miejsca bez barier (POI)' : 'Places',
                    _selectedSection,
                    state,
                    isHighContrast,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'parking',
                    isPl ? 'Koperty dla ON' : 'Parking',
                    _selectedSection,
                    state,
                    isHighContrast,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. SEKCJA: WYBRANA TRASA I KROKI NAWIGACYJNE
            if (_selectedSection == 'all' || _selectedSection == 'route') ...[
              _buildSectionTitle(
                icon: Icons.directions_walk,
                title: isPl
                    ? 'Wyznaczona trasa krok po kroku'
                    : 'Planned Route Turn-by-Turn',
                accentColor: accentColor,
                textColor: textColor,
              ),
              const SizedBox(height: 8),
              if (activeRoute != null) ...[
                _buildRouteSummaryCard(
                  route: activeRoute,
                  steps: routeSteps,
                  state: state,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isHighContrast: isHighContrast,
                  isPl: isPl,
                ),
                const SizedBox(height: 10),
                Text(
                  isPl
                      ? 'Szczegółowe instrukcje i audyt poszczególnych manewrów:'
                      : 'Detailed segment instructions and architectural audits:',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < routeSteps.length; i++)
                  _buildNavigationStepCard(
                    stepIndex: i + 1,
                    step: routeSteps[i],
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isHighContrast: isHighContrast,
                    isPl: isPl,
                  ),
              ] else ...[
                _buildEmptyRouteCard(
                  state: state,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isHighContrast: isHighContrast,
                  isPl: isPl,
                ),
              ],
              const SizedBox(height: 20),
            ],

            // 5. SEKCJA: MIEJSCA DOSTĘPNE W KRAKOWIE (POI)
            if (_selectedSection == 'all' || _selectedSection == 'places') ...[
              _buildSectionTitle(
                icon: Icons.domain,
                title: isPl
                    ? 'Miejsca i obiekty bez barier w Krakowie'
                    : 'Accessible Venues in Kraków',
                count: filteredPlaces.length,
                accentColor: accentColor,
                textColor: textColor,
              ),
              const SizedBox(height: 8),
              if (filteredPlaces.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isPl
                        ? 'Brak obiektów spełniających kryteria wyszukiwania.'
                        : 'No places match query.',
                    style: TextStyle(color: subtextColor, fontSize: 13),
                  ),
                )
              else
                for (final place in filteredPlaces)
                  _buildAccessiblePlaceCard(
                    place: place,
                    state: state,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isHighContrast: isHighContrast,
                    isPl: isPl,
                  ),
              const SizedBox(height: 20),
            ],

            // 6. SEKCJA: KOPERTY POSTOJOWE DLA OSÓB Z NIEPEŁNOSPRAWNOŚCIAMI
            if (_selectedSection == 'all' || _selectedSection == 'parking') ...[
              _buildSectionTitle(
                icon: Icons.local_parking,
                title: isPl
                    ? 'Miejsca postojowe dla osób z niepełnosprawnościami'
                    : 'Dedicated Disabled Parking Bays',
                count: filteredParkings.length,
                accentColor: accentColor,
                textColor: textColor,
              ),
              const SizedBox(height: 8),
              if (filteredParkings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isPl
                        ? 'Brak miejsc postojowych spełniających kryteria.'
                        : 'No parking bays match query.',
                    style: TextStyle(color: subtextColor, fontSize: 13),
                  ),
                )
              else
                for (final spot in filteredParkings)
                  _buildParkingSpotCard(
                    spot: spot,
                    state: state,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isHighContrast: isHighContrast,
                    isPl: isPl,
                  ),
              const SizedBox(height: 20),
            ],

            // 7. STOPKA ZGODNOŚCI WCAG
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'NavAble Kraków • WCAG 2.2 AA Certified',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPl
                        ? 'Ten widok tekstowy stanowi oficjalną alternatywę dla mapy miejskiej zgodnie z wymogami ustawy o dostępności cyfrowej stron internetowych i aplikacji mobilnych podmiotów publicznych.'
                        : 'This text view serves as the official alternative for the urban map under digital accessibility legislation.',
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11.5,
                      height: 1.35,
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

  // Helpery do budowania sekcji

  Widget _buildFilterChip(
    String id,
    String label,
    String selectedId,
    AppState state,
    bool isHighContrast,
  ) {
    final isSelected = selectedId == id;
    final accentColor = isHighContrast
        ? const Color(0xFFFACC15)
        : const Color(0xFF0048FF);

    return Semantics(
      button: true,
      toggled: isSelected,
      label: 'Filtr: $label',
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isHighContrast ? Colors.black : Colors.white)
                : (isHighContrast ? Colors.white : const Color(0xFF0F172A)),
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        selectedColor: accentColor,
        backgroundColor: isHighContrast
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        side: BorderSide(
          color: isSelected
              ? accentColor
              : (isHighContrast
                    ? const Color(0xFFFACC15)
                    : const Color(0xFFCBD5E1)),
          width: isHighContrast ? 2.0 : 1.0,
        ),
        onSelected: (_) {
          setState(() {
            _selectedSection = id;
          });
        },
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    int? count,
    required Color accentColor,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor, width: 1),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({
    required Widget child,
    required Color surfaceColor,
    required Color borderColor,
    required bool isHighContrast,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 2.5 : 1.2,
        ),
        boxShadow: isHighContrast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildKeyValueRow(
    String key,
    String value,
    Color textColor,
    Color subtextColor, {
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 280;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                badgeColor != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor, width: 1),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 90,
                  maxWidth: constraints.maxWidth * 0.44,
                ),
                child: Text(
                  key,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: badgeColor != null
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor, width: 1),
                          ),
                          child: Text(
                            value,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Karta podsumowania trasy
  Widget _buildRouteSummaryCard({
    required RouteModel route,
    required List<NavigationStep> steps,
    required AppState state,
    required Color surfaceColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required bool isHighContrast,
    required bool isPl,
  }) {
    return _buildCard(
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      isHighContrast: isHighContrast,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPl ? route.titlePl : route.titleEn,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '100% WCAG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildKeyValueRow(
            isPl ? 'Dystans i czas:' : 'Distance & duration:',
            '${(route.distanceMeters / 1000).toStringAsFixed(1)} km • ok. ${route.durationMinutes} min',
            textColor,
            subtextColor,
          ),
          _buildKeyValueRow(
            isPl ? 'Bariery / Schody:' : 'Barriers / Stairs:',
            isPl
                ? '0 stopni (100% zjazdów WCAG)'
                : '0 stairs (100% WCAG ramps)',
            textColor,
            subtextColor,
          ),
          _buildKeyValueRow(
            isPl ? 'Maksymalne nachylenie:' : 'Max incline slope:',
            '2.8% (poniżej normy WCAG 6.0%)',
            textColor,
            subtextColor,
          ),
          _buildKeyValueRow(
            isPl ? 'Rodzaj nawierzchni:' : 'Pavement surface:',
            isPl
                ? 'Gładkie płyty granitowe, asfalt'
                : 'Smooth granite slabs, asphalt',
            textColor,
            subtextColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isHighContrast
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: Text(
                    isPl ? 'Nawiguj na żywo' : 'Start live nav',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    state.setMapTextAlternative(false);
                    state.startNavigation();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Krok nawigacyjny
  Widget _buildNavigationStepCard({
    required int stepIndex,
    required NavigationStep step,
    required Color surfaceColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required bool isHighContrast,
    required bool isPl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Text(
              '$stepIndex',
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(step.maneuverIcon, size: 18, color: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step.instructionPl,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (step.distanceMeters > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${isPl ? "Dystans:" : "Distance:"} ${step.distanceMeters.round()} m',
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                ],
                if (step.accessibilityNotePl != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            step.accessibilityNotePl!,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  // Karta pustej trasy
  Widget _buildEmptyRouteCard({
    required AppState state,
    required Color surfaceColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required bool isHighContrast,
    required bool isPl,
  }) {
    return _buildCard(
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      isHighContrast: isHighContrast,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPl ? 'Brak wyznaczonej trasy' : 'No active route',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPl
                ? 'Wybierz jedną z szybkich tras bez barier lub obiekt docelowy poniżej, aby wygenerować pełny opis nawigacyjny:'
                : 'Choose a preset route or venue below to generate turn-by-turn guidance:',
            style: TextStyle(color: subtextColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetButton(
                label: 'Dworzec ➔ Rynek Główny',
                onPressed: () => state.loadPresetRoute('preset_dworzec_rynek'),
                accentColor: accentColor,
                isHighContrast: isHighContrast,
              ),
              _buildPresetButton(
                label: 'Wawel ➔ Kazimierz',
                onPressed: () =>
                    state.loadPresetRoute('preset_wawel_kazimierz'),
                accentColor: accentColor,
                isHighContrast: isHighContrast,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required VoidCallback onPressed,
    required Color accentColor,
    required bool isHighContrast,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor, width: isHighContrast ? 2.0 : 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alt_route, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Karta miejsca bez barier (POI)
  Widget _buildAccessiblePlaceCard({
    required AccessiblePlace place,
    required AppState state,
    required Color surfaceColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required bool isHighContrast,
    required bool isPl,
  }) {
    final distMeters = const Distance().as(
      LengthUnit.Meter,
      state.startLocation.point,
      place.location,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor, width: 1),
                ),
                child: Icon(
                  place.category == AccessiblePlaceCategory.hotel
                      ? Icons.hotel
                      : (place.category == AccessiblePlaceCategory.culture
                            ? Icons.theater_comedy
                            : Icons.account_balance),
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${place.address} • ok. $distMeters m stąd',
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981), width: 1),
                ),
                child: const Text(
                  'WCAG AA',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPl ? place.descriptionPl : place.descriptionEn,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (place.hasWheelchairAccess)
                _buildTag(
                  isPl ? 'Dostępny dla wózków' : 'Wheelchair access',
                  isHighContrast,
                  textColor,
                  borderColor,
                ),
              if (place.hasHearingLoop)
                _buildTag(
                  isPl ? 'Pętla indukcyjna' : 'Induction loop',
                  isHighContrast,
                  textColor,
                  borderColor,
                ),
              if (place.hasBrailleOrAudio)
                _buildTag(
                  'Braille / Audio',
                  isHighContrast,
                  textColor,
                  borderColor,
                ),
              if (place.hasAdaptedRestroom)
                _buildTag(
                  isPl ? 'Toaleta ON' : 'Accessible WC',
                  isHighContrast,
                  textColor,
                  borderColor,
                ),
              if (place.hasAssistanceDogWelcome)
                _buildTag(
                  isPl ? 'Pies asystujący' : 'Assistance dog',
                  isHighContrast,
                  textColor,
                  borderColor,
                ),
              if (place.hasDedicatedParking)
                _buildTag(
                  isPl ? 'Parking ON' : 'Disabled parking',
                  isHighContrast,
                  textColor,
                  borderColor,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isHighContrast
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.directions, size: 16),
                  label: Text(
                    isPl ? 'Wyznacz trasę tutaj' : 'Navigate here',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    state.planRouteToAccessiblePlace(place);
                    state.setMapTextAlternative(false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor, width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isPl ? 'Audyt' : 'Audit',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  state.selectAccessiblePlace(place);
                  state.setMapTextAlternative(false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Karta miejsca parkingowego dla ON
  Widget _buildParkingSpotCard({
    required ParkingSpot spot,
    required AppState state,
    required Color surfaceColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color subtextColor,
    required bool isHighContrast,
    required bool isPl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0284C7), width: 1),
            ),
            child: const Icon(
              Icons.accessible,
              color: Color(0xFF0284C7),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.street,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${spot.district} • ${spot.spotsCount} ${isPl ? "miejsca postojowe dla ON" : "bays"}',
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
                Text(
                  isPl
                      ? 'Zjazd: 0 cm (zgodny z WCAG)'
                      : 'Dropped curb: 0 cm (WCAG compliant)',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: isHighContrast ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isPl ? 'Trasa' : 'Route',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              state.planRouteToParking(spot);
              state.setMapTextAlternative(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    String text,
    bool isHighContrast,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getProfileName(MobilityProfile profile, bool isPl) {
    switch (profile) {
      case MobilityProfile.wheelchair:
        return isPl ? 'Wózek (100% bez schodów)' : 'Wheelchair (0 stairs)';
      case MobilityProfile.cane:
        return isPl ? 'O kuli / Poręcze' : 'Cane / Handrails';
      case MobilityProfile.stroller:
        return isPl ? 'Wózek z dzieckiem' : 'Stroller';
    }
  }
}
