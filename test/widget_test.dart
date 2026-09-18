import 'package:flutter_test/flutter_test.dart';
import 'package:maijek_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: '/login'));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
