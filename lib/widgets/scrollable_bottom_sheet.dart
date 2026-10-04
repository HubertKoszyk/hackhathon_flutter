import 'package:flutter/material.dart';
import 'package:hackhathon_flutter/theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/krakow_locations.dart';
import 'filters_modal.dart';
import 'route_search_sheet.dart';

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
        _destinationController.text =
            state.destinationLocation!.localizedName(state.language);
      }
    }
    if (state.isAnalyzingRoute) {
      _hasTriggeredSearch = true;
    }
  }

  void _openSearchSheet(BuildContext context, LocationPickMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RouteSearchSheet(pickMode: mode),
    );
  }

  List<KrakowLocation> _getSuggestions({required bool isDestination}) {
    final query = isDestination ? _destinationController.text : _startController.text;
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
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    final currentCardHeight =
        isInputFocused ? (_baseCardHeight + _suggestionsBoxHeight) : _baseCardHeight;
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
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        4.0,
                        20.0,
                        16.0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildResultSection(context, theme, state),
                      ),
                    ),

                  // 4. LISTA OSTATNIO WYSZUKIWANYCH POD SPODEM
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20.0,
                      4.0,
                      20.0,
                      12.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          isPL
                              ? 'Ostatnio wyszukiwane'
                              : (isUK ? 'Нещодавній пошук' : 'Recent searches'),
                          style: theme.textTheme.displaySmall,
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryItem(
                          context,
                          'Mały Rynek',
                          'TAURON Arena',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Mały Rynek',
                          'TAURON Arena',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Mały Rynek',
                          'TAURON Arena',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Dworzec Główny',
                          'Wawel',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Kazimierz',
                          'Kraków Główny',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Rynek Główny',
                          'Nowa Huta',
                          state,
                        ),
                        _buildHistoryItem(
                          context,
                          'Podgórze',
                          'Kopiec Kościuszki',
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
    final isStartFilled = _startController.text.trim().isNotEmpty;
    final isDestinationFilled = _destinationController.text.trim().isNotEmpty;
    final canSearch = isStartFilled &&
        isDestinationFilled &&
        !state.isLocatingUser &&
        !state.isAnalyzingRoute;

    return Container(
      height: cardHeight,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.5,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route,
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPL
                        ? 'Wyszukaj trasę'
                        : (isUK ? 'Пошук маршруту' : 'Search route'),
                    style: theme.textTheme.displaySmall,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 24,
                  color: theme.colorScheme.onSurface,
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
                : (isUK
                    ? 'Звідки (Початкова точка)'
                    : 'Start location (From)'),
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
            suffix: _destinationController.text.isNotEmpty &&
                    _destinationFocusNode.hasFocus
                ? GestureDetector(
                    onTap: () {
                      _destinationController.clear();
                      state.setDestinationLocation(null, calculateRoute: false);
                      setState(() {});
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  )
                : Icon(
                    Icons.search,
                    size: 18,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
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
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canSearch ? () => _onSearchButtonPressed(state) : null,
              icon: const Icon(
                Icons.search,
                size: 20,
              ),
              label: Text(
                isPL ? 'Szukaj' : (isUK ? 'Знайти' : 'Search'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Realne pole formularza TextField stylizowane zgodnie z motywem
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

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kColorGrayScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
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
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
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
      case 'transport':
        return Icons.train_outlined;
      case 'historic':
        return Icons.account_balance_outlined;
      case 'park':
        return Icons.park_outlined;
      case 'culture':
        return Icons.museum_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  // Wyświetlanie tekstu "Ładowanie..." w trakcie analizy trasy
  Widget _buildLoadingSection(
    BuildContext context,
    ThemeData theme,
    AppState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ładowanie...',
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 18),
              ),
            ],
          ),
          if (state.analysisStatusText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              state.analysisStatusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
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
    final startName =
        isPL ? state.startLocation.namePl : state.startLocation.nameEn;
    final destName = isPL
        ? (state.destinationLocation?.namePl ?? '')
        : (state.destinationLocation?.nameEn ?? '');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.2,
        ),
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
            Icon(
              Icons.history,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kColorGrayScheme.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1.0,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 8),
              Text(
                isPL ? 'Język' : (isUK ? 'Мова' : 'Language'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPL
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPL
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isPL ? 1.5 : 1.0,
                    ),
                  ),
                  child: const Text(
                    '🇵🇱',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => state.setLanguage('en'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEN
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEN
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isEN ? 1.5 : 1.0,
                    ),
                  ),
                  child: const Text(
                    '🇬🇧',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => state.setLanguage('uk'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUK
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUK
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isUK ? 1.5 : 1.0,
                    ),
                  ),
                  child: const Text(
                    '🇺🇦',
                    style: TextStyle(fontSize: 18),
                  ),
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
