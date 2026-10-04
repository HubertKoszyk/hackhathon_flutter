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
            backgroundColor: const Color(0xFF0F172A),
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
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Numer telefonu: $phone'),
            backgroundColor: const Color(0xFF0F172A),
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

    final primaryThemeColor = isHotel
        ? const Color(0xFFD97706) // Rich amber
        : const Color(0xFF7C3AED); // Modern violet

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pasek uchwytu (drag handle)
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Nagłówek: Ikona, Kategoria, Nazwa i Przycisk zamknięcia
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHotel
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHotel
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFE9D5FF),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isHotel
                            ? Icons.hotel_rounded
                            : (place.category == AccessiblePlaceCategory.publicBuilding
                                ? Icons.apartment_rounded
                                : Icons.account_balance_rounded),
                        color: primaryThemeColor,
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
                            Icons.accessible_rounded,
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isHotel
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isHotel
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFE9D5FF),
                              ),
                            ),
                            child: Text(
                              isPL ? place.categoryLabelPl : place.categoryLabelEn,
                              style: TextStyle(
                                color: primaryThemeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 12,
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  '${place.accessibilityScore}/100',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'PlusJakartaSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'PlusJakartaSans',
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF64748B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${place.address} (${place.district})',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => state.selectAccessiblePlace(null),
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
                      size: 20,
                    ),
                  ),
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
                    icon: Icons.accessible_rounded,
                    label: isPL ? 'Brak barier / Winda' : 'Step-free / Lift',
                    iconColor: const Color(0xFF0284C7),
                  ),
                if (place.hasHearingLoop)
                  _buildFeatureBadge(
                    icon: Icons.hearing_rounded,
                    label: isPL ? 'Pętla indukcyjna' : 'Hearing loop',
                    iconColor: const Color(0xFF7C3AED),
                  ),
                if (place.hasBrailleOrAudio)
                  _buildFeatureBadge(
                    icon: Icons.visibility_rounded,
                    label: isPL ? 'Braille / Audiodeskrypcja' : 'Braille / Audio',
                    iconColor: const Color(0xFFD97706),
                  ),
                if (place.hasAdaptedRooms)
                  _buildFeatureBadge(
                    icon: Icons.king_bed_rounded,
                    label: isPL ? 'Pokoje roll-in shower' : 'Roll-in shower rooms',
                    iconColor: const Color(0xFF059669),
                  ),
                if (place.hasAdaptedRestroom)
                  _buildFeatureBadge(
                    icon: Icons.wc_rounded,
                    label: isPL ? 'Toaleta PwN' : 'Accessible WC',
                    iconColor: const Color(0xFF2563EB),
                  ),
                if (place.hasDedicatedParking)
                  _buildFeatureBadge(
                    icon: Icons.local_parking_rounded,
                    label: isPL ? 'Koperta P-24' : 'Disabled parking',
                    iconColor: const Color(0xFF0048FF),
                  ),
                if (place.hasAssistanceDogWelcome)
                  _buildFeatureBadge(
                    icon: Icons.pets_rounded,
                    label: isPL ? 'Pies asystujący' : 'Service dog welcome',
                    iconColor: const Color(0xFFDB2777),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Opis obiektu i rozwiązania dostępności
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPL ? place.descriptionPl : place.descriptionEn,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPL
                        ? 'Kluczowe rozwiązania dostępności:'
                        : 'Key accessibility highlights:',
                    style: TextStyle(
                      color: primaryThemeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final item in (isPL
                      ? place.accessibilityHighlightsPl
                      : place.accessibilityHighlightsEn).take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12,
                                height: 1.3,
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
            // SEKCJA SOCIAL MEDIA & KONTAKT
            // =================================================================
            Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF0048FF),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isPL ? 'Social Media i Kontakt:' : 'Social Media & Contact:',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // 1. Instagram
                if (place.instagramUrl != null)
                  Expanded(
                    child: _buildSocialButton(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      label: 'Instagram',
                      subtitle: place.instagramHandle ?? 'Profil',
                      gradientColors: const [
                        Color(0xFF833AB4),
                        Color(0xFFFD1D1D),
                        Color(0xFFFCB045),
                      ],
                      isGradient: true,
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
                      icon: Icons.facebook_rounded,
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
                    icon: Icons.language_rounded,
                    label: isPL ? 'Strona WWW' : 'Website',
                    subtitle: isPL ? 'Rezerwacja / Info' : 'Official Portal',
                    backgroundColor: const Color(0xFF0048FF),
                    onTap: () => _launch(context, place.websiteUrl),
                  ),
                ),
                if (place.phoneNumber != null) const SizedBox(width: 8),

                // 4. Telefon kontaktowy / Asystent
                if (place.phoneNumber != null)
                  Expanded(
                    child: _buildSocialButton(
                      context: context,
                      icon: Icons.phone_rounded,
                      label: isPL ? 'Telefon' : 'Phone',
                      subtitle: place.phoneNumber!,
                      backgroundColor: const Color(0xFF059669),
                      onTap: () => _makePhoneCall(context, place.phoneNumber!),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Przyciski akcji: "Wyznacz trasę bez barier" oraz "Wyrusz stąd"
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => state.planRouteToAccessiblePlace(place),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0048FF),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.alt_route_rounded, size: 19),
                    label: Text(
                      isPL ? 'Trasa bez barier' : 'Accessible route',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => state.planRouteFromAccessiblePlace(place),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0048FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
                      backgroundColor: const Color(0xFFEFF6FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.trip_origin_rounded, size: 16),
                    label: Text(
                      isPL ? 'Start stąd' : 'Start here',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 11,
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
    bool isGradient = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isGradient ? null : backgroundColor,
            gradient: isGradient
                ? LinearGradient(
                    colors: gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isGradient ? gradientColors!.first : backgroundColor!)
                    .withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
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
                        fontWeight: FontWeight.w800,
                        fontFamily: 'PlusJakartaSans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                color: Colors.white70,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
