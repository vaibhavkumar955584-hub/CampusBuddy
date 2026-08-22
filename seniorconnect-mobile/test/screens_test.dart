import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniorconnect_mobile/core/theme/app_theme.dart';
import 'package:seniorconnect_mobile/features/matching/screens/matched_queries_screen.dart';
import 'package:seniorconnect_mobile/features/moderation/widgets/report_modal.dart';
import 'package:seniorconnect_mobile/features/notifications/screens/notifications_screen.dart';
import 'package:seniorconnect_mobile/features/profile/screens/points_badges_screen.dart';

void main() {
  group('Gap 5 Mobile UI Screens and Components Verification', () {
    testWidgets('1. MatchedQueriesScreen renders title and match feed layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MatchedQueriesScreen(),
        ),
      );

      expect(find.text('Matched Queries'), findsOneWidget);
      expect(find.text('Questions matching your skills and branch'), findsOneWidget);
    });

    testWidgets('2. NotificationsScreen renders grouped notification layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('3. PointsBadgesScreen renders gamification points & badges cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PointsBadgesScreen(),
        ),
      );

      expect(find.text('Points & Badges'), findsOneWidget);
    });

    testWidgets('4. ReportModal renders reason selection and submit button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ReportModal(
              targetType: 'QUERY',
              targetId: 'q-123',
              reportedUserId: 'u-456',
              targetTitle: 'Question on DSA preparation',
            ),
          ),
        ),
      );

      expect(find.text('Report Question'), findsOneWidget);
      expect(find.text('Select Reason'), findsOneWidget);
      expect(find.text('Harassment / Bullying / Hate Speech'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
    });
  });
}
