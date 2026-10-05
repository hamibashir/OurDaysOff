import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/schedule/data/schedule_repository.dart';
import 'package:our_days_off/features/schedule/data/shift_template_repository.dart';
import 'package:our_days_off/features/schedule/models/schedule_entry.dart';
import 'package:our_days_off/features/schedule/models/shift_template.dart';
import 'package:our_days_off/features/schedule/providers/schedule_notifier.dart';
import 'package:our_days_off/features/schedule/providers/schedule_state.dart';
import 'package:our_days_off/features/schedule/views/schedule_screen.dart';

class MockScheduleRepo extends Fake implements ScheduleRepository {
  @override
  Future<List<ScheduleEntry>> getSchedules({DateTime? startDate, DateTime? endDate}) async {
    return [
      ScheduleEntry(
        id: 1,
        userId: 1,
        date: DateTime(2026, 10, 5),
        startTime: '07:00:00',
        endTime: '15:30:00',
        entryType: 'work',
        label: 'ICU Day Shift',
        shiftTemplate: const ShiftTemplate(
          id: 1,
          name: 'Day',
          startTime: '07:00',
          endTime: '15:30',
          color: '#3B82F6',
        ),
      ),
      ScheduleEntry(
        id: 2,
        userId: 1,
        date: DateTime(2026, 10, 6),
        startTime: '21:00:00',
        endTime: '07:00:00',
        entryType: 'work',
        label: 'Night Shift',
        isOvernight: true,
      ),
    ];
  }
}

class MockTemplateRepo extends Fake implements ShiftTemplateRepository {
  @override
  Future<List<ShiftTemplate>> getTemplates() async => const [];
}

void main() {
  group('ScheduleScreen & Calendar View Tests', () {
    testWidgets('renders month calendar, day agenda, and today button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(MockScheduleRepo()),
            shiftTemplateRepositoryProvider.overrideWithValue(MockTemplateRepo()),
          ],
          child: const MaterialApp(
            home: ScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Today'), findsOneWidget);

      // Verify TableCalendar days of week appear
      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
    });

    testWidgets('displays assigned shift details in DayAgendaView when entry exists', (WidgetTester tester) async {
      final mockDate = DateTime(2026, 10, 5);
      final shift = ScheduleEntry(
        id: 1,
        userId: 1,
        date: mockDate,
        startTime: '07:00:00',
        endTime: '15:30:00',
        entryType: 'work',
        label: 'ICU Day Shift',
        notes: 'Bring stethoscope',
      );

      final stateWithShift = ScheduleState(
        selectedDate: mockDate,
        focusedMonth: mockDate,
        entries: {
          mockDate: [shift],
        },
        templates: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleNotifierProvider.overrideWith(
              (ref) => _CustomScheduleNotifier(stateWithShift),
            ),
          ],
          child: const MaterialApp(
            home: ScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ICU Day Shift'), findsOneWidget);
      expect(find.text('07:00 – 15:30'), findsOneWidget);
      expect(find.text('Bring stethoscope'), findsOneWidget);
      expect(find.text('Working'), findsOneWidget);
    });

    testWidgets('displays overnight badge when shift is overnight', (WidgetTester tester) async {
      final mockDate = DateTime(2026, 10, 6);
      final overnightShift = ScheduleEntry(
        id: 2,
        userId: 1,
        date: mockDate,
        startTime: '21:00:00',
        endTime: '07:00:00',
        entryType: 'work',
        label: 'Emergency Night Shift',
        isOvernight: true,
      );

      final stateWithOvernight = ScheduleState(
        selectedDate: mockDate,
        focusedMonth: mockDate,
        entries: {
          mockDate: [overnightShift],
        },
        templates: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleNotifierProvider.overrideWith(
              (ref) => _CustomScheduleNotifier(stateWithOvernight),
            ),
          ],
          child: const MaterialApp(
            home: ScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Emergency Night Shift'), findsOneWidget);
      expect(find.text('21:00 – 07:00 (+1d)'), findsOneWidget);
      expect(find.text('Overnight'), findsOneWidget);
    });

    testWidgets('displays free / Day Off state when date has no shifts', (WidgetTester tester) async {
      final mockDate = DateTime(2026, 10, 7);

      final stateFree = ScheduleState(
        selectedDate: mockDate,
        focusedMonth: mockDate,
        entries: const {},
        templates: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleNotifierProvider.overrideWith(
              (ref) => _CustomScheduleNotifier(stateFree),
            ),
          ],
          child: const MaterialApp(
            home: ScheduleScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Shifts Scheduled'), findsOneWidget);
      expect(find.text('You are free and marked as available on this date.'), findsOneWidget);
    });
  });
}

class _CustomScheduleNotifier extends StateNotifier<ScheduleState> implements ScheduleNotifier {
  _CustomScheduleNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
