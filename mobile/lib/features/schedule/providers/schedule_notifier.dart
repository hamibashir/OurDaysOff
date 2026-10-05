import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../data/schedule_repository.dart';
import '../data/shift_template_repository.dart';
import '../models/availability_block.dart';
import '../models/schedule_entry.dart';
import '../models/shift_template.dart';
import 'schedule_state.dart';

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  final templateRepo = ref.watch(shiftTemplateRepositoryProvider);
  return ScheduleNotifier(
    scheduleRepo: scheduleRepo,
    templateRepo: templateRepo,
  );
});

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository scheduleRepo;
  final ShiftTemplateRepository templateRepo;

  ScheduleNotifier({
    required this.scheduleRepo,
    required this.templateRepo,
  }) : super(ScheduleState.initial()) {
    init();
  }

  Future<void> init() async {
    await Future.wait([
      loadMonth(state.focusedMonth),
      loadTemplates(),
    ]);
  }

  /// Load schedule entries and overrides for the month with 7-day padding
  Future<void> loadMonth(DateTime month) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final queryStart = firstDay.subtract(const Duration(days: 7));
    final queryEnd = lastDay.add(const Duration(days: 7));

    try {
      final results = await Future.wait([
        scheduleRepo.getSchedules(startDate: queryStart, endDate: queryEnd),
        scheduleRepo.getOverrides(startDate: queryStart, endDate: queryEnd),
      ]);

      final entriesList = results[0] as List<ScheduleEntry>;
      final overridesList = results[1] as List<AvailabilityOverride>;

      final entriesMap = <DateTime, List<ScheduleEntry>>{};
      for (final entry in entriesList) {
        final key = DateTimeUtils.dateOnly(entry.date);
        entriesMap.putIfAbsent(key, () => []).add(entry);
      }

      final overridesMap = <DateTime, AvailabilityOverride>{};
      for (final override in overridesList) {
        final key = DateTimeUtils.dateOnly(override.date);
        overridesMap[key] = override;
      }

      state = state.copyWith(
        focusedMonth: month,
        entries: entriesMap,
        overrides: overridesMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Fetch saved shift template presets
  Future<void> loadTemplates() async {
    try {
      final templates = await templateRepo.getTemplates();
      state = state.copyWith(templates: templates);
    } catch (_) {}
  }

  /// Select a date on the calendar. If stamp mode is active, stamps the shift!
  Future<void> selectDate(DateTime date) async {
    final normalized = DateTimeUtils.dateOnly(date);

    if (state.isStampModeActive) {
      // High-Velocity Stamping Action
      await stampDate(normalized);
    } else {
      // Standard Date Selection
      AppHaptics.selection();
      state = state.copyWith(
        selectedDate: normalized,
        focusedMonth: date,
      );
    }
  }

  /// Toggle a shift template as active stamp
  void setActiveTemplateStamp(ShiftTemplate template) {
    AppHaptics.selection();
    if (state.activeStamp?.id == template.id) {
      state = state.copyWith(
        clearActiveStamp: true,
        isDayOffStampActive: false,
        isEraseStampActive: false,
      );
    } else {
      state = state.copyWith(
        activeStamp: template,
        isDayOffStampActive: false,
        isEraseStampActive: false,
      );
    }
  }

  /// Toggle Day Off preset as active stamp
  void setDayOffStamp() {
    AppHaptics.selection();
    if (state.isDayOffStampActive) {
      state = state.copyWith(isDayOffStampActive: false);
    } else {
      state = state.copyWith(
        isDayOffStampActive: true,
        clearActiveStamp: true,
        isEraseStampActive: false,
      );
    }
  }

  /// Toggle Erase / Clear tool as active stamp
  void setEraseStamp() {
    AppHaptics.selection();
    if (state.isEraseStampActive) {
      state = state.copyWith(isEraseStampActive: false);
    } else {
      state = state.copyWith(
        isEraseStampActive: true,
        clearActiveStamp: true,
        isDayOffStampActive: false,
      );
    }
  }

  /// Clear all stamp modes back to standard view
  void clearStampMode() {
    AppHaptics.light();
    state = state.copyWith(
      clearActiveStamp: true,
      isDayOffStampActive: false,
      isEraseStampActive: false,
    );
  }

  /// High-Velocity Single-Tap Date Stamping with Optimistic UI update
  Future<void> stampDate(DateTime date) async {
    final normalized = DateTimeUtils.dateOnly(date);
    final previousEntries = state.entries[normalized] ?? [];

    AppHaptics.light();

    // 1. Erase Stamp Mode
    if (state.isEraseStampActive) {
      if (previousEntries.isEmpty) return;

      final updatedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
      updatedMap.remove(normalized);
      state = state.copyWith(
        selectedDate: normalized,
        entries: updatedMap,
      );

      try {
        final existingId = previousEntries.first.id;
        if (existingId > 0) {
          await scheduleRepo.deleteSchedule(existingId);
        }
      } catch (e) {
        final rollbackMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
        rollbackMap[normalized] = previousEntries;
        state = state.copyWith(
          entries: rollbackMap,
          errorMessage: 'Failed to delete shift: $e',
        );
      }
      return;
    }

    // 2. Day Off Stamp Mode
    if (state.isDayOffStampActive) {
      final optimisticEntry = ScheduleEntry(
        id: -DateTime.now().millisecondsSinceEpoch,
        userId: 0,
        date: normalized,
        startTime: '00:00',
        endTime: '24:00',
        entryType: 'off',
        label: 'Day Off',
        isOvernight: false,
      );

      final updatedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
      updatedMap[normalized] = [optimisticEntry];
      state = state.copyWith(
        selectedDate: normalized,
        entries: updatedMap,
      );

      try {
        final confirmed = await scheduleRepo.saveSchedule(
          date: normalized,
          startTime: '00:00',
          endTime: '24:00',
          entryType: 'off',
          label: 'Day Off',
          isOvernight: false,
        );

        final confirmedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
        confirmedMap[normalized] = [confirmed];
        state = state.copyWith(entries: confirmedMap);
      } catch (e) {
        final rollbackMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
        if (previousEntries.isEmpty) {
          rollbackMap.remove(normalized);
        } else {
          rollbackMap[normalized] = previousEntries;
        }
        state = state.copyWith(
          entries: rollbackMap,
          errorMessage: 'Failed to stamp day off: $e',
        );
      }
      return;
    }

    // 3. Shift Template Stamp Mode
    if (state.activeStamp != null) {
      final template = state.activeStamp!;

      final optimisticEntry = ScheduleEntry(
        id: -DateTime.now().millisecondsSinceEpoch,
        userId: 0,
        shiftTemplateId: template.id,
        shiftTemplate: template,
        date: normalized,
        startTime: template.startTime,
        endTime: template.endTime,
        entryType: 'work',
        label: template.name,
        isOvernight: template.isOvernight,
      );

      final updatedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
      updatedMap[normalized] = [optimisticEntry];
      state = state.copyWith(
        selectedDate: normalized,
        entries: updatedMap,
      );

      try {
        final confirmed = await scheduleRepo.saveSchedule(
          date: normalized,
          startTime: template.startTime,
          endTime: template.endTime,
          entryType: 'work',
          label: template.name,
          shiftTemplateId: template.id,
          isOvernight: template.isOvernight,
        );

        final confirmedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
        confirmedMap[normalized] = [confirmed];
        state = state.copyWith(entries: confirmedMap);
      } catch (e) {
        final rollbackMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
        if (previousEntries.isEmpty) {
          rollbackMap.remove(normalized);
        } else {
          rollbackMap[normalized] = previousEntries;
        }
        state = state.copyWith(
          entries: rollbackMap,
          errorMessage: 'Failed to stamp shift: $e',
        );
      }
    }
  }

  /// Create a new shift template preset and refresh templates
  Future<void> createTemplate({
    required String name,
    required String startTime,
    required String endTime,
    bool? isOvernight,
    String? color,
  }) async {
    final created = await templateRepo.createTemplate(
      name: name,
      startTime: startTime,
      endTime: endTime,
      isOvernight: isOvernight,
      color: color,
    );
    state = state.copyWith(
      templates: [...state.templates, created],
    );
  }

  /// Save or update a single schedule entry from DateDetailBottomSheet
  Future<ScheduleEntry> saveScheduleEntry({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String entryType,
    String? label,
    String? notes,
    bool? isOvernight,
    int? shiftTemplateId,
  }) async {
    final normalized = DateTimeUtils.dateOnly(date);

    final saved = await scheduleRepo.saveSchedule(
      date: normalized,
      startTime: startTime,
      endTime: endTime,
      entryType: entryType,
      label: label,
      notes: notes,
      isOvernight: isOvernight,
      shiftTemplateId: shiftTemplateId,
    );

    final updatedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
    updatedMap[normalized] = [saved];
    state = state.copyWith(entries: updatedMap);

    return saved;
  }

  /// Delete a schedule entry from DateDetailBottomSheet
  Future<void> deleteScheduleEntry(int id, DateTime date) async {
    final normalized = DateTimeUtils.dateOnly(date);

    await scheduleRepo.deleteSchedule(id);

    final updatedMap = Map<DateTime, List<ScheduleEntry>>.from(state.entries);
    updatedMap.remove(normalized);
    state = state.copyWith(entries: updatedMap);
  }

  /// Save or update manual availability override
  Future<AvailabilityOverride> setAvailabilityOverride({
    required DateTime date,
    required String status,
    String? reason,
  }) async {
    final normalized = DateTimeUtils.dateOnly(date);

    final override = await scheduleRepo.saveOverride(
      date: normalized,
      status: status,
      reason: reason,
    );

    final updatedOverrides = Map<DateTime, AvailabilityOverride>.from(state.overrides);
    updatedOverrides[normalized] = override;
    state = state.copyWith(overrides: updatedOverrides);

    return override;
  }

  /// Remove manual availability override for date
  Future<void> removeAvailabilityOverride(DateTime date) async {
    final normalized = DateTimeUtils.dateOnly(date);
    final existing = state.overrides[normalized];
    if (existing != null && existing.id > 0) {
      await scheduleRepo.deleteOverride(existing.id);
    }

    final updatedOverrides = Map<DateTime, AvailabilityOverride>.from(state.overrides);
    updatedOverrides.remove(normalized);
    state = state.copyWith(overrides: updatedOverrides);
  }

  /// Navigate to previous/next month or jump to today
  Future<void> changeFocusedMonth(DateTime month) async {
    state = state.copyWith(focusedMonth: month);
    await loadMonth(month);
  }

  /// Jump directly to today's date
  Future<void> jumpToToday() async {
    final now = DateTimeUtils.dateOnly(DateTime.now());
    selectDate(now);
    if (now.month != state.focusedMonth.month || now.year != state.focusedMonth.year) {
      await changeFocusedMonth(now);
    }
  }
}
