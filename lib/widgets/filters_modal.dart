import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';

/// Modal z wyborem filtrów dostępności (profilu mobilności)
void showAccessibilityFiltersModal(BuildContext context) {
  final theme = Theme.of(context);
  final lang = context.read<AppState>().language;
  final isPL = lang == 'pl';
  final isUK = lang == 'uk';

  final modalTitle = isUK
      ? 'Фільтри доступності'
      : (isPL ? 'Filtry dostępności' : 'Accessibility Filters');
  final modalSubtitle = isUK
      ? 'Оберіть профіль мобільності для адаптації маршруту:'
      : (isPL
            ? 'Wybierz profil mobilności, aby dopasować trasę i omijać przeszkody:'
            : 'Choose mobility profile to tailor routes and bypass obstacles:');

  final wheelchairTitle = isUK
      ? 'Крісло колісне'
      : (isPL ? 'Wózek inwalidzki' : 'Wheelchair');
  final wheelchairSubtitle = isUK
      ? '100% маршрут без сходів (0 сходинок), пандуси та ліфти'
      : (isPL
            ? '100% trasa bez schodów (0 stopni), rampy, szerokie chodniki i windy'
            : '100% step-free route (0 stairs), ramps, wide paths & lifts');

  final caneTitle = isUK
      ? 'З тростиною / Літня особа'
      : (isPL ? 'Osoba z laską' : 'Person with cane');
  final caneSubtitle = isUK
      ? 'Уникнення високих сходинок, поручні та рівне покриття'
      : (isPL
            ? 'Omijanie wysokich stopni, bezpieczne poręcze i stabilna nawierzchnia'
            : 'Avoid steep stairs, prioritize handrails & even surface');

  final strollerTitle = isUK
      ? 'Дитячий візок'
      : (isPL ? 'Wózek z dzieckiem' : 'Stroller / Pram');
  final strollerSubtitle = isUK
      ? 'Пологі з’їзди, занижені бордюри, уникнення сходів'
      : (isPL
            ? 'Łagodne podjazdy, obniżone krawężniki, unikanie schodów'
            : 'Gentle slopes, lowered curbs, avoiding stairs');

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final activeProfile = appState.profile;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nagłówek filtrów
                  Row(
                    children: [
                      Icon(Icons.tune, size: 20.0),
                      const SizedBox(width: 10),
                      Text(modalTitle, style: theme.textTheme.displaySmall),
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 24.0,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    modalSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Opcja 1: Wózek inwalidzki
                  _buildProfileOption(
                    theme: theme,
                    isSelected: activeProfile == MobilityProfile.wheelchair,
                    icon: Icons.accessible,
                    title: wheelchairTitle,
                    subtitle: wheelchairSubtitle,
                    onTap: () {
                      appState.setProfile(MobilityProfile.wheelchair);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Opcja 2: Osoba z laską
                  _buildProfileOption(
                    theme: theme,
                    isSelected: activeProfile == MobilityProfile.cane,
                    icon: Icons.elderly,
                    title: caneTitle,
                    subtitle: caneSubtitle,
                    onTap: () {
                      appState.setProfile(MobilityProfile.cane);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Opcja 3: Wózek z dzieckiem
                  _buildProfileOption(
                    theme: theme,
                    isSelected: activeProfile == MobilityProfile.stroller,
                    icon: Icons.child_friendly,
                    title: strollerTitle,
                    subtitle: strollerSubtitle,
                    onTap: () {
                      appState.setProfile(MobilityProfile.stroller);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildProfileOption({
  required ThemeData theme,
  required bool isSelected,
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : kColorGrayScheme.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.4),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 22,
          ),
        ],
      ),
    ),
  );
}
