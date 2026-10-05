import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/matching/data/matching_repository.dart';
import 'package:our_days_off/features/matching/models/circle_availability_data.dart';
import 'package:our_days_off/features/matching/models/circle_roster_member.dart';
import 'package:our_days_off/features/matching/models/match_suggestion.dart';
import 'package:our_days_off/features/matching/models/roster_user_summary.dart';
import 'package:our_days_off/features/matching/providers/matching_grid_notifier.dart';
import 'package:our_days_off/features/matching/views/widgets/personal_compare_tool.dart';
import 'package:our_days_off/features/matching/views/widgets/suggested_times_card.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  List<CircleModel> mockCircles = [];

  @override
  Future<List<CircleModel>> getCircles() async => mockCircles;
}

class MockMatchingRepository extends Fake implements MatchingRepository {
  late CircleAvailabilityData mockAvailability;
  late CircleAvailabilityData mockCompareAvailability;
  List<int>? lastCompareUserIds;
  int getCircleAvailabilityCalls = 0;
  int compareUsersCalls = 0;

  @override
  Future<CircleAvailabilityData> getCircleAvailability({
    required int circleId,
    required String startDate,
    required String endDate,
  }) async {
    getCircleAvailabilityCalls++;
    return mockAvailability;
  }

  @override
  Future<CircleAvailabilityData> compareUsers({
    required List<int> userIds,
    required String startDate,
    required String endDate,
    int? circleId,
  }) async {
    compareUsersCalls++;
    lastCompareUserIds = userIds;
    return mockCompareAvailability;
  }
}

void main() {
  const testMemberAlice = CircleRosterMember(
    user: RosterUserSummary(id: 1, name: 'Alice Smith', handle: 'alice', initials: 'AS'),
    visibility: 'shifts',
  );

  const testMemberBob = CircleRosterMember(
    user: RosterUserSummary(id: 2, name: 'Bob Jones', handle: 'bob', initials: 'BJ'),
    visibility: 'free_busy',
  );

  const testMemberCharlie = CircleRosterMember(
    user: RosterUserSummary(id: 3, name: 'Charlie Day', handle: 'charlie', initials: 'CD'),
    visibility: 'shifts',
  );

  const testSuggestion1 = MatchSuggestion(
    date: '2026-10-14',
    start: '18:00',
    end: '22:00',
    durationHours: 4.0,
    score: 80.0,
    reasons: ['Ideal for dinner/evening meetup', 'All members available'],
    isMagicHour: true,
  );

  const testSuggestion2 = MatchSuggestion(
    date: '2026-10-15',
    start: '12:00',
    end: '14:00',
    durationHours: 2.0,
    score: 50.0,
    reasons: ['Perfect for lunch'],
    isMagicHour: false,
  );

  const testAvailability = CircleAvailabilityData(
    members: [testMemberAlice, testMemberBob, testMemberCharlie],
    commonAvailability: {},
    offTime: {},
    daysOff: {},
    suggestions: [testSuggestion1, testSuggestion2],
    plans: [],
  );

  final testCircle = CircleModel(
    id: 101,
    ownerId: 1,
    name: 'Weekend Climbers',
    handle: 'climbers',
    membersCount: 3,
    myRole: 'owner',
    myVisibility: 'shifts',
    createdAt: DateTime(2026, 1, 1),
  );

  group('MatchSuggestion Model Enhancements', () {
    test('parses and serializes reasons and isMagicHour', () {
      final json = {
        'date': '2026-10-14',
        'start': '18:00',
        'end': '22:00',
        'duration_hours': 4.0,
        'score': 80.0,
        'reasons': ['Ideal for dinner/evening meetup', 'All members available'],
        'is_magic_hour': true,
      };

      final suggestion = MatchSuggestion.fromJson(json);

      expect(suggestion.date, '2026-10-14');
      expect(suggestion.start, '18:00');
      expect(suggestion.end, '22:00');
      expect(suggestion.durationHours, 4.0);
      expect(suggestion.score, 80.0);
      expect(suggestion.isMagicHour, isTrue);
      expect(suggestion.reasons.length, 2);
      expect(suggestion.reasons.first, 'Ideal for dinner/evening meetup');

      final serialized = suggestion.toJson();
      expect(serialized['is_magic_hour'], isTrue);
      expect(serialized['reasons'], contains('All members available'));
    });
  });

  group('MatchingGridNotifier 1-on-1 & Custom Compare Tests', () {
    late MockCircleRepository mockCircleRepo;
    late MockMatchingRepository mockMatchingRepo;

    setUp(() {
      mockCircleRepo = MockCircleRepository();
      mockMatchingRepo = MockMatchingRepository();
      mockCircleRepo.mockCircles = [testCircle];
      mockMatchingRepo.mockAvailability = testAvailability;
      mockMatchingRepo.mockCompareAvailability = const CircleAvailabilityData(
        members: [testMemberAlice, testMemberBob],
        suggestions: [testSuggestion1],
      );
    });

    test('member selection toggling works properly', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();

      expect(notifier.state.selectedMemberIds, [1, 2, 3]);

      notifier.toggleMember(3);
      expect(notifier.state.selectedMemberIds, [1, 2]);

      notifier.toggleMember(3);
      expect(notifier.state.selectedMemberIds, [1, 2, 3]);

      notifier.deselectAllMembers();
      expect(notifier.state.selectedMemberIds, isEmpty);

      notifier.selectAllMembers();
      expect(notifier.state.selectedMemberIds, [1, 2, 3]);
    });

    test('runCustomCompare calls compareUsers with selected user IDs', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();

      notifier.toggleMember(3); // Keep only 1 and 2
      await notifier.runCustomCompare();

      expect(mockMatchingRepo.compareUsersCalls, 1);
      expect(mockMatchingRepo.lastCompareUserIds, [1, 2]);
      expect(notifier.state.isCustomCompare, isTrue);
      expect(notifier.state.availabilityData?.members.length, 2);
    });

    test('runCustomCompare blocks if fewer than 2 members selected', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();
      notifier.deselectAllMembers();
      notifier.toggleMember(1); // Only 1 member selected

      await notifier.runCustomCompare();

      expect(mockMatchingRepo.compareUsersCalls, 0);
      expect(notifier.state.errorMessage, contains('Select at least 2 members'));
    });

    test('resetToFullCircle resets custom compare flag and refetches full circle', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();
      notifier.toggleMember(3);
      await notifier.runCustomCompare();
      expect(notifier.state.isCustomCompare, isTrue);

      await notifier.resetToFullCircle();
      expect(notifier.state.isCustomCompare, isFalse);
      expect(mockMatchingRepo.getCircleAvailabilityCalls, 2);
    });
  });

  group('SuggestedTimesCard Widget Tests', () {
    testWidgets('renders suggestions with Magic Hour badges and reasons', (tester) async {
      MatchSuggestion? proposed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SuggestedTimesCard(
                suggestions: const [testSuggestion1, testSuggestion2],
                onProposePlan: (s) => proposed = s,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ranked Meet Suggestions'), findsOneWidget);
      expect(find.text('Magic Hour'), findsOneWidget);
      expect(find.text('18:00 — 22:00'), findsOneWidget);
      expect(find.text('(4.0 hrs)'), findsOneWidget);
      expect(find.text('Ideal for dinner/evening meetup'), findsOneWidget);
      expect(find.text('Perfect for lunch'), findsOneWidget);

      // Tap Propose Plan
      final proposeBtn = find.text('Propose Plan').first;
      await tester.tap(proposeBtn);
      await tester.pump();

      expect(proposed?.date, '2026-10-14');
      expect(proposed?.start, '18:00');
    });

    testWidgets('renders empty placeholder when suggestions list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuggestedTimesCard(suggestions: []),
          ),
        ),
      );

      expect(find.text('No overlapping meetup windows found for the selected dates.'), findsOneWidget);
    });
  });

  group('PersonalCompareTool Widget Tests', () {
    testWidgets('renders member chips and triggers callbacks', (tester) async {
      int? toggledId;
      bool selectAllCalled = false;
      bool deselectAllCalled = false;
      bool recalculateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalCompareTool(
                availableMembers: const [testMemberAlice, testMemberBob, testMemberCharlie],
                selectedUserIds: const [1, 2],
                onToggleUser: (id) => toggledId = id,
                onSelectAll: () => selectAllCalled = true,
                onDeselectAll: () => deselectAllCalled = true,
                onRunCompare: () => recalculateCalled = true,
                circleName: 'Weekend Climbers',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Compare: Weekend Climbers'), findsOneWidget);
      expect(find.text('2 of 3 Active'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Charlie Day'), findsOneWidget);

      // Tap Charlie to toggle
      await tester.tap(find.text('Charlie Day'));
      await tester.pump();
      expect(toggledId, 3);

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pump();
      expect(selectAllCalled, isTrue);

      // Tap Recalculate Match
      await tester.tap(find.text('Recalculate Match'));
      await tester.pump();
      expect(recalculateCalled, isTrue);

      // Now with all selected to test Clear Selection
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalCompareTool(
                availableMembers: const [testMemberAlice, testMemberBob, testMemberCharlie],
                selectedUserIds: const [1, 2, 3],
                onToggleUser: (id) => toggledId = id,
                onSelectAll: () => selectAllCalled = true,
                onDeselectAll: () => deselectAllCalled = true,
                onRunCompare: () => recalculateCalled = true,
                circleName: 'Weekend Climbers',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Deselect All'), findsOneWidget);
      await tester.tap(find.text('Deselect All'));
      await tester.pump();
      expect(deselectAllCalled, isTrue);
    });

    testWidgets('shows warning and disables recalculate when fewer than 2 members selected', (tester) async {
      bool recalculateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalCompareTool(
                availableMembers: const [testMemberAlice, testMemberBob],
                selectedUserIds: const [1], // Only 1 member
                onToggleUser: (_) {},
                onSelectAll: () {},
                onDeselectAll: () {},
                onRunCompare: () => recalculateCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select at least 2 members to calculate common free time.'), findsOneWidget);

      // Try tapping recalculate
      await tester.tap(find.text('Recalculate Match'));
      await tester.pump();
      expect(recalculateCalled, isFalse);
    });

    testWidgets('shows Reset button when isCustomCompare is true', (tester) async {
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalCompareTool(
                availableMembers: const [testMemberAlice, testMemberBob],
                selectedUserIds: const [1, 2],
                isCustomCompare: true,
                onToggleUser: (_) {},
                onSelectAll: () {},
                onDeselectAll: () {},
                onRunCompare: () {},
                onResetToCircle: () => resetCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(resetCalled, isTrue);
    });
  });
}
