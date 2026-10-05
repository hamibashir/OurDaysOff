import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/circles/providers/circles_notifier.dart';
import 'package:our_days_off/features/plans/data/plan_repository.dart';
import 'package:our_days_off/features/plans/models/plan_location_model.dart';
import 'package:our_days_off/features/plans/models/plan_member_model.dart';
import 'package:our_days_off/features/plans/models/plan_model.dart';
import 'package:our_days_off/features/plans/views/plans_screen.dart';
import 'package:our_days_off/features/plans/views/widgets/create_plan_bottom_sheet.dart';
import 'package:our_days_off/features/plans/views/widgets/plan_card_widget.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  List<CircleModel> mockCircles = [];

  @override
  Future<List<CircleModel>> getCircles() async => mockCircles;
}

class MockPlanRepository extends Fake implements PlanRepository {
  List<PlanModel> mockPlans = [];
  PlanModel? createdPlan;
  int? lastDeletedPlanId;
  String? lastRsvpStatus;
  int? lastRsvpPlanId;

  @override
  Future<List<PlanModel>> getPlans() async => mockPlans;

  @override
  Future<PlanModel> createPlan({
    required int circleId,
    required String title,
    String? description,
    required String eventType,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
  }) async {
    createdPlan = PlanModel(
      id: 999,
      circleId: circleId,
      createdBy: 1,
      title: title,
      description: description,
      eventType: eventType,
      startAt: startAt,
      endAt: endAt,
      status: status ?? 'confirmed',
    );
    return createdPlan!;
  }

  @override
  Future<PlanMemberModel> rsvp({
    required int planId,
    required String rsvpStatus,
  }) async {
    lastRsvpPlanId = planId;
    lastRsvpStatus = rsvpStatus;
    return PlanMemberModel(
      id: 1,
      planId: planId,
      userId: 1,
      rsvpStatus: rsvpStatus,
    );
  }

  @override
  Future<void> deletePlan(int id) async {
    lastDeletedPlanId = id;
  }
}

void main() {
  const testCircle = CircleModel(
    id: 1,
    ownerId: 1,
    name: 'Weekend Climbers',
    handle: 'climbers',
  );

  final testUpcomingPlan = PlanModel(
    id: 10,
    circleId: 1,
    createdBy: 1,
    title: 'Climbing at The Castle',
    description: 'Bouldering and lead session',
    eventType: 'social',
    status: 'confirmed',
    startAt: DateTime.now().add(const Duration(days: 2)),
    endAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
    circle: testCircle,
    members: const [
      PlanMemberModel(id: 1, planId: 10, userId: 1, rsvpStatus: 'attending'),
      PlanMemberModel(id: 2, planId: 10, userId: 2, rsvpStatus: 'tentative'),
    ],
    locations: const [
      PlanLocationModel(id: 1, planId: 10, name: 'The Castle Centre'),
    ],
    myRsvp: 'attending',
  );

  const testPollingPlan = PlanModel(
    id: 20,
    circleId: 1,
    createdBy: 1,
    title: 'Dinner Vote',
    eventType: 'meal',
    status: 'polling',
    startAt: null,
    endAt: null,
    circle: testCircle,
    myRsvp: 'pending',
  );

  final testPastPlan = PlanModel(
    id: 30,
    circleId: 1,
    createdBy: 1,
    title: 'Summer BBQ',
    eventType: 'social',
    status: 'completed',
    startAt: DateTime.now().subtract(const Duration(days: 10)),
    endAt: DateTime.now().subtract(const Duration(days: 10, hours: -3)),
    circle: testCircle,
    myRsvp: 'attending',
  );

  group('PlanCardWidget Tests', () {
    testWidgets('renders confirmed plan with title, circle, location and quick RSVP', (tester) async {
      PlanModel? tappedPlan;
      int? rsvpPlanId;
      String? rsvpValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanCardWidget(
              plan: testUpcomingPlan,
              onTap: (p) => tappedPlan = p,
              onRsvpChange: (id, rsvp) {
                rsvpPlanId = id;
                rsvpValue = rsvp;
              },
            ),
          ),
        ),
      );

      expect(find.text('Climbing at The Castle'), findsOneWidget);
      expect(find.text('Bouldering and lead session'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Weekend Climbers'), findsOneWidget);
      expect(find.text('SOCIAL'), findsOneWidget);
      expect(find.text('The Castle Centre'), findsOneWidget);
      expect(find.text('1 Going'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Climbing at The Castle'));
      await tester.pump();
      expect(tappedPlan?.id, 10);

      // Tap Maybe RSVP
      await tester.tap(find.text('Maybe'));
      await tester.pump();
      expect(rsvpPlanId, 10);
      expect(rsvpValue, 'tentative');

      // Tap Can't RSVP
      await tester.tap(find.text("Can't"));
      await tester.pump();
      expect(rsvpValue, 'declined');
    });

    testWidgets('renders polling plan with Date TBD indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlanCardWidget(
              plan: testPollingPlan,
            ),
          ),
        ),
      );

      expect(find.text('Dinner Vote'), findsOneWidget);
      expect(find.text('POLLING'), findsOneWidget);
      expect(find.text('Date TBD (Polling active)'), findsOneWidget);
    });
  });

  group('CreatePlanBottomSheet Tests', () {
    testWidgets('validates required title and creates plan on submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockCircleRepo = MockCircleRepository()..mockCircles = [testCircle];
      final mockPlanRepo = MockPlanRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockCircleRepo),
            planRepositoryProvider.overrideWithValue(mockPlanRepo),
            circlesNotifierProvider.overrideWith(
              (ref) => CirclesNotifier(mockCircleRepo),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreatePlanBottomSheet(
                circles: [testCircle],
                initialDate: '2026-10-20',
                initialStart: '19:00',
                initialEnd: '22:00',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Meetup Plan'), findsOneWidget);
      expect(find.text('TARGET CIRCLE'), findsOneWidget);
      expect(find.text('Weekend Climbers'), findsOneWidget);

      // Try submitting without title -> Validation error
      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Meetup Plan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.text('Title is required'), findsOneWidget);

      // Enter title
      await tester.enterText(find.byType(TextFormField).first, 'Taco Tuesday Feast');
      await tester.pump();

      // Submit form
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockPlanRepo.createdPlan, isNotNull);
      expect(mockPlanRepo.createdPlan?.title, 'Taco Tuesday Feast');
      expect(mockPlanRepo.createdPlan?.circleId, 1);
      expect(mockPlanRepo.createdPlan?.status, 'confirmed');
    });

    testWidgets('supports switching to polling mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockCircleRepo = MockCircleRepository()..mockCircles = [testCircle];
      final mockPlanRepo = MockPlanRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockCircleRepo),
            planRepositoryProvider.overrideWithValue(mockPlanRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreatePlanBottomSheet(
                circles: [testCircle],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Polling
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Date & Time pickers should no longer be rendered
      expect(find.text('START TIME'), findsNothing);

      // Enter title and submit
      await tester.enterText(find.byType(TextFormField).first, 'Open Poll for Friday');
      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Meetup Plan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockPlanRepo.createdPlan?.status, 'polling');
      expect(mockPlanRepo.createdPlan?.startAt, isNull);
    });
  });

  group('PlansScreen Tests', () {
    testWidgets('renders tabs and categorizes upcoming, polling, and past plans', (tester) async {
      final mockCircleRepo = MockCircleRepository()..mockCircles = [testCircle];
      final mockPlanRepo = MockPlanRepository()
        ..mockPlans = [testUpcomingPlan, testPollingPlan, testPastPlan];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockCircleRepo),
            planRepositoryProvider.overrideWithValue(mockPlanRepo),
          ],
          child: const MaterialApp(
            home: PlansScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab badges
      expect(find.text('Upcoming (1)'), findsOneWidget);
      expect(find.text('Polling (1)'), findsOneWidget);
      expect(find.text('Past (1)'), findsOneWidget);

      // Upcoming Tab content
      expect(find.text('Climbing at The Castle'), findsOneWidget);

      // Switch to Polling tab
      await tester.tap(find.text('Polling (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Dinner Vote'), findsOneWidget);

      // Switch to Past tab
      await tester.tap(find.text('Past (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Summer BBQ'), findsOneWidget);
    });

    testWidgets('renders empty state when tab has no plans', (tester) async {
      final mockCircleRepo = MockCircleRepository()..mockCircles = [testCircle];
      final mockPlanRepo = MockPlanRepository()..mockPlans = []; // No plans

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockCircleRepo),
            planRepositoryProvider.overrideWithValue(mockPlanRepo),
          ],
          child: const MaterialApp(
            home: PlansScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Meetups'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Create Meetup Plan'), findsOneWidget);
    });
  });
}
