import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Wyświetla okno modalne ze szczegółami o źródłach i aktualności danych.
void showDataSourcesDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const DataSourcesDialog());
}

class DataSourcesDialog extends StatelessWidget {
  const DataSourcesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPl = state.language == 'pl';
    final isUk = state.language == 'uk';
    final isHighContrast = state.isHighContrastMode;

    final bgColor = isHighContrast ? const Color(0xFF000000) : Colors.white;
    final cardColor = isHighContrast
        ? const Color(0xFF141414)
        : const Color(0xFFF8FAFC);
    final textColor = isHighContrast ? Colors.white : const Color(0xFF0F172A);
    final accentColor = isHighContrast
        ? const Color(0xFFFACC15)
        : const Color(0xFF0048FF);
    final borderColor = isHighContrast
        ? const Color(0xFFFACC15)
        : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: isHighContrast ? 2.5 : 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nagłówek okna
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPl
                              ? 'Źródła i aktualność danych'
                              : (isUk
                                    ? 'Джерела та актуальність даних'
                                    : 'Data Sources & Freshness'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPl
                              ? 'Kraków • Stan aktualizacji i pochodzenie danych'
                              : (isUk
                                    ? 'Краків • Стан оновлення та походження даних'
                                    : 'Kraków • Data freshness and provenance'),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    tooltip: isPl ? 'Zamknij' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Lista źródeł danych
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(18),
                shrinkWrap: true,
                children: [
                  // 1. Google Street View
                  _buildSourceTile(
                    icon: Icons.streetview,
                    iconColor: const Color(0xFF0284C7),
                    title: isPl
                        ? 'Street View & Zdjęcia terenowe'
                        : (isUk
                              ? 'Street View та фотографії'
                              : 'Street View & Field Imagery'),
                    statusText: isPl
                        ? 'Lipiec 2025'
                        : (isUk ? 'Липень 2025' : 'July 2025'),
                    statusColor: const Color(0xFF0284C7),
                    description: isPl
                        ? 'Zdjęcia panoramiczne Google Street View oraz klatki audytowe z terenu (lipiec 2025) analizowane przez model wizyjny AI pod kątem krawężników, szerokości przejść i barier.'
                        : (isUk
                              ? 'Панорамні знімки Google Street View та кадри польового аудиту (липень 2025), проаналізовані зоровою моделлю AI на наявність перешкод.'
                              : 'Google Street View panoramas and audit footage (July 2025) analyzed by AI vision for curbs, narrow passages, and physical barriers.'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    isHighContrast: isHighContrast,
                  ),
                  const SizedBox(height: 12),

                  // 2. Kamery miejskie
                  _buildSourceTile(
                    icon: Icons.videocam,
                    iconColor: const Color(0xFFEF4444),
                    title: isPl
                        ? 'Kamery miejskie (Monitoring)'
                        : (isUk
                              ? 'Міські камери (Відеоспостереження)'
                              : 'City Cameras (Live Stream)'),
                    statusText: isPl
                        ? 'Na żywo (Live)'
                        : (isUk ? 'Наживо (Live)' : 'Live Feed'),
                    statusColor: const Color(0xFFEF4444),
                    isLiveBadge: true,
                    description: isPl
                        ? 'Obraz na żywo z kamer monitoringu miejskiego Krakowa i głównych węzłów przesiadkowych do bieżącej weryfikacji sytuacji na trasie.'
                        : (isUk
                              ? 'Трансляції наживо з міських камер відеоспостереження Кракова для оперативної перевірки прохідності маршруту.'
                              : 'Real-time city camera feeds and transit hub monitoring in Kraków for live obstacle verification.'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    isHighContrast: isHighContrast,
                  ),
                  const SizedBox(height: 12),

                  // 3. API Tramwajów i Autobusów (GTFS)
                  _buildSourceTile(
                    icon: Icons.tram,
                    iconColor: const Color(0xFF10B981),
                    title: isPl
                        ? 'Komunikacja Miejska (Tramwaje & Autobusy)'
                        : (isUk
                              ? 'Громадський транспорт (Трамваї & Автобуси)'
                              : 'Public Transit (Trams & Buses)'),
                    statusText: isPl
                        ? 'Na żywo (GTFS-RT)'
                        : (isUk ? 'Наживо (GTFS-RT)' : 'Live (GTFS-RT)'),
                    statusColor: const Color(0xFF10B981),
                    isLiveBadge: true,
                    description: isPl
                        ? 'Oficjalny Krakowski System Informacji Pasażerskiej (SIP MPK / ZTP) w formacie GTFS Realtime: rzeczywiste odjazdy, opóźnienia i status niskopodłogowości taboru.'
                        : (isUk
                              ? 'Офіційна інформаційна система пасажирів Кракова (SIP MPK / ZTP) у форматі GTFS Realtime: актуальні відправлення та низькопідлоговість.'
                              : 'Official Kraków Passenger Information System (SIP MPK / ZTP) in GTFS-RT format: live departures, delay tracking, and low-floor accessibility status.'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    isHighContrast: isHighContrast,
                  ),
                  const SizedBox(height: 12),

                  // 4. Siatka ulic i chodników
                  _buildSourceTile(
                    icon: Icons.map,
                    iconColor: const Color(0xFFF59E0B),
                    title: isPl
                        ? 'Siatka dróg i chodników'
                        : (isUk
                              ? 'Мережа доріг і тротуарів'
                              : 'Walkway & Street Network'),
                    statusText: 'OpenStreetMap',
                    statusColor: const Color(0xFFF59E0B),
                    description: isPl
                        ? 'Dane przestrzenne OpenStreetMap, OSRM oraz warstwy dostępności architektonicznej (obniżone krawężniki, rampy, nawierzchnia bez barier).'
                        : (isUk
                              ? 'Просторові дані OpenStreetMap, OSRM та шари архітектурної доступності (пандуси, пониження бордюрів).'
                              : 'OpenStreetMap spatial data, OSRM pedestrian routing engine, and architectural accessibility layers.'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    isHighContrast: isHighContrast,
                  ),
                  const SizedBox(height: 12),

                  // 5. Silnik audytu AI
                  _buildSourceTile(
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFF8B5CF6),
                    title: isPl
                        ? 'Silnik audytu wizyjnego AI'
                        : (isUk
                              ? 'Механізм візуального аудиту AI'
                              : 'AI Vision Audit Engine'),
                    statusText: 'Google Gemini 3.8 Flash',
                    statusColor: const Color(0xFF8B5CF6),
                    description: isPl
                        ? 'Wielomodalny model sztucznej inteligencji analizujący zdjęcia w celu natychmiastowej oceny dostępności dla wózków, seniorów i rodziców z dziećmi.'
                        : (isUk
                              ? 'Мультимодальна модель штучного інтелекту, що оцінює доступність інфраструктури для людей з інвалідністю.'
                              : 'Multimodal AI analyzing imagery to detect accessibility barriers for wheelchair users, seniors, and strollers.'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    isHighContrast: isHighContrast,
                  ),
                ],
              ),
            ),

            // Dolny przycisk zamykający
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: isHighContrast
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isPl ? 'Rozumiem' : (isUk ? 'Зрозуміло' : 'Got it'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildSourceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String statusText,
    required Color statusColor,
    required String description,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required bool isHighContrast,
    bool isLiveBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.transparent
                      : iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: isHighContrast
                      ? Border.all(color: iconColor, width: 1.5)
                      : null,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.black
                      : statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor,
                    width: isHighContrast ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLiveBadge) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isHighContrast ? Colors.white : statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
