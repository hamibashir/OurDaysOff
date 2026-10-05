import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/schedule/data/schedule_repository.dart';
import 'package:our_days_off/features/schedule/data/shift_template_repository.dart';
import 'package:our_days_off/features/schedule/models/availability_block.dart';
import 'package:our_days_off/features/schedule/models/schedule_entry.dart';
import 'package:our_days_off/features/schedule/models/shift_template.dart';
import 'package:our_days_off/features/schedule/views/widgets/date_detail_bottom_sheet.dart';

class MockDetailScheduleRepo extends Fake implements ScheduleRepository {
  DateTime? lastSavedDate;
  String? lastSavedStartTime;
  String? lastSavedEndTime;
  String? lastSavedLabel;
  String? lastSavedNotes;
  String? lastSavedOverrideStatus;
  int? lastDeletedScheduleId;

  @override
  Future<List<ScheduleEntry>> getSchedules({DateTime? startDate, DateTime? endDate}) async => [];

  @override
  Future<List<AvailabilityOverride>> getOverrides({DateTime? startDate, DateTime? endDate}) async => [];

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
    lastSavedStartTime = startTime;
    lastSavedEndTime = endTime;
    lastSavedLabel = label;
    lastSavedNotes = notes;

    return ScheduleEntry(
      id: 777,
      userId: 1,
      date: date,
      startTime: startTime,
      endTime: endTime,
      entryType: entryType,
      label: label,
      notes: notes,
      isOvernight: isOvernight ?? false,
    );
  }

  @override
  Future<void> deleteSchedule(int id) async {
    lastDeletedScheduleId = id;
  }

  @override
  Future<AvailabilityOverride> saveOverride({
    required DateTime date,
    required String status,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    lastSavedDate = date;
    lastSavedOverrideStatus = status;

    return AvailabilityOverride(
      id: 888,
      userId: 1,
      date: date,
      status: status,
      reason: reason,
    );
  }

  @override
  Future<void> deleteOverride(int id) async {}
}

class MockDetailTemplateRepo extends Fake implements ShiftTemplateRepository {
  @override
  Future<List<ShiftTemplate>> getTemplates() async => [];
}

void main() {
  group('DateDetailBottomSheet Widget Tests', () {
    testWidgets('renders shift input fields and availability override segment', (WidgetTester tester) async {
      final testDate = DateTime(2026, 10, 20);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(MockDetailScheduleRepo()),
            shiftTemplateRepositoryProvider.overrideWithValue(MockDetailTemplateRepo()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DateDetailBottomSheet(date: testDate),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Shift Assignment'), findsOneWidget);
      expect(find.text('Shift Label / Custom Title'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Availability Override'), findsOneWidget);
      expect(find.text('Force Free'), findsOneWidget);
      expect(find.text('Force Busy'), findsOneWidget);
      expect(find.text('Save Shift'), findsOneWidget);
      expect(find.text('Save Override'), findsOneWidget);
    });

    testWidgets('saving shift updates via repository', (WidgetTester tester) async {
      final testDate = DateTime(2026, 10, 20);
      final repo = MockDetailScheduleRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(repo),
            shiftTemplateRepositoryProvider.overrideWithValue(MockDetailTemplateRepo()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DateDetailBottomSheet(date: testDate),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter shift label
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Day Shift, ICU, Flight'),
        'Emergency Ward Shift',
      );

      // Tap Save Shift
      await tester.ensureVisible(find.text('Save Shift'));
      await tester.tap(find.text('Save Shift'));
      await tester.pumpAndSettle();

      expect(repo.lastSavedDate?.day, 20);
      expect(repo.lastSavedLabel, 'Emergency Ward Shift');
    });

    testWidgets('saving availability override passes status to repository', (WidgetTester tester) async {
      final testDate = DateTime(2026, 10, 22);
      final repo = MockDetailScheduleRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(repo),
            shiftTemplateRepositoryProvider.overrideWithValue(MockDetailTemplateRepo()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DateDetailBottomSheet(date: testDate),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Force Free segment
      await tester.ensureVisible(find.text('Force Free'));
      await tester.tap(find.text('Force Free'));
      await tester.pumpAndSettle();

      // Tap Save Override
      await tester.ensureVisible(find.text('Save Override'));
      await tester.tap(find.text('Save Override'));
      await tester.pumpAndSettle();

      expect(repo.lastSavedDate?.day, 22);
      expect(repo.lastSavedOverrideStatus, 'available');
    });
  });
}
