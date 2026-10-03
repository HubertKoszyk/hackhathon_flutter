import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ReportObstacleDialog extends StatefulWidget {
  const ReportObstacleDialog({super.key});

  @override
  State<ReportObstacleDialog> createState() => _ReportObstacleDialogState();
}

class _ReportObstacleDialogState extends State<ReportObstacleDialog> {
  String _selectedBarrierType = 'schody';
  final TextEditingController _descController = TextEditingController();
  bool _isAnalyzingWithAI = false;
  bool _submitted = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    setState(() => _isAnalyzingWithAI = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _isAnalyzingWithAI = false;
        _submitted = true;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPL = state.language == 'pl';

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _submitted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 54),
                  const SizedBox(height: 14),
                  Text(
                    isPL ? 'Zgłoszenie przetworzone przez AI!' : 'Report Processed by AI!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPL
                        ? 'Punkt został uwzględniony w algorytmie omijania przeszkód dla Krakowa.'
                        : 'Hazard added to the real-time obstacle avoidance routing.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.camera_alt, color: Color(0xFFF59E0B), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPL ? 'Zgłoś barierę miejską' : 'Report Urban Barrier',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isPL ? 'Zero pracy dla urzędników (AI Audit)' : 'Zero city maintenance needed',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPL ? 'Typ przeszkody:' : 'Barrier Type:',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: isPL ? 'Schody bez rampy' : 'Stairs without ramp',
                        val: 'schody',
                      ),
                      _buildChip(
                        label: isPL ? 'Wysoki krawężnik' : 'High curb',
                        val: 'kraweznik',
                      ),
                      _buildChip(
                        label: isPL ? 'Zepsuta winda' : 'Broken elevator',
                        val: 'winda',
                      ),
                      _buildChip(
                        label: isPL ? 'Remont / Dziura' : 'Roadwork / Pothole',
                        val: 'remont',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isPL
                          ? 'Np. ul. Grodzka – roboty drogowe, brak przejścia...'
                          : 'E.g., Grodzka St. – roadworks, no wheelchair passage...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzingWithAI ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isAnalyzingWithAI
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        _isAnalyzingWithAI
                            ? (isPL ? 'Analiza AI w toku...' : 'AI Analyzing...')
                            : (isPL ? 'Wyślij i przeanalizuj AI' : 'Submit & Analyze with AI'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChip({required String label, required String val}) {
    final isSelected = _selectedBarrierType == val;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFF1E293B),
      onSelected: (_) => setState(() => _selectedBarrierType = val),
    );
  }
}
