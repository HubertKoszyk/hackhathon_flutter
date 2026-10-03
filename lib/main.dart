import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'widgets/audit_modal.dart';
import 'widgets/map_view.dart';
import 'widgets/parking_details_sheet.dart';
import 'widgets/report_obstacle_dialog.dart';
import 'widgets/route_card.dart';
import 'widgets/top_bar.dart';

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
      title: 'KrakAccess - Dostępny Kraków',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // Emerald
          secondary: Color(0xFF0284C7), // Sky Blue
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Podkład mapy Krakowa z trasami i parkingami
          const Positioned.fill(
            child: KrakMapView(),
          ),

          // 2. Górny pasek nawigacji i wyboru profilu
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(),
          ),

          // 3. Pływający przycisk zgłaszania przeszkód ("Crowdsourced AI")
          Positioned(
            right: 16,
            bottom: state.selectedParking != null ? 220 : 260,
            child: FloatingActionButton(
              heroTag: 'report_barrier_btn',
              backgroundColor: const Color(0xFF0284C7),
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

          // 4. Dolny panel: Karta parkingu LUB Karta trasy
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: state.selectedParking != null
                  ? ParkingDetailsSheet(spot: state.selectedParking!)
                  : const RouteCard(),
            ),
          ),

          // 5. Modal audytu AI Street View (jeśli aktywny)
          if (state.activeAudit != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: AuditModal(audit: state.activeAudit!),
              ),
            ),
        ],
      ),
    );
  }
}
