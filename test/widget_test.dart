import 'package:flutter_test/flutter_test.dart';
import 'package:agua/main.dart';

void main() {
  testWidgets('La app inicia', (WidgetTester tester) async {
    await tester.pumpWidget(const MiApp());
    expect(find.byType(MiApp), findsOneWidget);
  });
}