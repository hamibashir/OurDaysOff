import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/activity_event.dart';
import '../models/circle_invite.dart';
import '../models/circle_member.dart';
import '../models/circle_model.dart';

class CircleRepository {
  final ApiClient apiClient;

  CircleRepository({required this.apiClient});

  /// Fetch all circles that the authenticated user belongs to
  Future<List<CircleModel>> getCircles() async {
    final response = await apiClient.get('/circles');
    final data = response['data'] as List<dynamic>? ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => CircleModel.fromJson(json))
        .toList();
  }

  /// Create a new circle with name, optional handle, and discoverability
  Future<CircleModel> createCircle({
    required String name,
    String? handle,
    String discoverability = 'private',
  }) async {
    final payload = {
      'name': name.trim(),
      if (handle != null && handle.trim().isNotEmpty) 'handle': handle.trim(),
      'discoverability': discoverability,
    };

    final response = await apiClient.post('/circles', data: payload);
    final data = response['data'] as Map<String, dynamic>;
    return CircleModel.fromJson(data);
  }

  /// Fetch single circle details including members and user role
  Future<CircleModel> getCircle(int id) async {
    final response = await apiClient.get('/circles/$id');
    final data = response['data'] as Map<String, dynamic>;
    return CircleModel.fromJson(data);
  }

  /// Delete circle (Owner only)
  Future<void> deleteCircle(int id) async {
    await apiClient.delete('/circles/$id');
  }

  /// Update circle member role, type, or privacy visibility
  Future<CircleMember> updateMember({
    required int circleId,
    required int memberId,
    String? role,
    String? memberType,
    String? visibility,
  }) async {
    final payload = <String, dynamic>{
      if (role != null) 'role': role,
      if (memberType != null) 'member_type': memberType,
      if (visibility != null) 'visibility': visibility,
    };

    final response = await apiClient.put(
      '/circles/$circleId/members/$memberId',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return CircleMember.fromJson(data);
  }

  /// Remove a member from circle or leave circle
  Future<void> removeMember({
    required int circleId,
    required int memberId,
  }) async {
    await apiClient.delete('/circles/$circleId/members/$memberId');
  }

  /// Fetch recent activity event stream for a circle
  Future<List<ActivityEvent>> getCircleActivity(int circleId) async {
    final response = await apiClient.get('/circles/$circleId/activity');
    final data = response['data'] as List<dynamic>? ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => ActivityEvent.fromJson(json))
        .toList();
  }

  /// Generate a new 6-character invite code and link
  Future<CircleInvite> createInvite({
    required int circleId,
    int? maxUses,
  }) async {
    final payload = <String, dynamic>{
      if (maxUses != null) 'max_uses': maxUses,
    };

    final response = await apiClient.post(
      '/circles/$circleId/invites',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return CircleInvite.fromJson(data);
  }

  /// Join a circle using a 6-character invite code
  Future<CircleModel> joinCircle(String inviteCode) async {
    final payload = {
      'invite_code': inviteCode.trim().toUpperCase(),
    };

    final response = await apiClient.post('/invites/join', data: payload);
    final data = response['data'] as Map<String, dynamic>;
    return CircleModel.fromJson(data);
  }
}

final circleRepositoryProvider = Provider<CircleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CircleRepository(apiClient: apiClient);
});
