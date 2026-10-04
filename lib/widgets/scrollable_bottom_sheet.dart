import 'package:flutter/material.dart';
import 'package:hackhathon_flutter/theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/accessible_place.dart';
import '../models/parking_spot.dart';
import '../providers/app_state.dart';
import '../services/krakow_locations.dart';
import 'filters_modal.dart';

class CustomStickySheet extends StatefulWidget {
  const CustomStickySheet({super.key});

  @override
  State<CustomStickySheet> createState() => _CustomStickySheetState();
}

class _CustomStickySheetState extends State<CustomStickySheet> {
  static const double _initialSize = 0.48;
  static const double _minSize = 0.30;
  static const double _maxSize = 0.92;

  // Wysokość kafelka wyszukiwarki oraz ile pikseli wystaje ponad krawędź sheeta
  static const double _baseCardHeight = 248.0;
  static const double _suggestionsBoxHeight = 156.0;
  static const double _overlap = 48.0;
  static const double _bottomSpacing = 16.0;

  late final DraggableScrollableController _sheetController;
  late final TextEditingController _startController;
  late final TextEditingController _destinationController;
  late final FocusNode _startFocusNode;
  late final FocusNode _destinationFocusNode;

  String? _syncedStartId;
  String? _syncedDestinationId;
  bool _hasTriggeredSearch = false;
  String _placeTabFilter = 'all'; // 'all', 'hotel', 'building', 'parking'

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _startController = TextEditingController();
    _destinationController = TextEditingController();
    _startFocusNode = FocusNode();
    _destinationFocusNode = FocusNode();

    _startController.addListener(_onTextChanged);
    _destinationController.addListener(_onTextChanged);
    _startFocusNode.addListener(_onFocusChanged);
    _destinationFocusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<AppState>();
        if (state.userCurrentGpsPoint == null && !state.isLocatingUser) {
          state.useCurrentLocationAsStart(calculateRoute: false);
        }
      }
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (_startFocusNode.hasFocus || _destinationFocusNode.hasFocus) {
      // Płynne podniesienie sheeta po kliknięciu w pole tekstowe, aby klawiatura go nie zasłaniała
      if (_sheetController.isAttached && _sheetController.size < 0.82) {
        _sheetController.animateTo(
          0.88,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _startController.removeListener(_onTextChanged);
    _destinationController.removeListener(_onTextChanged);
    _startFocusNode.removeListener(_onFocusChanged);
    _destinationFocusNode.removeListener(_onFocusChanged);

    _sheetController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    _startFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  String? _syncedLanguage;

  void _syncLocationsWithState(AppState state) {
    final langChanged = _syncedLanguage != state.language;
    _syncedLanguage = state.language;

    if (!_startFocusNode.hasFocus &&
        (_syncedStartId != state.startLocation.id || langChanged)) {
      _syncedStartId = state.startLocation.id;
      _startController.text = state.startLocation.localizedName(state.language);
    }
    if (!_destinationFocusNode.hasFocus) {
      if (state.destinationLocation == null) {
        if (_syncedDestinationId != null) {
          _syncedDestinationId = null;
          _destinationController.clear();
        }
      } else if (_syncedDestinationId != state.destinationLocation!.id ||
          langChanged) {
        _syncedDestinationId = state.destinationLocation!.id;
        _destinationController.text = state.destinationLocation!.localizedName(
          state.language,
        );
      }
    }
    if (state.isAnalyzingRoute) {
      _hasTriggeredSearch = true;
    }
  }

  List<KrakowLocation> _getSuggestions({required bool isDestination}) {
    final query = isDestination
        ? _destinationController.text
        : _startController.text;
    return KrakowLocationsDatabase.search(query);
  }

  void _onSuggestionSelected(
    KrakowLocation loc,
    AppState state, {
    required bool isDestination,
  }) {
    if (isDestination) {
      _syncedDestinationId = loc.id;
      _destinationController.text = loc.namePl;
      state.setDestinationLocation(loc, calculateRoute: false);
    } else {
      _syncedStartId = loc.id;
      _startController.text = loc.namePl;
      state.setStartLocation(loc, calculateRoute: false);
    }

    FocusScope.of(context).unfocus();
  }

  void _onSearchButtonPressed(AppState state) {
    FocusScope.of(context).unfocus();

    final startText = _startController.text.trim();
    final destText = _destinationController.text.trim();

    if (startText.isEmpty || destText.isEmpty) {
      return;
    }

    _hasTriggeredSearch = true;

    // Synchronizuj punkt startowy jeśli użytkownik ręcznie wpisał inną nazwę
    if (startText != state.startLocation.localizedName(state.language) &&
        startText != state.startLocation.namePl) {
      final startMatches = KrakowLocationsDatabase.search(startText);
      if (startMatches.isNotEmpty) {
        state.setStartLocation(startMatches.first, calculateRoute: false);
      } else {
        state.setStartLocation(
          KrakowLocation(
            id: 'loc_custom_start_${DateTime.now().millisecondsSinceEpoch}',
            namePl: startText,
            nameEn: startText,
            address: 'Kraków, $startText',
            point: const LatLng(50.0647, 19.9450),
            category: 'custom',
          ),
          calculateRoute: false,
        );
      }
    }

    // Synchronizuj punkt docelowy jeśli użytkownik ręcznie wpisał inną nazwę
    if (state.destinationLocation == null ||
        (destText != state.destinationLocation!.localizedName(state.language) &&
            destText != state.destinationLocation!.namePl)) {
      final destMatches = KrakowLocationsDatabase.search(destText);
      if (destMatches.isNotEmpty) {
        state.setDestinationLocation(destMatches.first, calculateRoute: false);
      } else {
        state.setDestinationLocation(
          KrakowLocation(
            id: 'loc_custom_dest_${DateTime.now().millisecondsSinceEpoch}',
            namePl: destText,
            nameEn: destText,
            address: 'Kraków, $destText',
            point: const LatLng(50.0617, 19.9373),
            category: 'custom',
          ),
          calculateRoute: false,
        );
      }
    }

    // Faktyczne wyszukiwanie i analiza trasy z wyświetleniem ładowania i wyniku
    state.planRouteBetweenSelectedPoints(showLoader: true);
  }

  void _onSwapLocations(AppState state) {
    FocusScope.of(context).unfocus();

    final currentStartText = _startController.text.trim();
    final currentDestText = _destinationController.text.trim();

    // 1. Jeśli pole docelowe ma wpisany tekst, ale w stanie jest null, pobierz/utwórz lokalizację
    KrakowLocation? destLoc = state.destinationLocation;
    if (destLoc == null && currentDestText.isNotEmpty) {
      final destMatches = KrakowLocationsDatabase.search(currentDestText);
      destLoc = destMatches.isNotEmpty
          ? destMatches.first
          : KrakowLocation(
              id: 'loc_custom_dest_${DateTime.now().millisecondsSinceEpoch}',
              namePl: currentDestText,
              nameEn: currentDestText,
              address: 'Kraków, $currentDestText',
              point: const LatLng(50.0617, 19.9373),
              category: 'custom',
            );
    }

    // 2. Jeśli pole startowe ma wpisany tekst różniący się od stanu, pobierz/utwórz lokalizację
    KrakowLocation startLoc = state.startLocation;
    if (currentStartText.isNotEmpty &&
        currentStartText != state.startLocation.localizedName(state.language) &&
        currentStartText != state.startLocation.namePl) {
      final startMatches = KrakowLocationsDatabase.search(currentStartText);
      startLoc = startMatches.isNotEmpty
          ? startMatches.first
          : KrakowLocation(
              id: 'loc_custom_start_${DateTime.now().millisecondsSinceEpoch}',
              namePl: currentStartText,
              nameEn: currentStartText,
              address: 'Kraków, $currentStartText',
              point: const LatLng(50.0647, 19.9450),
              category: 'custom',
            );
    }

    // 3. Zamiana miejscami
    if (destLoc != null && currentStartText.isNotEmpty) {
      // Obie lokalizacje istnieją
      state.setStartLocation(destLoc, calculateRoute: false);
      state.setDestinationLocation(startLoc, calculateRoute: false);
      _syncedStartId = destLoc.id;
      _syncedDestinationId = startLoc.id;
      _startController.text = destLoc.localizedName(state.language);
      _destinationController.text = startLoc.localizedName(state.language);
    } else if (destLoc != null && currentStartText.isEmpty) {
      // Tylko punkt docelowy był wpisany -> staje się punktem startowym
      state.setStartLocation(destLoc, calculateRoute: false);
      state.setDestinationLocation(null, calculateRoute: false);
      _syncedStartId = destLoc.id;
      _syncedDestinationId = null;
      _startController.text = destLoc.localizedName(state.language);
      _destinationController.clear();
    } else if (currentStartText.isNotEmpty && destLoc == null) {
      // Tylko punkt startowy był wpisany -> staje się punktem docelowym, a start jest czyszczony
      final emptyStart = KrakowLocation(
        id: 'loc_empty_${DateTime.now().millisecondsSinceEpoch}',
        namePl: '',
        nameEn: '',
        address: '',
        point: const LatLng(50.0645, 19.9430),
        category: 'custom',
      );
      state.setStartLocation(emptyStart, calculateRoute: false);
      state.setDestinationLocation(startLoc, calculateRoute: false);
      _syncedStartId = emptyStart.id;
      _syncedDestinationId = startLoc.id;
      _startController.clear();
      _destinationController.text = startLoc.localizedName(state.language);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    _syncLocationsWithState(state);
    final isPL = state.language == 'pl';
    final isUK = state.language == 'uk';

    // Podczas ładowania wyników usuwamy wszystkie inne elementy z sheeta,
    // aby w tym czasie nie dało się niczego kliknąć ani wprowadzać zmian.
    if (state.isAnalyzingRoute) {
      return DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _initialSize,
        minChildSize: _minSize,
        maxChildSize: _maxSize,
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
                                ? 'Wyszukiwanie i analiza trasy...'
                                : (isUK
                                      ? 'Пошук та аналіз маршруту...'
                                      : 'Searching & analyzing route...'),
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
                                      ? 'Analizowanie dostępności AI, barier i nawierzchni...'
                                      : (isUK
                                            ? 'Аналіз доступності AI, бар\'єрів та покриття...'
                                            : 'Analyzing AI accessibility, barriers and surfaces...')),
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

    final isInputFocused =
        _startFocusNode.hasFocus || _destinationFocusNode.hasFocus;
    final textScale = state.textScale;
    final extraScaleHeight = textScale > 1.0 ? (textScale - 1.0) * 120.0 : 0.0;
    final dynamicBaseCardHeight = _baseCardHeight + extraScaleHeight;
    final currentCardHeight = isInputFocused
        ? (dynamicBaseCardHeight + _suggestionsBoxHeight)
        : dynamicBaseCardHeight;
    final currentTotalHeight = currentCardHeight + _bottomSpacing;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _initialSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_initialSize, _maxSize],
      builder: (context, scrollController) {
        return Stack(
          children: [
            // 1. BIAŁY PANEL SHEETA ZACZYNAJĄCY SIĘ PONIŻEJ GÓRY KAFELKA (_overlap)
            Positioned.fill(
              top: _overlap,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 16.0,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
              ),
            ),

            // 2. PRZEWIJANA ZAWARTOŚĆ OD SAMEJ GÓRY (y = 0)
            Positioned.fill(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // Sticky Header wyszukiwarki z podpowiedziami bezpośrednio pod aktywnym polem
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SearchCardStickyDelegate(
                      cardHeight: currentCardHeight,
                      overlap: _overlap,
                      totalHeight: currentTotalHeight,
                      child: _buildSearchCard(
                        context,
                        theme,
                        state,
                        currentCardHeight,
                        isPL,
                        isUK,
                      ),
                    ),
                  ),

                  // 3. SEKCJA WYNIKU TRASY (Gdy wyszukiwanie zostało wykonane)
                  if (_hasTriggeredSearch && state.currentRoute != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 16.0),
                      sliver: SliverToBoxAdapter(
                        child: _buildResultSection(context, theme, state),
                      ),
                    ),

                  // 4. SEKCJA MIEJSC BEZ BARIER (HOTELE, KULTURA, KOPERTY)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 16.0),
                    sliver: SliverToBoxAdapter(
                      child: _buildAccessiblePlacesSection(
                        context,
                        theme,
                        state,
                      ),
                    ),
                  ),

                  // 5. LISTA OSTATNIO WYSZUKIWANYCH POD SPODEM
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 12.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            Icon(Icons.history, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              isPL
                                  ? 'Ostatnio wyszukiwane'
                                  : (isUK
                                        ? 'Нещодавній пошук'
                                        : 'Recent searches'),
                              style: theme.textTheme.displaySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryItem(
                          context,
                          'Dworzec Główny',
                          'Rynek Główny',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Wawel',
                          'Plac Nowy (Kazimierz)',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Hotel Radisson Blu',
                          'Sukiennice',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Centrum Kongresowe ICE',
                          'Gmach Główny MNK',
                          state,
                        ),
                      ]),
                    ),
                  ),

                  // 5. WYBÓR JĘZYKA NA DOLE SHEETA (Polski / Angielski)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 36.0),
                      child: _buildLanguageSelector(theme, state),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Wyszukiwarka o stylistyce ze zdjęcia i kolorach z theme.dart
  Widget _buildSearchCard(
    BuildContext context,
    ThemeData theme,
    AppState state,
    double cardHeight,
    bool isPL,
    bool isUK,
  ) {
    final isHighContrast = theme.brightness == Brightness.dark;
    final isStartFilled = _startController.text.trim().isNotEmpty;
    final isDestinationFilled = _destinationController.text.trim().isNotEmpty;
    final canSearch =
        isStartFilled &&
        isDestinationFilled &&
        !state.isLocatingUser &&
        !state.isAnalyzingRoute;

    return Container(
      constraints: BoxConstraints(minHeight: cardHeight),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: isHighContrast ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek: Ikona trasy + Tytuł + Ikona filtrów
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route,
                      size: 24,
                      color: isHighContrast
                          ? const Color(0xFFFACC15)
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isPL
                            ? 'Wyszukaj trasę'
                            : (isUK ? 'Пошук маршруту' : 'Search route'),
                        style: theme.textTheme.displaySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 20.0,
                  color: isHighContrast
                      ? const Color(0xFFFACC15)
                      : theme.colorScheme.onSurface,
                ),
                tooltip: isPL
                    ? 'Filtry dostępności'
                    : (isUK ? 'Фільтри доступності' : 'Accessibility filters'),
                onPressed: () {
                  showAccessibilityFiltersModal(context);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input 1: Punkt startowy (A)
          _buildInputField(
            context: context,
            controller: _startController,
            focusNode: _startFocusNode,
            icon: Icons.navigation_outlined,
            hint: isPL
                ? 'Punkt startowy (Skąd)'
                : (isUK ? 'Звідки (Початкова точка)' : 'Start location (From)'),
            suffix: GestureDetector(
              onTap: () async {
                await state.useCurrentLocationAsStart(calculateRoute: false);
              },
              child: state.isLocatingUser
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
            ),
            onSubmitted: (query) {
              if (query.trim().isEmpty) return;
              final matches = KrakowLocationsDatabase.search(query.trim());
              if (matches.isNotEmpty) {
                state.setStartLocation(matches.first, calculateRoute: false);
              }
              FocusScope.of(context).unfocus();
            },
          ),

          // Podpowiedzi bezpośrednio pod inputem punktu startowego
          if (_startFocusNode.hasFocus) ...[
            const SizedBox(height: 8),
            _buildInlineSuggestionsBox(
              context,
              theme,
              state,
              isDestination: false,
            ),
          ],

          const SizedBox(height: 8),

          // Input 2: Punkt docelowy (B)
          _buildInputField(
            context: context,
            controller: _destinationController,
            focusNode: _destinationFocusNode,
            icon: Icons.location_on_outlined,
            hint: isPL
                ? 'Wpisz miejsce docelowe'
                : (isUK ? 'Куди (Пункт призначення)' : 'Enter destination'),
            suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_destinationController.text.isNotEmpty &&
                    _destinationFocusNode.hasFocus)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _destinationController.clear();
                      state.setDestinationLocation(null, calculateRoute: false);
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onSwapLocations(state),
                  child: Tooltip(
                    message: isPL
                        ? 'Zamień kierunki miejscami'
                        : (isUK ? 'Поміняти місцями' : 'Swap directions'),
                    child: Icon(Icons.swap_vert_rounded, size: 22),
                  ),
                ),
              ],
            ),
            onSubmitted: (query) {
              if (canSearch) {
                _onSearchButtonPressed(state);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),

          // Podpowiedzi bezpośrednio pod inputem punktu docelowego
          if (_destinationFocusNode.hasFocus) ...[
            const SizedBox(height: 8),
            _buildInlineSuggestionsBox(
              context,
              theme,
              state,
              isDestination: true,
            ),
          ],

          const SizedBox(height: 12),

          // Przycisk "Szukaj" (nieaktywny dopóki oba pola nie są wypełnione)
          SizedBox(
            height: 44 + (state.textScale > 1.0 ? (state.textScale - 1.0) * 16 : 0),
            child: ElevatedButton.icon(
              onPressed: canSearch ? () => _onSearchButtonPressed(state) : null,
              icon: const Icon(Icons.search, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(isPL ? 'Szukaj' : (isUK ? 'Знайти' : 'Search')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Realne pole formularza TextField stylizowane zgodnie z motywem (WCAG compliant)
  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    final theme = Theme.of(context);
    final isHighContrast = theme.brightness == Brightness.dark;

    final inputBg = isHighContrast ? const Color(0xFF141414) : kColorGrayScheme.primary;
    final inputBorderColor = isHighContrast ? const Color(0xFFFACC15) : const Color(0xFFCBD5E1);
    final textColor = isHighContrast ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isHighContrast ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
    final iconColor = isHighContrast ? const Color(0xFFFACC15) : theme.colorScheme.onSurface;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inputBorderColor,
          width: isHighContrast ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: hintColor,
                ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8.0),
          ?suffix,
        ],
      ),
    );
  }

  // Osobny scroll z podpowiedziami umieszczony bezpośrednio pod danym polem input
  Widget _buildInlineSuggestionsBox(
    BuildContext context,
    ThemeData theme,
    AppState state, {
    required bool isDestination,
  }) {
    final suggestions = _getSuggestions(isDestination: isDestination);

    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: suggestions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  state.language == 'pl'
                      ? 'Brak pasujących miejsc w Krakowie'
                      : (state.language == 'uk'
                            ? 'Немає відповідних місць у Кракові'
                            : 'No matching places in Krakow'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          : Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 48,
                  color: theme.colorScheme.outline.withValues(alpha: 0.25),
                ),
                itemBuilder: (context, index) {
                  final loc = suggestions[index];
                  return InkWell(
                    onTap: () => _onSuggestionSelected(
                      loc,
                      state,
                      isDestination: isDestination,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              _getCategoryIcon(loc.category),
                              size: 15,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.namePl,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  loc.address,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.north_west,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'hotel':
        return Icons.hotel_outlined;
      case 'transport':
        return Icons.train_outlined;
      case 'historic':
        return Icons.account_balance_outlined;
      case 'park':
        return Icons.park_outlined;
      case 'culture':
        return Icons.museum_outlined;
      case 'parking':
        return Icons.local_parking_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  Widget _buildAccessiblePlacesSection(
    BuildContext context,
    ThemeData theme,
    AppState state,
  ) {
    final isPL = state.language == 'pl';
    final isUK = state.language == 'uk';

    final hotels = state.allAccessiblePlaces
        .where((p) => p.category == AccessiblePlaceCategory.hotel)
        .toList();
    final buildings = state.allAccessiblePlaces
        .where((p) => p.category != AccessiblePlaceCategory.hotel)
        .toList();
    final parkings = state.parkingSpots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.accessible_forward, size: 24),
                const SizedBox(width: 8),
                Text(
                  isPL
                      ? 'Miejsca z trybem bez barier'
                      : (isUK
                            ? 'Заклади з безбар’єрним режимом'
                            : 'Accessible places & venues'),
                  style: theme.textTheme.displaySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filtry kategorii (Wszystkie, Hotele, Kultura/Budynki, Koperty)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip(
                theme: theme,
                label: isPL ? 'Wszystkie' : 'All',
                isSelected: _placeTabFilter == 'all',
                onTap: () => setState(() => _placeTabFilter = 'all'),
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                theme: theme,
                label:
                    '🏨 ${isPL ? 'Hotele bez barier' : 'Hotels'} (${hotels.length})',
                isSelected: _placeTabFilter == 'hotel',
                onTap: () => setState(() => _placeTabFilter = 'hotel'),
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                theme: theme,
                label:
                    '🏛️ ${isPL ? 'Budynki i kultura' : 'Venues'} (${buildings.length})',
                isSelected: _placeTabFilter == 'building',
                onTap: () => setState(() => _placeTabFilter = 'building'),
              ),
              const SizedBox(width: 6),
              _buildCategoryChip(
                theme: theme,
                label:
                    '🅿️ ${isPL ? 'Koperty ON' : 'Parking'} (${parkings.length})',
                isSelected: _placeTabFilter == 'parking',
                onTap: () => setState(() => _placeTabFilter = 'parking'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Horyzontalna lista kafelków
        SizedBox(
          height: 148 + (state.textScale > 1.0 ? (state.textScale - 1.0) * 85 : 0),
          child: _buildPlacesCardsList(
            context,
            theme,
            state,
            hotels,
            buildings,
            parkings,
            isPL,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesCardsList(
    BuildContext context,
    ThemeData theme,
    AppState state,
    List<AccessiblePlace> hotels,
    List<AccessiblePlace> buildings,
    List<ParkingSpot> parkings,
    bool isPL,
  ) {
    List<Widget> items = [];

    if (_placeTabFilter == 'all' || _placeTabFilter == 'hotel') {
      for (final hotel in hotels) {
        items.add(_buildPlaceCard(context, theme, state, hotel, isPL));
      }
    }

    if (_placeTabFilter == 'all' || _placeTabFilter == 'building') {
      for (final building in buildings) {
        items.add(_buildPlaceCard(context, theme, state, building, isPL));
      }
    }

    if (_placeTabFilter == 'all' || _placeTabFilter == 'parking') {
      for (final spot in parkings) {
        items.add(_buildParkingCard(context, theme, state, spot, isPL));
      }
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (_, index) => items[index],
    );
  }

  Widget _buildPlaceCard(
    BuildContext context,
    ThemeData theme,
    AppState state,
    AccessiblePlace place,
    bool isPL,
  ) {
    final isHotel = place.category == AccessiblePlaceCategory.hotel;
    final badgeColor = isHotel
        ? const Color(0xFFF59E0B)
        : const Color(0xFF8B5CF6);

    final isHighContrast = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        state.selectAccessiblePlace(place);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 245 + (state.textScale > 1.0 ? (state.textScale - 1.0) * 100 : 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighContrast
                ? const Color(0xFFFACC15)
                : badgeColor.withValues(alpha: 0.4),
            width: isHighContrast ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHotel ? Icons.hotel : Icons.account_balance,
                        size: 11,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHotel ? 'HOTEL' : 'KULTURA',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '★ ${place.accessibilityScore}/100',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${place.address} • ${place.district}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (place.hasWheelchairAccess)
                      const Icon(
                        Icons.accessible,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                    if (place.hasHearingLoop) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.hearing,
                        size: 14,
                        color: Color(0xFFA78BFA),
                      ),
                    ],
                    if (place.hasAdaptedRooms) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.king_bed,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPL ? 'Social & Info' : 'Social & Info',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 9,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingCard(
    BuildContext context,
    ThemeData theme,
    AppState state,
    ParkingSpot spot,
    bool isPL,
  ) {
    const badgeColor = Color(0xFF0284C7);

    final isHighContrast = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        state.selectParking(spot);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 245 + (state.textScale > 1.0 ? (state.textScale - 1.0) * 100 : 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighContrast
                ? const Color(0xFFFACC15)
                : badgeColor.withValues(alpha: 0.4),
            width: isHighContrast ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.accessible, size: 11, color: badgeColor),
                      SizedBox(width: 4),
                      Text(
                        'KOPERTA P-24',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (spot.isOccupied
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    spot.isOccupied
                        ? (isPL ? 'Zajęte' : 'Occupied')
                        : (isPL ? 'Wolne' : 'Free'),
                    style: TextStyle(
                      color: spot.isOccupied
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.street,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${spot.spotsCount} ${isPL ? 'koperty' : 'spots'} • ${spot.district}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    spot.note,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Prowadź',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.navigation,
                        size: 10,
                        color: Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Wyświetlanie tekstu wyniku wyszukiwania trasy
  Widget _buildResultSection(
    BuildContext context,
    ThemeData theme,
    AppState state,
  ) {
    final route = state.currentRoute;
    if (route == null) return const SizedBox.shrink();

    final isPL = state.language == 'pl';
    final startName = isPL
        ? state.startLocation.namePl
        : state.startLocation.nameEn;
    final destName = isPL
        ? (state.destinationLocation?.namePl ?? '')
        : (state.destinationLocation?.nameEn ?? '');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.colorScheme.outline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Wynik wyszukiwania trasy:',
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$startName  ➔  $destName',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Typ trasy: ${route.titlePl}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Szacowany czas: ${route.durationMinutes} min  |  Dystans: ${route.getDistanceString()}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Wskaźnik dostępności: ${route.accessibilityScore}/100${route.stairsAvoided > 0 ? " (ominięto ${route.stairsAvoided} st. schodów)" : ""}',
            style: theme.textTheme.bodyMedium,
          ),
          if (route.surfaceSummaryPl.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Nawierzchnia: ${route.surfaceSummaryPl}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (route.bypassReasonPl != null &&
              route.bypassReasonPl!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Informacja o barierach: ${route.bypassReasonPl}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (route.isTransit && route.transitInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              'Komunikacja miejska GTFS: ${route.transitInfo!.summaryDescriptionPl}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    String from,
    String to,
    AppState state,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        _hasTriggeredSearch = true;
        final startMatches = KrakowLocationsDatabase.search(from);
        final destMatches = KrakowLocationsDatabase.search(to);
        if (startMatches.isNotEmpty) {
          state.setStartLocation(startMatches.first);
        }
        if (destMatches.isNotEmpty) {
          state.setDestinationLocation(destMatches.first);
        }
        state.planRouteBetweenSelectedPoints(showLoader: true);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11.0),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      from,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      to,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  /// Przełącznik języka na dole sheeta (tylko na głównym sheecie, emotki flag)
  Widget _buildLanguageSelector(ThemeData theme, AppState state) {
    final isPL = state.language == 'pl';
    final isEN = state.language == 'en';
    final isUK = state.language == 'uk';
    final isHighContrast = theme.brightness == Brightness.dark;

    final bgColor = isHighContrast ? const Color(0xFF141414) : kColorGrayScheme.primary;
    final borderColor = isHighContrast ? const Color(0xFFFACC15) : theme.colorScheme.outline.withValues(alpha: 0.5);
    final textColor = isHighContrast ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final iconColor = isHighContrast ? const Color(0xFFFACC15) : theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                isPL ? 'Język' : (isUK ? 'Мова' : 'Language'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => state.setLanguage('pl'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPL
                        ? (isHighContrast ? const Color(0xFF2E2400) : theme.colorScheme.primaryContainer)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPL
                          ? (isHighContrast ? const Color(0xFFFACC15) : theme.colorScheme.primary)
                          : (isHighContrast ? Colors.white24 : theme.colorScheme.outline.withValues(alpha: 0.3)),
                      width: isPL ? 1.8 : 1.0,
                    ),
                  ),
                  child: const Text('🇵🇱', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => state.setLanguage('en'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isEN
                        ? (isHighContrast ? const Color(0xFF2E2400) : theme.colorScheme.primaryContainer)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEN
                          ? (isHighContrast ? const Color(0xFFFACC15) : theme.colorScheme.primary)
                          : (isHighContrast ? Colors.white24 : theme.colorScheme.outline.withValues(alpha: 0.3)),
                      width: isEN ? 1.8 : 1.0,
                    ),
                  ),
                  child: const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => state.setLanguage('uk'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUK
                        ? (isHighContrast ? const Color(0xFF2E2400) : theme.colorScheme.primaryContainer)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUK
                          ? (isHighContrast ? const Color(0xFFFACC15) : theme.colorScheme.primary)
                          : (isHighContrast ? Colors.white24 : theme.colorScheme.outline.withValues(alpha: 0.3)),
                      width: isUK ? 1.8 : 1.0,
                    ),
                  ),
                  child: const Text('🇺🇦', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Delegat odpowiedzialny za sticky header wyszukiwarki na krawędzi sheeta
class _SearchCardStickyDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double cardHeight;
  final double overlap;
  final double totalHeight;

  const _SearchCardStickyDelegate({
    required this.child,
    required this.cardHeight,
    required this.overlap,
    required this.totalHeight,
  });

  @override
  double get minExtent => totalHeight;

  @override
  double get maxExtent => totalHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Białe tło z zaokrągloną krawędzią zasłaniające przewijaną listę od poziomu overlap
        Positioned(
          top: overlap,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28.0),
              ),
            ),
          ),
        ),

        // Kafelek wyszukiwarki wiszący na górnej krawędzi sheeta
        Positioned(
          top: 0,
          left: 16.0,
          right: 16.0,
          height: cardHeight,
          child: child,
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _SearchCardStickyDelegate oldDelegate) {
    return oldDelegate.totalHeight != totalHeight ||
        oldDelegate.cardHeight != cardHeight ||
        oldDelegate.overlap != overlap ||
        oldDelegate.child != child;
  }
}
