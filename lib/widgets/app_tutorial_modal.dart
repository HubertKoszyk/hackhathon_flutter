import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AppTutorialModal extends StatefulWidget {
  final bool isFirstLaunch;

  const AppTutorialModal({super.key, this.isFirstLaunch = false});

  static Future<void> show(BuildContext context, {bool isFirstLaunch = false}) {
    return showDialog(
      context: context,
      barrierDismissible: !isFirstLaunch,
      builder: (ctx) => AppTutorialModal(isFirstLaunch: isFirstLaunch),
    );
  }

  @override
  State<AppTutorialModal> createState() => _AppTutorialModalState();
}

class _AppTutorialModalState extends State<AppTutorialModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishTutorial() {
    final state = context.read<AppState>();
    state.markTutorialAsSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Górna belka modala: Wskaźnik postępu i przycisk Zamknij / Pomiń
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${isPL ? 'Krok' : 'Step'} ${_currentPage + 1} / $_totalPages',
                      style: const TextStyle(
                        color: Color(0xFF0048FF),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!widget.isFirstLaunch || _currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _finishTutorial,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: Text(
                        isPL ? 'Pomiń' : 'Skip',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  InkWell(
                    onTap: _finishTutorial,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF475569),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Główna treść w PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildSlide1(isPL),
                  _buildSlide2(isPL),
                  _buildSlide3(isPL),
                  _buildSlide4(isPL),
                  _buildSlide5(isPL),
                ],
              ),
            ),

            // Dolny panel nawigacyjny: Kropki postępu + Przyciski Dalej / Wstecz
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wskaźnik stron (Pill dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        height: 6.5,
                        width: isActive ? 24 : 6.5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF0048FF)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Przyciski akcji
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        OutlinedButton(
                          onPressed: _prevPage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            backgroundColor: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0048FF),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            _currentPage == _totalPages - 1
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _currentPage == _totalPages - 1
                                ? (isPL
                                      ? 'Rozpocznij korzystanie z NavAble'
                                      : 'Start using NavAble')
                                : (isPL ? 'Następny krok' : 'Next step'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIDE 1: Główna zasada działania – Inspekcja zdjęć trasy przez AI
  // ===========================================================================
  Widget _buildSlide1(bool isPL) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0048FF), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0048FF).withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPL
                            ? 'Wizualny Audyt AI'
                            : 'AI Vision Audit Engine',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPL
                            ? 'Analiza zdjęć ulic i chodników'
                            : 'Street View inspection per checkpoint',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isPL
                ? 'Jak działa aplikacja NavAble?'
                : 'How does NavAble work?',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPL
                ? 'Zwykłe nawigacje wyznaczają najkrótszą drogę po kresce na mapie. NavAble robi coś zupełnie innego: '
                  'przechodzi wzdłuż całej trasy, pobiera rzeczywiste zdjęcia Google Street View z każdego skrzyżowania '
                  'i analizuje je pod kątem barier dla osób z niepełnosprawnościami.'
                : 'Standard map apps only calculate line distances. NavAble goes beyond: '
                  'it steps along the entire route, downloads real Street View photos for every checkpoint '
                  'and uses AI to evaluate safety for disabled passengers.',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          _buildFeatureRow(
            icon: Icons.stairs_rounded,
            iconColor: const Color(0xFFEF4444),
            title: isPL ? 'Wykrywanie schodów i braków ramp' : 'Detecting stairs & lack of ramps',
            desc: isPL
                ? 'Model AI rozpoznaje stopnie i natychmiast kieruje na pochylnię lub windę.'
                : 'AI flags architectural barriers and redirects to ramps or elevators.',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.height_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: isPL ? 'Ocena wysokości krawężników' : 'Curb height verification',
            desc: isPL
                ? 'Weryfikacja czy przejście dla pieszych ma obniżony krawężnik (poniżej 2 cm).'
                : 'Verifying dropped curbs at pedestrian crossings below 2 cm.',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.texture_rounded,
            iconColor: const Color(0xFF10B981),
            title: isPL ? 'Omijanie kocich łbów i bruku' : 'Avoiding cobblestones',
            desc: isPL
                ? 'Koniec z wibracjami wózka: eliminacja nierównego bruku (np. ul. Floriańska).'
                : 'Zero wheelchair vibrations: avoids bumpy cobblestone alleys.',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE 2: Profile Mobilności
  // ===========================================================================
  Widget _buildSlide2(bool isPL) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPL
                ? 'Dopasowanie do Twoich potrzeb'
                : 'Tailored to your mobility',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPL
                ? 'Wybierz profil mobilności, aby algorytm dostosował trasę do Twoich fizycznych możliwości:'
                : 'Choose your profile to let the routing engine adapt to your physical needs:',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          _buildProfileCard(
            icon: Icons.accessible_rounded,
            color: const Color(0xFF0048FF),
            title: isPL ? 'Wózek inwalidzki (Wheelchair)' : 'Wheelchair',
            desc: isPL
                ? 'Trasa w 100% bez schodów. Maksymalne nachylenie pochylni do 6%, tylko gładkie chodniki i obniżone krawężniki.'
                : '100% step-free routing. Incline under 6%, dropped curbs and smooth pavements only.',
          ),
          const SizedBox(height: 10),

          _buildProfileCard(
            icon: Icons.elderly_rounded,
            color: const Color(0xFF7C3AED),
            title: isPL ? 'Laska / Balkonik (Cane / Walker)' : 'Cane & Walker',
            desc: isPL
                ? 'Minimalizacja liczby stopni, unikanie stromych wzniesień, priorytet dla tras z ławkami do odpoczynku i poręczami.'
                : 'Minimizes step count, avoids steep inclines, prioritizes handrails and rest benches.',
          ),
          const SizedBox(height: 10),

          _buildProfileCard(
            icon: Icons.baby_changing_station_rounded,
            color: const Color(0xFF059669),
            title: isPL ? 'Wózek dziecięcy (Stroller)' : 'Baby Stroller',
            desc: isPL
                ? 'Szerokie chodniki, płynne zjazdy, omijanie wąskich przejść i zatłoczonych wąskich gardeł.'
                : 'Wide sidewalks, gentle ramps, bypassing congested narrow street corridors.',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE 3: Wizualny Audyt i Street View
  // ===========================================================================
  Widget _buildSlide3(bool isPL) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPL
                ? 'Zobacz barierę zanim wyruszysz'
                : 'Inspect barriers before you travel',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPL
                ? 'Nie musisz zgadywać, czy na skrzyżowaniu czeka na Ciebie niespodzianka. Masz pełny wgląd w zdjęcia:'
                : 'No more guessing whether an intersection has unexpected stairs. Preview real photos:',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPL
                            ? 'Wykrycie przeszkody na trasie'
                            : 'Barrier detection on route',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPL
                      ? 'Po wyznaczeniu trasy kliknij w kafelki punktów kontrolnych (np. "Tunel Magda - Schody"). '
                        'Zobaczysz zdjęcie bariery oraz analizę AI wyjaśniającą powód objazdu.'
                      : 'After calculating a route, tap any checkpoint card. '
                        'Inspect the barrier photo and AI recommendations.',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPL
                            ? 'Zweryfikowany objazd fotograficzny'
                            : 'Verified bypass photo',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPL
                      ? 'W modalu audytu możesz jednym kliknięciem przełączyć widok na "Pokaż bezpieczny objazd" '
                        'i zobaczyć zdjęcie windy lub rampy, którą poprowadzi Cię NavAble.'
                      : 'Toggle the "Show safe bypass" button inside the modal to see the elevator or ramp '
                        'where NavAble safely navigates you.',
                  style: const TextStyle(color: Color(0xFF166534), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE 4: Ponad 51 punktów: Parkingi ON & Miejsca bez barier
  // ===========================================================================
  Widget _buildSlide4(bool isPL) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPL
                ? '51+ Miejsc Dostępnych i Kopert ON'
                : '51+ Accessible Venues & Parking',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPL
                ? 'Baza zweryfikowanych miejsc w centrum Krakowa dostępna w dolnym panelu wyszukiwarki:'
                : 'Verified locations database in Kraków available directly in the bottom sheet:',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          _buildVenueFeatureRow(
            icon: Icons.local_parking_rounded,
            iconColor: const Color(0xFF0048FF),
            badgeColor: const Color(0xFFEFF6FF),
            title: isPL ? '35 Kopert Parkingowych (P-24)' : '35 Disabled Parking Spots (P-24)',
            desc: isPL
                ? 'Niebieskie znaczniki na mapie z dokładnymi współrzędnymi pod sam krawężnik.'
                : 'Blue map pins with precise GPS location right at the curb.',
          ),
          const SizedBox(height: 10),

          _buildVenueFeatureRow(
            icon: Icons.hotel_rounded,
            iconColor: const Color(0xFFD97706),
            badgeColor: const Color(0xFFFEF3C7),
            title: isPL ? 'Hotele bez barier (Radisson, Sheraton, PURO...)' : 'Accessible Hotels',
            desc: isPL
                ? 'Pokoje z prysznicem roll-in shower, toalety PwN i windy dla wózków.'
                : 'Roll-in shower adapted rooms, accessible restrooms and step-free access.',
          ),
          const SizedBox(height: 10),

          _buildVenueFeatureRow(
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF7C3AED),
            badgeColor: const Color(0xFFF3E8FF),
            title: isPL ? 'Budynki kultury i urzędy (ICE, Sukiennice, MNK)' : 'Culture & Public Buildings',
            desc: isPL
                ? 'Pętle indukcyjne dla osób słabosłyszących, braille i wstęp dla psów asystujących.'
                : 'Hearing induction loops, braille signage and assistance dog welcome.',
          ),
          const SizedBox(height: 10),

          _buildVenueFeatureRow(
            icon: Icons.share_rounded,
            iconColor: const Color(0xFFDB2777),
            badgeColor: const Color(0xFFFDF2F8),
            title: isPL ? 'Social Media i Bezpośredni Kontakt' : 'Social Media & Direct Contact',
            desc: isPL
                ? 'Kliknij w dowolny obiekt, aby otworzyć Instagram, Facebook, stronę WWW lub zadzwonić na recepcję!'
                : 'Tap any venue to open Instagram, Facebook, website or call reception directly!',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SLIDE 5: Nawigacja na Żywo i Zgłaszanie Przeszkód
  // ===========================================================================
  Widget _buildSlide5(bool isPL) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPL
                ? 'Nawigacja na żywo i Społeczność'
                : 'Live Navigation & Community',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPL
                ? 'Wyrusz w drogę i korzystaj z aktywnego asystenta turn-by-turn:'
                : 'Start walking with active turn-by-turn guidance:',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF0048FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPL
                            ? 'Wskazówki głosowe i perony MPK'
                            : 'Voice guidance & low-floor trams',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPL
                            ? 'Asystent na bieżąco informuje o zbliżających się rampach, windach oraz dostępnych peronach tramwajowych.'
                            : 'Real-time turn-by-turn HUD alerting about upcoming elevators and accessible platforms.',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPL
                            ? 'Zgłaszanie barier (Przycisk aparatu)'
                            : 'Crowdsourced barrier reports',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPL
                            ? 'Widzisz rozkopany chodnik lub zepsutą windę? Kliknij pływający przycisk aparatu nad mapą. '
                              'AI natychmiast zweryfikuje zgłoszenie i ochroni innych przed utknięciem!'
                            : 'Spotted sudden roadworks or a broken elevator? Tap the camera FAB button. '
                              'AI immediately updates routing to safeguard others!',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pomocnicze widżety stylizacyjne
  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueFeatureRow({
    required IconData icon,
    required Color iconColor,
    required Color badgeColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
