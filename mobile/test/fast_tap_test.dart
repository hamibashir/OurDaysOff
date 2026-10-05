import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/schedule/data/schedule_repository.dart';
import 'package:our_days_off/features/schedule/data/shift_template_repository.dart';
import 'package:our_days_off/features/schedule/models/schedule_entry.dart';
import 'package:our_days_off/features/schedule/models/shift_template.dart';
import 'package:our_days_off/features/schedule/views/schedule_screen.dart';
import 'package:our_days_off/features/schedule/views/widgets/fast_tap_bar.dart';

class MockFastTapScheduleRepo extends Fake implements ScheduleRepository {
  DateTime? lastSavedDate;
  String? lastEntryType;
  int? lastDeletedId;

  @override
  Future<List<ScheduleEntry>> getSchedules({DateTime? startDate, DateTime? endDate}) async => [];

  @override
  Future<ScheduleEntry> saveSchedule({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String entryType,
    String? label,
    String? notes,
    bool? isOvernight,
    int? shiftTemplateId,
    String? source,
  }) async {
    lastSavedDate = date;
    lastEntryType = entryType;
    return ScheduleEntry(
      id: 999,
      userId: 1,
      date: date,
      startTime: startTime,
      endTime: endTime,
      entryType: entryType,
      label: label,
      isOvernight: isOvernight ?? false,
    );
  }

  @override
  Future<void> deleteSchedule(int id) async {
    lastDeletedId = id;
  }
}

class MockFastTapTemplateRepo extends Fake implements ShiftTemplateRepository {
  @override
  Future<List<ShiftTemplate>> getTemplates() async {
    return [
      const ShiftTemplate(
        id: 1,
        name: 'Early Bird',
        startTime: '06:00',
        endTime: '14:30',
        color: '#3B82F6',
      ),
    ];
  }

  @override
  Future<ShiftTemplate> createTemplate({
    required String name,
    required String startTime,
    required String endTime,
    bool? isOvernight,
    String? color,
  }) async {
    return ShiftTemplate(
      id: 2,
      name: name,
      startTime: startTime,
      endTime: endTime,
      isOvernight: isOvernight ?? false,
      color: color ?? '#3B82F6',
    );
  }
}

void main() {
  group('Fast-Tap Stamping Toolbar Tests', () {
    testWidgets('renders fast-tap preset pills and action items', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(MockFastTapScheduleRepo()),
            shiftTemplateRepositoryProvider.overrideWithValue(MockFastTapTemplateRepo()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FastTapBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('+ Day Off'), findsOneWidget);
      expect(find.text('+ Early Bird'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('New Preset'), findsOneWidget);
    });

    testWidgets('tapping a preset pill activates stamp mode banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(MockFastTapScheduleRepo()),
            shiftTemplateRepositoryProvider.overrideWithValue(MockFastTapTemplateRepo()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FastTapBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on "+ Day Off"
      await tester.tap(find.text('+ Day Off'));
      await tester.pump();

      // Mode Banner should now be visible
      expect(find.text('Active Stamp: Day Off'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done exits stamp mode
      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(find.text('Active Stamp: Day Off'), findsNothing);
    });

    testWidgets('stamping a day off onto calendar date saves via repository', (WidgetTester tester) async {
      final mockScheduleRepo = MockFastTapScheduleRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(mockScheduleRepo),
            shiftTemplateRepositoryProvider.overrideWithValue(MockFastTapTemplateRepo()),
          ],
          child: const MaterialApp(
            home: ScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Activate Day Off stamp
      await tester.tap(find.text('+ Day Off'));
      await tester.pump();

      // 2. Tap on calendar date (e.g., day 15)
      final dayCell = find.text('15').first;
      await tester.tap(dayCell);
      await tester.pumpAndSettle();

      // 3. Verify repository was called to save the day off
      expect(mockScheduleRepo.lastSavedDate?.day, 15);
      expect(mockScheduleRepo.lastEntryType, 'off');
    });
  });
}
