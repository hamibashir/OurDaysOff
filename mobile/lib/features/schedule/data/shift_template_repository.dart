import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/shift_template.dart';

final shiftTemplateRepositoryProvider = Provider<ShiftTemplateRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShiftTemplateRepository(apiClient: apiClient);
});

class ShiftTemplateRepository {
  final ApiClient apiClient;

  ShiftTemplateRepository({required this.apiClient});

  /// Fetch all saved shift templates for the authenticated user
  Future<List<ShiftTemplate>> getTemplates() async {
    final response = await apiClient.get('/shift-templates');
    final data = (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => ShiftTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create a new fast-tap shift template preset
  Future<ShiftTemplate> createTemplate({
    required String name,
    required String startTime,
    required String endTime,
    bool? isOvernight,
    String? color,
  }) async {
    final response = await apiClient.post(
      '/shift-templates',
      data: {
        'name': name.trim(),
        'start_time': startTime,
        'end_time': endTime,
        if (isOvernight != null) 'is_overnight': isOvernight,
        if (color != null) 'color': color,
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ShiftTemplate.fromJson(data);
  }

  /// Update an existing shift template preset
  Future<ShiftTemplate> updateTemplate(
    int id, {
    String? name,
    String? startTime,
    String? endTime,
    bool? isOvernight,
    String? color,
  }) async {
    final response = await apiClient.put(
      '/shift-templates/$id',
      data: {
        if (name != null) 'name': name.trim(),
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (isOvernight != null) 'is_overnight': isOvernight,
        if (color != null) 'color': color,
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ShiftTemplate.fromJson(data);
  }

  /// Delete a shift template preset
  Future<void> deleteTemplate(int id) async {
    await apiClient.delete('/shift-templates/$id');
  }
}
