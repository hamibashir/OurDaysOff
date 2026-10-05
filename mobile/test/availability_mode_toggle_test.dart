import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/matching/data/matching_repository.dart';
import 'package:our_days_off/features/matching/models/availability_mode.dart';
import 'package:our_days_off/features/matching/models/circle_availability_data.dart';
import 'package:our_days_off/features/matching/models/circle_roster_member.dart';
import 'package:our_days_off/features/matching/models/days_off_summary.dart';
import 'package:our_days_off/features/matching/models/member_daily_status.dart';
import 'package:our_days_off/features/matching/models/off_time_summary.dart';
import 'package:our_days_off/features/matching/models/roster_user_summary.dart';
import 'package:our_days_off/features/matching/providers/matching_grid_notifier.dart';
import 'package:our_days_off/features/matching/views/widgets/availability_mode_toggle.dart';
import 'package:our_days_off/features/matching/views/widgets/date_overlap_breakdown_sheet.dart';
import 'package:our_days_off/features/matching/views/widgets/mode_summary_highlight_card.dart';
import 'package:our_days_off/features/matching/views/widgets/rota_grid_matrix.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  List<CircleModel> mockCircles = [];

  @override
  Future<List<CircleModel>> getCircles() async => mockCircles;
}

class MockMatchingRepository extends Fake implements MatchingRepository {
  late CircleAvailabilityData mockAvailability;

  @override
  Future<CircleAvailabilityData> getCircleAvailability({
    required int circleId,
    required String startDate,
    required String endDate,
  }) async =>
      mockAvailability;
}

void main() {
  const testMemberAlice = CircleRosterMember(
    user: RosterUserSummary(id: 1, name: 'Alice Smith', handle: 'alice', initials: 'AS'),
    visibility: 'shifts',
    dailyStatus: {
      '2026-10-12': MemberDailyStatus(
        status: 'work',
        label: 'Day Shift',
        shortCode: '08–16',
        isDayOff: false,
        startTime: '08:00',
        endTime: '16:00',
      ),
      '2026-10-13': MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
      ),
    },
  );

  const testMemberBob = CircleRosterMember(
    user: RosterUserSummary(id: 2, name: 'Bob Jones', handle: 'bob', initials: 'BJ'),
    visibility: 'free_busy',
    dailyStatus: {
      '2026-10-12': MemberDailyStatus(
        status: 'work',
        label: 'Evening Shift',
        shortCode: '14–22',
        isDayOff: false,
        startTime: '14:00',
        endTime: '22:00',
      ),
      '2026-10-13': MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
      ),
    },
  );

  const testDaysOff = {
    '2026-10-12': DaysOffDateSummary(
      freeCount: 0,
      totalCount: 2,
      allFree: false,
      workingMembers: [
        RosterUserSummary(id: 1, name: 'Alice Smith', handle: 'alice', initials: 'AS'),
        RosterUserSummary(id: 2, name: 'Bob Jones', handle: 'bob', initials: 'BJ'),
      ],
    ),
    '2026-10-13': DaysOffDateSummary(
      freeCount: 2,
      totalCount: 2,
      allFree: true,
      freeMembers: [
        RosterUserSummary(id: 1, name: 'Alice Smith', handle: 'alice', initials: 'AS'),
        RosterUserSummary(id: 2, name: 'Bob Jones', handle: 'bob', initials: 'BJ'),
      ],
    ),
  };

  const testOffTime = {
    '2026-10-12': OffTimeDateSummary(
      bestWindow: BestWindow(
        start: '22:00',
        end: '24:00',
        durationMinutes: 120,
        durationFormatted: '2.0 hrs',
      ),
      hasOverlap: true,
      freeCount: 2,
      totalCount: 2,
      allFree: true,
      commonIntervals: [
        {'start': '22:00', 'end': '24:00'}
      ],
    ),
    '2026-10-13': OffTimeDateSummary(
      bestWindow: BestWindow(
        start: '00:00',
        end: '24:00',
        durationMinutes: 1440,
        durationFormatted: '24.0 hrs',
      ),
      hasOverlap: true,
      freeCount: 2,
      totalCount: 2,
      allFree: true,
      commonIntervals: [
        {'start': '00:00', 'end': '24:00'}
      ],
    ),
  };

  const testAvailability = CircleAvailabilityData(
    members: [testMemberAlice, testMemberBob],
    commonAvailability: {},
    offTime: testOffTime,
    daysOff: testDaysOff,
    suggestions: [],
    plans: [],
  );

  group('AvailabilityMode Enum Tests', () {
    test('properties return appropriate labels and icons', () {
      expect(AvailabilityMode.daysOff.label, 'Days Off');
      expect(AvailabilityMode.daysOff.icon, LucideIcons.calendarCheck);
      expect(AvailabilityMode.daysOff.description, contains('Full days'));

      expect(AvailabilityMode.offTime.label, 'Off Time');
      expect(AvailabilityMode.offTime.icon, LucideIcons.clock);
      expect(AvailabilityMode.offTime.description, contains('Overlapping free hours'));
    });
  });

  group('MatchingGridNotifier Mode Tests', () {
    late MockCircleRepository mockCircleRepo;
    late MockMatchingRepository mockMatchingRepo;

    setUp(() {
      mockCircleRepo = MockCircleRepository();
      mockMatchingRepo = MockMatchingRepository();
      mockMatchingRepo.mockAvailability = testAvailability;
    });

    test('notifier defaults to daysOff mode and toggles seamlessly', () {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      expect(notifier.state.mode, AvailabilityMode.daysOff);

      notifier.setMode(AvailabilityMode.offTime);
      expect(notifier.state.mode, AvailabilityMode.offTime);

      notifier.setMode(AvailabilityMode.daysOff);
      expect(notifier.state.mode, AvailabilityMode.daysOff);
    });
  });

  group('AvailabilityModeToggle Widget Tests', () {
    testWidgets('renders both mode options and calls callback on select', (tester) async {
      AvailabilityMode selectedMode = AvailabilityMode.daysOff;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AvailabilityModeToggle(
                  currentMode: selectedMode,
                  onModeChanged: (mode) {
                    setState(() {
                      selectedMode = mode;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Days Off'), findsOneWidget);
      expect(find.text('Off Time'), findsOneWidget);

      // Tap Off Time
      await tester.tap(find.text('Off Time'));
      await tester.pumpAndSettle();

      expect(selectedMode, AvailabilityMode.offTime);
    });
  });

  group('ModeSummaryHighlightCard Widget Tests', () {
    testWidgets('renders Days Off highlights with ALL OFF badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModeSummaryHighlightCard(
              mode: AvailabilityMode.daysOff,
              daysOffSummary: testDaysOff,
              offTimeSummary: testOffTime,
              members: [testMemberAlice, testMemberBob],
            ),
          ),
        ),
      );

      expect(find.text('Top Days Off'), findsOneWidget);
      expect(find.text('ALL OFF'), findsOneWidget);
      expect(find.text('2 free'), findsOneWidget);
    });

    testWidgets('renders Off Time highlights with best window duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModeSummaryHighlightCard(
              mode: AvailabilityMode.offTime,
              daysOffSummary: testDaysOff,
              offTimeSummary: testOffTime,
              members: [testMemberAlice, testMemberBob],
            ),
          ),
        ),
      );

      expect(find.text('Top Overlapping Shift Windows'), findsOneWidget);
      expect(find.text('24.0 hrs'), findsOneWidget);
      expect(find.text('00:00 — 24:00'), findsOneWidget);
    });
  });

  group('DateOverlapBreakdownSheet Widget Tests', () {
    testWidgets('renders Days Off breakdown with confirmed members and working members', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateOverlapBreakdownSheet(
              dateStr: '2026-10-13',
              mode: AvailabilityMode.daysOff,
              daysOffSummary: testDaysOff['2026-10-13'],
              offTimeSummary: testOffTime['2026-10-13'],
              members: const [testMemberAlice, testMemberBob],
            ),
          ),
        ),
      );

      expect(find.text('Full Days Off Breakdown'), findsOneWidget);
      expect(find.textContaining('100% Shared Day Off'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('OFF WORK TODAY'), findsOneWidget);
    });

    testWidgets('renders Off Time breakdown with best window and common intervals', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateOverlapBreakdownSheet(
              dateStr: '2026-10-12',
              mode: AvailabilityMode.offTime,
              daysOffSummary: testDaysOff['2026-10-12'],
              offTimeSummary: testOffTime['2026-10-12'],
              members: const [testMemberAlice, testMemberBob],
            ),
          ),
        ),
      );

      expect(find.text('Overlapping Off Time Breakdown'), findsOneWidget);
      expect(find.text('Best Overlap Window'), findsOneWidget);
      expect(find.text('22:00 — 24:00'), findsOneWidget);
      expect(find.text('2.0 hrs'), findsOneWidget);
      expect(find.text('COMMON FREE TIME BLOCKS'), findsOneWidget);
      expect(find.text('22:00 – 24:00'), findsOneWidget);
    });
  });

  group('RotaGridMatrix Dynamic Mode Header Tests', () {
    testWidgets('renders ALL OFF in daysOff mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RotaGridMatrix(
                members: [testMemberAlice, testMemberBob],
                mode: AvailabilityMode.daysOff,
                daysOffSummary: testDaysOff,
                offTimeSummary: testOffTime,
                customDates: ['2026-10-13'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('ALL OFF'), findsOneWidget);
    });

    testWidgets('renders best window in offTime mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RotaGridMatrix(
                members: [testMemberAlice, testMemberBob],
                mode: AvailabilityMode.offTime,
                daysOffSummary: testDaysOff,
                offTimeSummary: testOffTime,
                customDates: ['2026-10-12'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('22:00–24:00'), findsOneWidget);
    });
  });
}
