import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/plan_location_model.dart';
import '../models/plan_member_model.dart';
import '../models/plan_message_model.dart';
import '../models/plan_model.dart';
import '../models/plan_option_model.dart';

class PlanRepository {
  final ApiClient apiClient;

  PlanRepository({required this.apiClient});

  String _formatApiDate(DateTime dt) {
    final d = dt.toUtc();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}:${pad(d.second)}';
  }

  /// Get all plans for circles user belongs to
  Future<List<PlanModel>> getPlans() async {
    final response = await apiClient.get('/plans');
    final data = response['data'] as List<dynamic>? ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => PlanModel.fromJson(json))
        .toList();
  }

  /// Fetch full plan detail with members, options, locations, and messages
  Future<PlanModel> getPlan(int id) async {
    final response = await apiClient.get('/plans/$id');
    final data = response['data'] as Map<String, dynamic>;
    return PlanModel.fromJson(data);
  }

  /// Create a new meetup plan
  Future<PlanModel> createPlan({
    required int circleId,
    required String title,
    String? description,
    required String eventType,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'circle_id': circleId,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'event_type': eventType,
      if (startAt != null) 'start_at': _formatApiDate(startAt),
      if (endAt != null) 'end_at': _formatApiDate(endAt),
      if (status != null) 'status': status,
    };

    final response = await apiClient.post('/plans', data: payload);
    final data = response['data'] as Map<String, dynamic>;
    return PlanModel.fromJson(data);
  }

  /// Delete a plan (creator only)
  Future<void> deletePlan(int id) async {
    await apiClient.delete('/plans/$id');
  }

  /// Submit or update RSVP status for a plan
  Future<PlanMemberModel> rsvp({
    required int planId,
    required String rsvpStatus,
  }) async {
    final response = await apiClient.post(
      '/plans/$planId/rsvp',
      data: {'rsvp_status': rsvpStatus},
    );
    final data = response['data'] as Map<String, dynamic>;
    return PlanMemberModel.fromJson(data);
  }

  /// Add a date/time polling option to a plan
  Future<PlanOptionModel> addOption({
    required int planId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final payload = {
      'start_at': _formatApiDate(startAt),
      'end_at': _formatApiDate(endAt),
    };

    final response = await apiClient.post(
      '/plans/$planId/options',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PlanOptionModel.fromJson(data);
  }

  /// Propose a new meetup venue/location
  Future<PlanLocationModel> proposeLocation({
    required int planId,
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await apiClient.post(
      '/plans/$planId/locations',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return PlanLocationModel.fromJson(data);
  }

  /// Vote for a proposed location
  Future<PlanLocationVoteModel> voteLocation(int locationId) async {
    final response = await apiClient.post('/locations/$locationId/vote');
    final data = response['data'] as Map<String, dynamic>;
    return PlanLocationVoteModel.fromJson(data);
  }

  /// Get messages in the in-plan discussion thread
  Future<List<PlanMessageModel>> getMessages(int planId) async {
    final response = await apiClient.get('/plans/$planId/messages');
    final data = response['data'] as List<dynamic>? ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => PlanMessageModel.fromJson(json))
        .toList();
  }

  /// Send a message in the plan discussion thread
  Future<PlanMessageModel> sendMessage({
    required int planId,
    required String body,
  }) async {
    final response = await apiClient.post(
      '/plans/$planId/messages',
      data: {'body': body.trim()},
    );
    final data = response['data'] as Map<String, dynamic>;
    return PlanMessageModel.fromJson(data);
  }
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlanRepository(apiClient: apiClient);
});
