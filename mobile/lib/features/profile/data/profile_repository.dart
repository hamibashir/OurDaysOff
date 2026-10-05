import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient: apiClient);
});

class ProfileRepository {
  final ApiClient apiClient;

  ProfileRepository({required this.apiClient});

  /// Fetch user profile details
  Future<UserModel> getProfile() async {
    final response = await apiClient.get('/profile');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Update name, timezone, or handle visibility
  Future<UserModel> updateProfile({
    String? name,
    String? timezone,
    String? handleVisibility,
  }) async {
    final response = await apiClient.put(
      '/profile',
      data: {
        if (name != null) 'name': name.trim(),
        if (timezone != null) 'timezone': timezone,
        if (handleVisibility != null) 'handle_visibility': handleVisibility,
      },
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Redeem VIP promo / coupon code
  Future<void> redeemCoupon(String code) async {
    await apiClient.post(
      '/subscription/redeem',
      data: {'coupon_code': code.trim()},
    );
  }

  /// Check subscription status
  Future<bool> getSubscriptionStatus() async {
    final response = await apiClient.get('/subscription/status');
    final map = response as Map<String, dynamic>;
    return map['is_premium'] == true;
  }
}
