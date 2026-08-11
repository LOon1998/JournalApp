import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/main.dart';

void main() {
  testWidgets('Lumina app boots to the Today tab', (WidgetTester tester) async {
    await tester.pumpWidget(const LuminaApp());
    await tester.pumpAndSettle();

    expect(find.text('Lumina'), findsWidgets);
    expect(find.text('How are you feeling today?'), findsOneWidget);
  });
}
