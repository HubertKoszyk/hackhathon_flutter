import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/accessible_place.dart';
import '../providers/app_state.dart';

class AccessiblePlaceSheet extends StatelessWidget {
  final AccessiblePlace place;

  const AccessiblePlaceSheet({super.key, required this.place});

  Future<void> _launch(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie można otworzyć linku: $urlString'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd otwierania: $urlString'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Numer telefonu: $phone'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Numer telefonu: $phone'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';
    final isHotel = place.category == AccessiblePlaceCategory.hotel;

    final categoryColor = isHotel
        ? const Color(0xFFF59E0B) // Amber for hotels
        : const Color(0xFF8B5CF6); // Violet/Purple for cultural/public buildings

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      padding: const EdgeInsets.all(18),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek: Ikona, Kategoria, Nazwa i Przycisk zamknięcia
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: categoryColor),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isHotel
                            ? Icons.hotel
                            : (place.category == AccessiblePlaceCategory.publicBuilding
                                ? Icons.apartment
                                : Icons.account_balance),
                        color: categoryColor,
                        size: 26,
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.accessible,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPL ? place.categoryLabelPl : place.categoryLabelEn,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF34D399),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${place.accessibilityScore}/100',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white60,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${place.address} (${place.district})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => state.selectAccessiblePlace(null),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Chips: Udogodnienia dla osób z niepełnosprawnościami
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (place.hasWheelchairAccess)
                  _buildFeatureBadge(
                    icon: Icons.accessible,
                    label: isPL ? 'Brak barier / Winda' : 'Step-free / Lift',
                    color: const Color(0xFF38BDF8),
                  ),
                if (place.hasHearingLoop)
                  _buildFeatureBadge(
                    icon: Icons.hearing,
                    label: isPL ? 'Pętla indukcyjna' : 'Hearing loop',
                    color: const Color(0xFFA78BFA),
                  ),
                if (place.hasBrailleOrAudio)
                  _buildFeatureBadge(
                    icon: Icons.visibility,
                    label: isPL ? 'Braille / Audiodeskrypcja' : 'Braille / Audio',
                    color: const Color(0xFFFBBF24),
                  ),
                if (place.hasAdaptedRooms)
                  _buildFeatureBadge(
                    icon: Icons.king_bed,
                    label: isPL ? 'Pokoje z prysznicem roll-in' : 'Roll-in shower rooms',
                    color: const Color(0xFF34D399),
                  ),
                if (place.hasAdaptedRestroom)
                  _buildFeatureBadge(
                    icon: Icons.wc,
                    label: isPL ? 'Toaleta PwN' : 'Accessible WC',
                    color: const Color(0xFF60A5FA),
                  ),
                if (place.hasDedicatedParking)
                  _buildFeatureBadge(
                    icon: Icons.local_parking,
                    label: isPL ? 'Koperta P-24' : 'Disabled parking',
                    color: const Color(0xFF0284C7),
                  ),
                if (place.hasAssistanceDogWelcome)
                  _buildFeatureBadge(
                    icon: Icons.pets,
                    label: isPL ? 'Pies asystujący' : 'Service dog welcome',
                    color: const Color(0xFFF472B6),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Opis obiektu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPL ? place.descriptionPl : place.descriptionEn,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPL
                        ? 'Kluczowe rozwiązania dostępności:'
                        : 'Key accessibility highlights:',
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final item in (isPL
                      ? place.accessibilityHighlightsPl
                      : place.accessibilityHighlightsEn).take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =================================================================
            // SEKCJA SOCIAL MEDIA & KONTAKT (Główny wymóg użytkownika!)
            // =================================================================
            Text(
              isPL ? 'Social Media & Oficjalne Linki:' : 'Social Media & Official Links:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // 1. Instagram
                if (place.instagramUrl != null)
                  Expanded(
                    child: _buildSocialButton(
                      context: context,
                      icon: Icons.camera_alt,
                      label: 'Instagram',
                      subtitle: place.instagramHandle ?? 'Profil',
                      gradientColors: const [
                        Color(0xFF833AB4),
                        Color(0xFFFD1D1D),
                        Color(0xFFFCB045),
                      ],
                      onTap: () => _launch(context, place.instagramUrl!),
                    ),
                  ),
                if (place.instagramUrl != null && place.facebookUrl != null)
                  const SizedBox(width: 8),

                // 2. Facebook
                if (place.facebookUrl != null)
                  Expanded(
                    child: _buildSocialButton(
                      context: context,
                      icon: Icons.facebook,
                      label: 'Facebook',
                      subtitle: isPL ? 'Strona FB' : 'FB Page',
                      backgroundColor: const Color(0xFF1877F2),
                      onTap: () => _launch(context, place.facebookUrl!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // 3. Oficjalna strona WWW
                Expanded(
                  child: _buildSocialButton(
                    context: context,
                    icon: Icons.language,
                    label: isPL ? 'Strona WWW' : 'Website',
                    subtitle: isPL ? 'Rezerwacja / Info' : 'Official Portal',
                    backgroundColor: const Color(0xFF0284C7),
                    onTap: () => _launch(context, place.websiteUrl),
                  ),
                ),
                if (place.phoneNumber != null) const SizedBox(width: 8),

                // 4. Telefon kontaktowy / Asystent
                if (place.phoneNumber != null)
                  Expanded(
                    child: _buildSocialButton(
                      context: context,
                      icon: Icons.phone,
                      label: isPL ? 'Telefon' : 'Phone',
                      subtitle: place.phoneNumber!,
                      backgroundColor: const Color(0xFF059669),
                      onTap: () => _makePhoneCall(context, place.phoneNumber!),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Przyciski akcji: "Wyznacz trasę bez barier tutaj" oraz "Wyrusz stąd"
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => state.planRouteToAccessiblePlace(place),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.directions_walk, size: 20),
                    label: Text(
                      isPL
                          ? 'Wyznacz trasę bez barier tutaj'
                          : 'Plan accessible route here',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      state.setStartLocation(place.toKrakowLocation());
                      state.selectAccessiblePlace(null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isPL
                                ? 'Ustawiono jako punkt startowy: ${place.name}'
                                : 'Set as start point: ${place.name}',
                          ),
                          backgroundColor: const Color(0xFF0F172A),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.trip_origin, size: 18),
                    label: Text(
                      isPL ? 'Wyrusz stąd' : 'Start here',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    Color? backgroundColor,
    List<Color>? gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: gradientColors == null
                ? (backgroundColor ?? const Color(0xFF1E293B))
                : null,
            gradient: gradientColors != null
                ? LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_outward, color: Colors.white70, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}
