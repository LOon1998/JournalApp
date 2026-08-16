import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/main.dart';

void main() {
  testWidgets('Moodlet app boots to the Today tab', (WidgetTester tester) async {
    await tester.pumpWidget(const LuminaApp());
    await tester.pumpAndSettle();

    expect(find.text('Moodlet'), findsWidgets);
    expect(find.text('How are you feeling today?'), findsOneWidget);
  });
}
