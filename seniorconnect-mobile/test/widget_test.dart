import 'package:flutter_test/flutter_test.dart';
import 'package:seniorconnect_mobile/main.dart';

void main() {
  testWidgets('SeniorConnectApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SeniorConnectApp());
    expect(find.byType(SeniorConnectApp), findsOneWidget);
  });
}
