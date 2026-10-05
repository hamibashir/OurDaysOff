import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_time_utils.dart';
import '../models/availability_block.dart';
import '../models/schedule_entry.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ScheduleRepository(apiClient: apiClient);
});

class ScheduleRepository {
  final ApiClient apiClient;

  ScheduleRepository({required this.apiClient});

  /// Fetch schedule entries within an optional date range
  Future<List<ScheduleEntry>> getSchedules({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (startDate != null) {
      queryParameters['start_date'] = DateTimeUtils.formatYmd(startDate);
    }
    if (endDate != null) {
      queryParameters['end_date'] = DateTimeUtils.formatYmd(endDate);
    }

    final response = await apiClient.get(
      '/schedules',
      queryParameters: queryParameters,
    );

    final data = (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => ScheduleEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create or update a schedule entry for a single date
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
    final response = await apiClient.post(
      '/schedules',
      data: {
        'date': DateTimeUtils.formatYmd(date),
        'start_time': startTime,
        'end_time': endTime,
        'entry_type': entryType,
        if (label != null) 'label': label.trim(),
        if (notes != null) 'notes': notes.trim(),
        if (isOvernight != null) 'is_overnight': isOvernight,
        if (shiftTemplateId != null) 'shift_template_id': shiftTemplateId,
        if (source != null) 'source': source,
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ScheduleEntry.fromJson(data);
  }

  /// Batch stamp shift template onto multiple dates in a single fast call
  Future<List<ScheduleEntry>> batchSaveSchedules({
    required List<DateTime> dates,
    required String startTime,
    required String endTime,
    required String entryType,
    String? label,
    String? notes,
    bool? isOvernight,
    int? shiftTemplateId,
  }) async {
    final formattedDates = dates.map(DateTimeUtils.formatYmd).toList();

    final response = await apiClient.post(
      '/schedules/batch',
      data: {
        'dates': formattedDates,
        'start_time': startTime,
        'end_time': endTime,
        'entry_type': entryType,
        if (label != null) 'label': label.trim(),
        if (notes != null) 'notes': notes.trim(),
        if (isOvernight != null) 'is_overnight': isOvernight,
        if (shiftTemplateId != null) 'shift_template_id': shiftTemplateId,
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => ScheduleEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Update an existing schedule entry by ID
  Future<ScheduleEntry> updateSchedule(
    int id, {
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
    final response = await apiClient.put(
      '/schedules/$id',
      data: {
        'date': DateTimeUtils.formatYmd(date),
        'start_time': startTime,
        'end_time': endTime,
        'entry_type': entryType,
        if (label != null) 'label': label.trim(),
        if (notes != null) 'notes': notes.trim(),
        if (isOvernight != null) 'is_overnight': isOvernight,
        if (shiftTemplateId != null) 'shift_template_id': shiftTemplateId,
        if (source != null) 'source': source,
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ScheduleEntry.fromJson(data);
  }

  /// Delete a schedule entry by ID
  Future<void> deleteSchedule(int id) async {
    await apiClient.delete('/schedules/$id');
  }

  /// Fetch derived personal availability blocks from AvailabilityEngine
  Future<Map<String, List<AvailabilityBlock>>> getPersonalAvailability({
    required DateTime startDate,
    required DateTime endDate,
    int? recoveryHours,
    int? bufferBefore,
    int? bufferAfter,
  }) async {
    final queryParameters = <String, dynamic>{
      'start_date': DateTimeUtils.formatYmd(startDate),
      'end_date': DateTimeUtils.formatYmd(endDate),
      if (recoveryHours != null) 'recovery_hours': recoveryHours,
      if (bufferBefore != null) 'buffer_before': bufferBefore,
      if (bufferAfter != null) 'buffer_after': bufferAfter,
    };

    final response = await apiClient.get(
      '/availability/personal',
      queryParameters: queryParameters,
    );

    final rawData = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final result = <String, List<AvailabilityBlock>>{};

    rawData.forEach((dateStr, blocksJson) {
      if (blocksJson is List) {
        result[dateStr] = blocksJson
            .map((b) => AvailabilityBlock.fromJson(b as Map<String, dynamic>))
            .toList();
      }
    });

    return result;
  }

  /// Fetch user's manual availability overrides
  Future<List<AvailabilityOverride>> getOverrides({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (startDate != null) {
      queryParameters['start_date'] = DateTimeUtils.formatYmd(startDate);
    }
    if (endDate != null) {
      queryParameters['end_date'] = DateTimeUtils.formatYmd(endDate);
    }

    final response = await apiClient.get(
      '/availability/overrides',
      queryParameters: queryParameters,
    );

    final data = (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => AvailabilityOverride.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create a manual availability override for a date
  Future<AvailabilityOverride> saveOverride({
    required DateTime date,
    required String status,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final response = await apiClient.post(
      '/availability/overrides',
      data: {
        'date': DateTimeUtils.formatYmd(date),
        'status': status,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (reason != null) 'reason': reason.trim(),
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return AvailabilityOverride.fromJson(data);
  }

  /// Delete a manual availability override by ID
  Future<void> deleteOverride(int id) async {
    await apiClient.delete('/availability/overrides/$id');
  }
}
