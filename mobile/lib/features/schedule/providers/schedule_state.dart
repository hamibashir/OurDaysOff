import '../../../core/utils/date_time_utils.dart';
import '../models/availability_block.dart';
import '../models/schedule_entry.dart';
import '../models/shift_template.dart';

class ScheduleState {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Map<DateTime, List<ScheduleEntry>> entries;
  final Map<DateTime, AvailabilityOverride> overrides;
  final List<ShiftTemplate> templates;
  final bool isLoading;
  final String? errorMessage;

  // Fast-Tap Stamping Mode States
  final ShiftTemplate? activeStamp;
  final bool isDayOffStampActive;
  final bool isEraseStampActive;
  final bool isStamping;

  ScheduleState({
    required this.selectedDate,
    required this.focusedMonth,
    required this.entries,
    this.overrides = const {},
    required this.templates,
    this.isLoading = false,
    this.errorMessage,
    this.activeStamp,
    this.isDayOffStampActive = false,
    this.isEraseStampActive = false,
    this.isStamping = false,
  });

  factory ScheduleState.initial() {
    final now = DateTimeUtils.dateOnly(DateTime.now());
    return ScheduleState(
      selectedDate: now,
      focusedMonth: now,
      entries: const {},
      overrides: const {},
      templates: const [],
      isLoading: false,
      isDayOffStampActive: false,
      isEraseStampActive: false,
      isStamping: false,
    );
  }

  /// Whether any fast-tap stamp is currently active
  bool get isStampModeActive =>
      activeStamp != null || isDayOffStampActive || isEraseStampActive;

  /// Get schedule entries for a specific day
  List<ScheduleEntry> getEntriesForDay(DateTime day) {
    final normalized = DateTimeUtils.dateOnly(day);
    return entries[normalized] ?? const [];
  }

  /// Get manual override for a specific day if one exists
  AvailabilityOverride? getOverrideForDay(DateTime day) {
    final normalized = DateTimeUtils.dateOnly(day);
    return overrides[normalized];
  }

  /// Get primary schedule entry for selected day
  ScheduleEntry? get selectedDayEntry {
    final list = getEntriesForDay(selectedDate);
    return list.isNotEmpty ? list.first : null;
  }

  /// Get override for selected day
  AvailabilityOverride? get selectedDayOverride => getOverrideForDay(selectedDate);

  ScheduleState copyWith({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    Map<DateTime, List<ScheduleEntry>>? entries,
    Map<DateTime, AvailabilityOverride>? overrides,
    List<ShiftTemplate>? templates,
    bool? isLoading,
    String? errorMessage,
    ShiftTemplate? activeStamp,
    bool clearActiveStamp = false,
    bool? isDayOffStampActive,
    bool? isEraseStampActive,
    bool? isStamping,
  }) {
    return ScheduleState(
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      entries: entries ?? this.entries,
      overrides: overrides ?? this.overrides,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeStamp: clearActiveStamp ? null : (activeStamp ?? this.activeStamp),
      isDayOffStampActive: isDayOffStampActive ?? this.isDayOffStampActive,
      isEraseStampActive: isEraseStampActive ?? this.isEraseStampActive,
      isStamping: isStamping ?? this.isStamping,
    );
  }
}
