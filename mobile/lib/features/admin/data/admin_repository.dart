import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminRepository(apiClient: apiClient);
});

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  /// Fetch dashboard platform metrics
  Future<AdminStats> getStats() async {
    final response = await apiClient.get('/admin/stats');
    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return AdminStats.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load admin stats');
  }

  /// Search & list users
  Future<List<AdminUser>> getUsers({String? search}) async {
    final response = await apiClient.get(
      '/admin/users',
      queryParameters: search != null && search.trim().isNotEmpty
          ? {'search': search.trim()}
          : null,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Toggle user VIP premium status
  Future<AdminUser> toggleUserPremium(int userId) async {
    final response = await apiClient.put('/admin/users/$userId/toggle-premium');
    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle premium status');
  }

  /// Toggle user admin status
  Future<AdminUser> toggleUserAdmin(int userId) async {
    final response = await apiClient.put('/admin/users/$userId/toggle-admin');
    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle admin status');
  }

  /// Fetch all system coupons
  Future<List<AdminCoupon>> getCoupons() async {
    final response = await apiClient.get('/admin/coupons');
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => AdminCoupon.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a new promotional coupon code
  Future<AdminCoupon> storeCoupon({
    required String code,
    DateTime? expiresAt,
  }) async {
    final response = await apiClient.post(
      '/admin/coupons',
      data: {
        'code': code.trim().toUpperCase(),
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      },
    );

    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return AdminCoupon.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create coupon code');
  }

  /// Toggle coupon active state
  Future<AdminCoupon> toggleCoupon(int couponId) async {
    final response = await apiClient.put('/admin/coupons/$couponId/toggle');
    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return AdminCoupon.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to toggle coupon status');
  }

  /// Fetch all system circles with members count and owner
  Future<List<AdminCircle>> getCircles() async {
    final response = await apiClient.get('/admin/circles');
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => AdminCircle.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
