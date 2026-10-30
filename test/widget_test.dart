import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spicci/main.dart';

void main() {
  testWidgets('SpicciApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SpicciApp(),
      ),
    );

    // Verifica che il titolo dell'app sia presente
    expect(find.text('Spicci'), findsOneWidget);
  });
}
