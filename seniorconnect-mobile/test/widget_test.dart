import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniorconnect_mobile/core/theme/app_theme.dart';
import 'package:seniorconnect_mobile/features/auth/screens/role_selection_screen.dart';

void main() {
  testWidgets('SeniorConnectApp initial screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const RoleSelectionScreen(),
      ),
    );
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.text('Welcome to SeniorConnect'), findsOneWidget);
  });
}
