import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_repository.dart';
import '../models/admin_models.dart';

// --- STATS PROVIDER ---
final adminStatsProvider =
    StateNotifierProvider<AdminStatsNotifier, AsyncValue<AdminStats>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminStatsNotifier(repository: repository);
});

class AdminStatsNotifier extends StateNotifier<AsyncValue<AdminStats>> {
  final AdminRepository repository;

  AdminStatsNotifier({required this.repository}) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await repository.getStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// --- USERS STATE & PROVIDER ---
class AdminUsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  AdminUsersState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminUsersNotifier(repository: repository);
});

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminRepository repository;

  AdminUsersNotifier({required this.repository}) : super(const AdminUsersState()) {
    loadUsers();
  }

  Future<void> loadUsers({String? query}) async {
    final search = query ?? state.searchQuery;
    state = state.copyWith(isLoading: true, error: null, searchQuery: search);
    try {
      final users = await repository.getUsers(search: search);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> togglePremium(int userId) async {
    final oldUsers = state.users;
    // Optimistic toggle
    state = state.copyWith(
      users: state.users.map((u) {
        if (u.id == userId) return u.copyWith(isPremium: !u.isPremium);
        return u;
      }).toList(),
    );

    try {
      final updated = await repository.toggleUserPremium(userId);
      state = state.copyWith(
        users: state.users.map((u) => u.id == userId ? updated : u).toList(),
      );
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        users: oldUsers,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> toggleAdmin(int userId) async {
    final oldUsers = state.users;
    // Optimistic toggle
    state = state.copyWith(
      users: state.users.map((u) {
        if (u.id == userId) return u.copyWith(isAdmin: !u.isAdmin);
        return u;
      }).toList(),
    );

    try {
      final updated = await repository.toggleUserAdmin(userId);
      state = state.copyWith(
        users: state.users.map((u) => u.id == userId ? updated : u).toList(),
      );
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        users: oldUsers,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

// --- COUPONS STATE & PROVIDER ---
class AdminCouponsState {
  final List<AdminCoupon> coupons;
  final bool isLoading;
  final String? error;
  final bool isCreating;

  const AdminCouponsState({
    this.coupons = const [],
    this.isLoading = false,
    this.error,
    this.isCreating = false,
  });

  AdminCouponsState copyWith({
    List<AdminCoupon>? coupons,
    bool? isLoading,
    String? error,
    bool? isCreating,
  }) {
    return AdminCouponsState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

final adminCouponsProvider =
    StateNotifierProvider<AdminCouponsNotifier, AdminCouponsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminCouponsNotifier(repository: repository);
});

class AdminCouponsNotifier extends StateNotifier<AdminCouponsState> {
  final AdminRepository repository;

  AdminCouponsNotifier({required this.repository}) : super(const AdminCouponsState()) {
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final coupons = await repository.getCoupons();
      state = state.copyWith(coupons: coupons, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> createCoupon({required String code, DateTime? expiresAt}) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final newCoupon = await repository.storeCoupon(code: code, expiresAt: expiresAt);
      state = state.copyWith(
        coupons: [newCoupon, ...state.coupons],
        isCreating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> toggleCoupon(int couponId) async {
    final oldCoupons = state.coupons;
    state = state.copyWith(
      coupons: state.coupons.map((c) {
        if (c.id == couponId) return c.copyWith(isActive: !c.isActive);
        return c;
      }).toList(),
    );

    try {
      final updated = await repository.toggleCoupon(couponId);
      state = state.copyWith(
        coupons: state.coupons.map((c) => c.id == couponId ? updated : c).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        coupons: oldCoupons,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

// --- CIRCLES STATE & PROVIDER ---
final adminCirclesProvider =
    StateNotifierProvider<AdminCirclesNotifier, AsyncValue<List<AdminCircle>>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminCirclesNotifier(repository: repository);
});

class AdminCirclesNotifier extends StateNotifier<AsyncValue<List<AdminCircle>>> {
  final AdminRepository repository;

  AdminCirclesNotifier({required this.repository}) : super(const AsyncValue.loading()) {
    loadCircles();
  }

  Future<void> loadCircles() async {
    state = const AsyncValue.loading();
    try {
      final circles = await repository.getCircles();
      state = AsyncValue.data(circles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
