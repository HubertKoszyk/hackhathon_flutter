import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/krakow_locations.dart';

enum LocationPickMode { start, destination }

class RouteSearchSheet extends StatefulWidget {
  final LocationPickMode pickMode;

  const RouteSearchSheet({super.key, required this.pickMode});

  @override
  State<RouteSearchSheet> createState() => _RouteSearchSheetState();
}

class _RouteSearchSheetState extends State<RouteSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<KrakowLocation> _filteredLocations = KrakowLocationsDatabase.locations;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredLocations = KrakowLocationsDatabase.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final isStart = widget.pickMode == LocationPickMode.start;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Pasek chwytaka
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tytuł
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isStart ? Icons.trip_origin : Icons.location_on,
                  color: isStart ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isStart
                      ? (isPL ? 'Wybierz punkt startowy (Skąd)' : 'Choose starting point')
                      : (isPL ? 'Wybierz punkt docelowy (Dokąd)' : 'Choose destination'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Pole wyszukiwania
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: isPL
                    ? 'Szukaj w Krakowie (np. Wawel, Rynek, Dworzec)...'
                    : 'Search Kraków (e.g. Wawel, Market, Station)...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Przycisk "Użyj mojej bieżącej pozycji (GPS)"
          InkWell(
            onTap: () async {
              Navigator.of(context).pop();
              await state.useCurrentLocationAsStart();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPL ? 'Moja bieżąca lokalizacja (GPS)' : 'My current location (GPS)',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isPL ? 'Wyznacz trasę bez barier od miejsca, gdzie stoisz' : 'Plan accessible route from where you are',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFF38BDF8), size: 12),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 14),

          // Lista miejsc
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLocations.length,
              itemBuilder: (ctx, idx) {
                final loc = _filteredLocations[idx];
                final isSelected = isStart
                    ? state.startLocation.id == loc.id
                    : state.destinationLocation?.id == loc.id;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isStart ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(loc.category),
                      color: isSelected
                          ? (isStart ? const Color(0xFF34D399) : const Color(0xFFF87171))
                          : const Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isPL ? loc.namePl : loc.nameEn,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    loc.address,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF10B981), size: 18)
                      : null,
                  onTap: () {
                    if (isStart) {
                      state.setStartLocation(loc);
                    } else {
                      state.setDestinationLocation(loc);
                    }
                    Navigator.of(context).pop();
                    state.planRouteBetweenSelectedPoints(showLoader: true);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'hotel':
        return Icons.hotel;
      case 'transport':
        return Icons.train;
      case 'historic':
        return Icons.account_balance;
      case 'park':
        return Icons.park;
      case 'culture':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }
}
