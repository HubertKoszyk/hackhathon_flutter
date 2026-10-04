import 'package:flutter/material.dart';
import 'package:hackhathon_flutter/theme.dart';
import 'package:hackhathon_flutter/widgets/scrollable_bottom_sheet.dart';
import 'package:hackhathon_flutter/widgets/top_gradient_bar.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'widgets/accessible_place_sheet.dart';
import 'widgets/app_tutorial_modal.dart';
import 'widgets/audit_modal.dart';
import 'widgets/live_navigation_overlay.dart';
import 'widgets/map_view.dart';
import 'widgets/parking_details_sheet.dart';
import 'widgets/report_obstacle_dialog.dart';
import 'widgets/route_result_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KrakAccessApp(),
    ),
  );
}

class KrakAccessApp extends StatelessWidget {
  const KrakAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavAble',
      debugShowCheckedModeBanner: false,
      theme: materialLightTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _checkedTutorial = false;

  void _checkFirstLaunchTutorial() {
    if (_checkedTutorial) return;
    final state = context.read<AppState>();
    if (state.shouldShowTutorial) {
      _checkedTutorial = true;
      state.dismissTutorialFlag();
      AppTutorialModal.show(context, isFirstLaunch: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Sprawdź czy pokazać samouczek powitalny
    if (state.shouldShowTutorial && !_checkedTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkFirstLaunchTutorial();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Podkład mapy Krakowa z trasami i parkingami
          const Positioned.fill(child: KrakMapView()),

          // 2. TRYB NAWIGACJI NA ŻYWO (Google Maps Turn-by-Turn Live HUD)
          if (state.isNavigating)
            const Positioned.fill(child: LiveNavigationOverlay()),

          // 3. TRYB PRZEGLĄDANIA I PLANOWANIA TRASY (Gdy nawigacja nie jest aktywna)
          if (!state.isNavigating) ...[
            // Górny pasek nawigacji i wyboru profilu
            // const Positioned(top: 0, left: 0, right: 0, child: TopBar()),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopGradientBar(),
            ),

            // Pływający przycisk mojej lokalizacji GPS
            // Positioned(
            //   right: 16,
            //   bottom: state.selectedParking != null ? 280 : 375,
            //   child: FloatingActionButton.small(
            //     heroTag: 'my_gps_btn',
            //     backgroundColor: const Color(0xFF1E293B),
            //     foregroundColor: const Color(0xFF38BDF8),
            //     tooltip: 'Moja lokalizacja GPS',
            //     elevation: 4,
            //     onPressed: state.useCurrentLocationAsStart,
            //     child: state.isLocatingUser
            //         ? const SizedBox(
            //             width: 16,
            //             height: 16,
            //             child: CircularProgressIndicator(
            //               strokeWidth: 2,
            //               color: Color(0xFF38BDF8),
            //             ),
            //           )
            //         : const Icon(Icons.my_location),
            //   ),
            // ),

            // Dolny panel: Karta parkingu LUB Karta obiektu/hotelu LUB Ekran wyników LUB Wyszukiwarka
            if (state.selectedParking != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: ParkingDetailsSheet(spot: state.selectedParking!),
                ),
              )
            else if (state.selectedAccessiblePlace != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: AccessiblePlaceSheet(place: state.selectedAccessiblePlace!),
                ),
              )
            else if (state.routes.isNotEmpty)
              // Nowy ekran po wyszukaniu trasy: wszystko inne się usuwa
              const Positioned.fill(
                child: RouteResultSheet(),
              )
            else ...[
              // Pływający przycisk zgłaszania przeszkód ("Crowdsourced AI")
              if (!state.isAnalyzingRoute)
                Positioned(
                  right: 16,
                  bottom: 315,
                  child: FloatingActionButton(
                    heroTag: 'report_barrier_btn',
                    backgroundColor: kColorScheme.primary,
                    foregroundColor: Colors.white,
                    tooltip: state.tr('report_obstacle'),
                    elevation: 4,
                    child: const Icon(Icons.add_a_photo_outlined),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const ReportObstacleDialog(),
                      );
                    },
                  ),
                ),

              const CustomStickySheet(),
            ],
          ],

          // 5. Modal audytu AI Street View (jeśli aktywny)
          if (state.activeAudit != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: state.closeAudit,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {}, // Zapobiega zamknięciu przy kliknięciu w treść modala
                    child: AuditModal(audit: state.activeAudit!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
