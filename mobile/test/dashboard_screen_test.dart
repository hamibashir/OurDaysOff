import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_notifier.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/circles/providers/circles_notifier.dart';
import 'package:our_days_off/features/circles/providers/circles_state.dart';
import 'package:our_days_off/features/dashboard/views/dashboard_screen.dart';
import 'package:our_days_off/features/plans/models/plan_model.dart';
import 'package:our_days_off/features/plans/providers/plan_providers.dart';
import 'package:our_days_off/features/schedule/models/schedule_entry.dart';
import 'package:our_days_off/features/schedule/providers/schedule_notifier.dart';
import 'package:our_days_off/features/schedule/providers/schedule_state.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockScheduleNotifier extends StateNotifier<ScheduleState> implements ScheduleNotifier {
  MockScheduleNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCirclesNotifier extends StateNotifier<CirclesState> implements CirclesNotifier {
  MockCirclesNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DashboardScreen Enhancement & Optimization Tests', () {
    testWidgets('Dashboard renders personalized greeting, metrics, and quick actions', (WidgetTester tester) async {
      const testUser = UserModel(
        id: 1,
        name: 'Hamza Bashir',
        email: 'hamza@example.com',
        handle: 'hamza',
        isPremium: true,
      );

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final mockEntries = <DateTime, List<ScheduleEntry>>{
        todayMidnight: [
          ScheduleEntry(
            id: 101,
            userId: 1,
            date: todayMidnight,
            startTime: '08:00',
            endTime: '16:30',
            entryType: 'work',
            label: 'Day Shift',
          ),
        ],
      };

      final scheduleState = ScheduleState(
        selectedDate: todayMidnight,
        focusedMonth: todayMidnight,
        entries: mockEntries,
        templates: const [],
        isLoading: false,
      );

      final mockCircles = [
        const CircleModel(
          id: 1,
          ownerId: 1,
          name: 'Weekend Travelers',
          membersCount: 4,
          myVisibility: 'free_busy',
        ),
      ];

      final circlesState = CirclesState(
        circles: mockCircles,
        status: CirclesStatus.loaded,
      );

      final mockPlans = [
        PlanModel(
          id: 50,
          circleId: 1,
          createdBy: 1,
          title: 'Sunday Brunch Meetup',
          startAt: now.add(const Duration(days: 2)),
          status: 'confirmed',
          circle: mockCircles.first,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => MockAuthNotifier(AuthState.authenticated(testUser)),
            ),
            scheduleNotifierProvider.overrideWith(
              (ref) => MockScheduleNotifier(scheduleState),
            ),
            circlesNotifierProvider.overrideWith(
              (ref) => MockCirclesNotifier(circlesState),
            ),
            plansListProvider.overrideWith(
              () => _TestPlansNotifier(mockPlans),
            ),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify personalized hero card
      expect(find.text('Welcome back, Hamza 👋'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('AI Rota Scanner & Import'), findsOneWidget);

      // 2. Verify quick action buttons
      expect(find.text('Import Rota'), findsOneWidget);
      expect(find.text('Log Shift'), findsOneWidget);
      expect(find.text('Roster'), findsOneWidget);
      expect(find.text('New Plan'), findsOneWidget);

      // 3. Verify next shift spotlight banner
      expect(find.textContaining('Upcoming Shift: Day Shift'), findsOneWidget);

      // 4. Verify metrics overview
      expect(find.text('FREE DAYS'), findsOneWidget);
      expect(find.text('CIRCLES'), findsOneWidget);
      expect(find.text('ACTIVE PLANS'), findsOneWidget);
      expect(find.text('LOGGED SHIFTS'), findsOneWidget);

      // 5. Verify 14-day timeline preview
      expect(find.text('14-DAY AVAILABILITY PREVIEW'), findsOneWidget);

      // 6. Verify plans preview
      expect(find.text('Sunday Brunch Meetup'), findsOneWidget);

      // 7. Verify circles preview
      expect(find.text('Weekend Travelers'), findsOneWidget);

      // 8. Verify privacy reassurance
      expect(find.text('Zero-Knowledge Privacy'), findsOneWidget);
    });
  });
}

class _TestPlansNotifier extends PlansListNotifier {
  final List<PlanModel> initialPlans;

  _TestPlansNotifier(this.initialPlans);

  @override
  Future<List<PlanModel>> build() async => initialPlans;
}
