import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_notifier.dart';
import '../data/profile_repository.dart';

final profileLoadingProvider = StateProvider<bool>((ref) => false);

final profileNotifierProvider = Provider<ProfileNotifier>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final authNotifier = ref.watch(authNotifierProvider.notifier);
  return ProfileNotifier(
    repository: repository,
    authNotifier: authNotifier,
    ref: ref,
  );
});

class ProfileNotifier {
  final ProfileRepository repository;
  final AuthNotifier authNotifier;
  final Ref ref;

  ProfileNotifier({
    required this.repository,
    required this.authNotifier,
    required this.ref,
  });

  Future<UserModel> updateProfile({
    String? name,
    String? timezone,
    String? handleVisibility,
  }) async {
    ref.read(profileLoadingProvider.notifier).state = true;
    try {
      final updatedUser = await repository.updateProfile(
        name: name,
        timezone: timezone,
        handleVisibility: handleVisibility,
      );
      authNotifier.updateUser(updatedUser);
      return updatedUser;
    } finally {
      ref.read(profileLoadingProvider.notifier).state = false;
    }
  }

  Future<void> redeemCoupon(String code) async {
    ref.read(profileLoadingProvider.notifier).state = true;
    try {
      await repository.redeemCoupon(code);
      // Refresh current user to reflect updated premium status
      final refreshed = await ref.read(authNotifierProvider.notifier).repository.getMe();
      authNotifier.updateUser(refreshed);
    } finally {
      ref.read(profileLoadingProvider.notifier).state = false;
    }
  }
}
