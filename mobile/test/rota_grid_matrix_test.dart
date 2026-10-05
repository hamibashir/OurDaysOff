import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/matching/data/matching_repository.dart';
import 'package:our_days_off/features/matching/models/circle_availability_data.dart';
import 'package:our_days_off/features/matching/models/circle_roster_member.dart';
import 'package:our_days_off/features/matching/models/days_off_summary.dart';
import 'package:our_days_off/features/matching/models/member_daily_status.dart';
import 'package:our_days_off/features/matching/models/roster_user_summary.dart';
import 'package:our_days_off/features/matching/providers/matching_grid_notifier.dart';
import 'package:our_days_off/features/matching/views/widgets/member_cell_detail_sheet.dart';
import 'package:our_days_off/features/matching/views/widgets/rota_grid_cell.dart';
import 'package:our_days_off/features/matching/views/widgets/rota_grid_matrix.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  List<CircleModel> mockCircles = [];
  bool getCirclesThrows = false;

  @override
  Future<List<CircleModel>> getCircles() async {
    if (getCirclesThrows) {
      throw Exception('Failed to load circles');
    }
    return mockCircles;
  }
}

class MockMatchingRepository extends Fake implements MatchingRepository {
  late CircleAvailabilityData mockAvailability;
  bool getAvailabilityThrows = false;
  int? lastCircleId;
  String? lastStartDate;
  String? lastEndDate;

  @override
  Future<CircleAvailabilityData> getCircleAvailability({
    required int circleId,
    required String startDate,
    required String endDate,
  }) async {
    if (getAvailabilityThrows) {
      throw Exception('Availability fetch error');
    }
    lastCircleId = circleId;
    lastStartDate = startDate;
    lastEndDate = endDate;
    return mockAvailability;
  }
}

void main() {
  final testCircle1 = CircleModel(
    id: 101,
    ownerId: 1,
    name: 'ICU Shift Workers',
    handle: 'icu-team',
    membersCount: 2,
    myRole: 'owner',
    myVisibility: 'shifts',
    createdAt: DateTime(2026, 1, 1),
  );

  final testCircle2 = CircleModel(
    id: 102,
    ownerId: 2,
    name: 'Weekend Climbers',
    handle: 'climbers',
    membersCount: 3,
    myRole: 'member',
    myVisibility: 'free_busy',
    createdAt: DateTime(2026, 1, 1),
  );

  const testMemberAlice = CircleRosterMember(
    user: RosterUserSummary(id: 1, name: 'Alice Smith', handle: 'alice', initials: 'AS'),
    visibility: 'shifts',
    dailyStatus: {
      '2026-10-12': MemberDailyStatus(
        status: 'work',
        label: 'Day Shift',
        shortCode: '08–16',
        isDayOff: false,
        isOvernight: false,
        startTime: '08:00',
        endTime: '16:00',
      ),
      '2026-10-13': MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
        isOvernight: false,
      ),
      '2026-10-14': MemberDailyStatus(
        status: 'work',
        label: 'Night Shift',
        shortCode: '20–08',
        isDayOff: false,
        isOvernight: true,
        startTime: '20:00',
        endTime: '08:00',
      ),
    },
    availability: {},
  );

  const testMemberBob = CircleRosterMember(
    user: RosterUserSummary(id: 2, name: 'Bob Jones', handle: 'bob', initials: 'BJ'),
    visibility: 'free_busy',
    dailyStatus: {
      '2026-10-12': MemberDailyStatus(
        status: 'leave',
        label: 'Annual Leave',
        shortCode: 'A/L',
        isDayOff: true,
        isOvernight: false,
      ),
      '2026-10-13': MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
        isOvernight: false,
      ),
      '2026-10-14': MemberDailyStatus(
        status: 'study',
        label: 'Study Day',
        shortCode: 'DEV',
        isDayOff: false,
        isOvernight: false,
      ),
    },
    availability: {},
  );

  const testDaysOff = {
    '2026-10-12': DaysOffDateSummary(
      freeCount: 1,
      totalCount: 2,
      allFree: false,
    ),
    '2026-10-13': DaysOffDateSummary(
      freeCount: 2,
      totalCount: 2,
      allFree: true,
    ),
    '2026-10-14': DaysOffDateSummary(
      freeCount: 0,
      totalCount: 2,
      allFree: false,
    ),
  };

  const testAvailability = CircleAvailabilityData(
    members: [testMemberAlice, testMemberBob],
    commonAvailability: {},
    offTime: {},
    daysOff: testDaysOff,
    suggestions: [],
    plans: [],
  );

  group('MatchingGridNotifier Tests', () {
    late MockCircleRepository mockCircleRepo;
    late MockMatchingRepository mockMatchingRepo;

    setUp(() {
      mockCircleRepo = MockCircleRepository();
      mockMatchingRepo = MockMatchingRepository();
      mockCircleRepo.mockCircles = [testCircle1, testCircle2];
      mockMatchingRepo.mockAvailability = testAvailability;
    });

    test('initial state defaults correctly', () {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.circles, isEmpty);
      expect(notifier.state.selectedCircleId, isNull);
      expect(notifier.state.errorMessage, isNull);
    });

    test('loadCirclesAndAvailability loads circles and selects initial circle', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability(initialCircleId: 102);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.circles.length, 2);
      expect(notifier.state.selectedCircleId, 102);
      expect(notifier.state.selectedCircle?.name, 'Weekend Climbers');
      expect(notifier.state.availabilityData, isNotNull);
      expect(mockMatchingRepo.lastCircleId, 102);
    });

    test('loadCirclesAndAvailability handles empty circles list', () async {
      mockCircleRepo.mockCircles = [];
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.circles, isEmpty);
      expect(notifier.state.availabilityData, isNull);
    });

    test('selectCircle changes circle and refetches', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();
      expect(notifier.state.selectedCircleId, 101);

      await notifier.selectCircle(102);
      expect(notifier.state.selectedCircleId, 102);
      expect(mockMatchingRepo.lastCircleId, 102);
    });

    test('setDateRange updates dates and fetches new data', () async {
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();

      final newStart = DateTime(2026, 11, 1);
      final newEnd = DateTime(2026, 11, 14);
      await notifier.setDateRange(newStart, newEnd);

      expect(notifier.state.startDate, newStart);
      expect(notifier.state.endDate, newEnd);
      expect(mockMatchingRepo.lastStartDate, '2026-11-01');
      expect(mockMatchingRepo.lastEndDate, '2026-11-14');
    });

    test('handles errors during circle fetch gracefully', () async {
      mockCircleRepo.getCirclesThrows = true;
      final notifier = MatchingGridNotifier(
        matchingRepository: mockMatchingRepo,
        circleRepository: mockCircleRepo,
      );

      await notifier.loadCirclesAndAvailability();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, contains('Failed to load circles'));
    });
  });

  group('RotaGridCell Widget Tests', () {
    testWidgets('renders OFF status cell with proper shortCode', (tester) async {
      const status = MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
        isOvernight: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RotaGridCell(status: status),
          ),
        ),
      );

      expect(find.text('OFF'), findsOneWidget);
      expect(find.byIcon(LucideIcons.moon), findsNothing);
    });

    testWidgets('renders Work shift with overnight moon icon', (tester) async {
      const status = MemberDailyStatus(
        status: 'work',
        label: 'Night Shift',
        shortCode: '20–08',
        isDayOff: false,
        isOvernight: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RotaGridCell(status: status),
          ),
        ),
      );

      expect(find.text('20–08'), findsOneWidget);
      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
    });

    testWidgets('renders A/L and DEV status badges', (tester) async {
      const statusLeave = MemberDailyStatus(
        status: 'leave',
        label: 'Annual Leave',
        shortCode: 'A/L',
        isDayOff: true,
        isOvernight: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RotaGridCell(status: statusLeave),
          ),
        ),
      );

      expect(find.text('A/L'), findsOneWidget);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      bool tapped = false;
      const status = MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
        isOvernight: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotaGridCell(
              status: status,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RotaGridCell));
      expect(tapped, isTrue);
    });
  });

  group('RotaGridMatrix Widget Tests', () {
    testWidgets('renders empty placeholder if members list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RotaGridMatrix(members: []),
          ),
        ),
      );

      expect(find.text('No active members in circle'), findsOneWidget);
    });

    testWidgets('renders members column with names and initials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RotaGridMatrix(
                members: [testMemberAlice, testMemberBob],
                daysOffSummary: testDaysOff,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('AS'), findsOneWidget);
      expect(find.text('BJ'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('ALL OFF'), findsOneWidget); // On 2026-10-13
    });

    testWidgets('triggers onCellTap callback on cell tap', (tester) async {
      CircleRosterMember? tappedMember;
      String? tappedDate;
      MemberDailyStatus? tappedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RotaGridMatrix(
                members: const [testMemberAlice],
                customDates: const ['2026-10-12'],
                onCellTap: (m, d, s) {
                  tappedMember = m;
                  tappedDate = d;
                  tappedStatus = s;
                },
              ),
            ),
          ),
        ),
      );

      // Find the cell with 08–16
      final cellFinder = find.text('08–16');
      expect(cellFinder, findsOneWidget);

      await tester.tap(cellFinder);
      await tester.pump();

      expect(tappedMember?.user.name, 'Alice Smith');
      expect(tappedDate, '2026-10-12');
      expect(tappedStatus?.shortCode, '08–16');
    });
  });

  group('MemberCellDetailSheet Widget Tests', () {
    testWidgets('renders member info, shift hours, and privacy notice', (tester) async {
      const status = MemberDailyStatus(
        status: 'work',
        label: 'Evening Shift',
        shortCode: '14–22',
        isDayOff: false,
        isOvernight: false,
        startTime: '14:00',
        endTime: '22:00',
        notes: 'Covering for Charlie',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemberCellDetailSheet(
              member: testMemberAlice,
              dateStr: '2026-10-12',
              status: status,
            ),
          ),
        ),
      );

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('@alice'), findsOneWidget);
      expect(find.text('Shift Hours: 14:00 — 22:00'), findsOneWidget);
      expect(find.text('Notes: Covering for Charlie'), findsOneWidget);
      expect(find.textContaining('Privacy-first guarantee'), findsOneWidget);
    });

    testWidgets('renders full day off information', (tester) async {
      const status = MemberDailyStatus(
        status: 'off',
        label: 'Off Day',
        shortCode: 'OFF',
        isDayOff: true,
        isOvernight: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemberCellDetailSheet(
              member: testMemberBob,
              dateStr: '2026-10-13',
              status: status,
            ),
          ),
        ),
      );

      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Full Day Off — No shifts scheduled'), findsOneWidget);
      expect(find.text('OFF'), findsOneWidget);
    });
  });
}
