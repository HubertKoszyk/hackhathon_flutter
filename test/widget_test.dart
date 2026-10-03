import 'package:flutter_test/flutter_test.dart';
import 'package:hackhathon_flutter/main.dart';
import 'package:provider/provider.dart';
import 'package:hackhathon_flutter/providers/app_state.dart';

void main() {
  testWidgets('KrakAccess app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const KrakAccessApp(),
      ),
    );

    expect(find.text('KrakAccess'), findsOneWidget);
  });
}
