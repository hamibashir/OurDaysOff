import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_handler.dart';
import '../../../core/storage/offline_cache_service.dart';
import '../data/circle_repository.dart';
import '../models/circle_model.dart';
import 'circles_state.dart';

class CirclesNotifier extends StateNotifier<CirclesState> {
  final CircleRepository _repository;
  final OfflineCacheService _offlineCache;

  CirclesNotifier(this._repository, [OfflineCacheService? offlineCache])
      : _offlineCache = offlineCache ?? OfflineCacheService(),
        super(const CirclesState()) {
    // 1. Instantly hydrate from local cache
    final cached = _offlineCache.getCachedCircles();
    if (cached.isNotEmpty) {
      state = state.copyWith(
        status: CirclesStatus.loaded,
        circles: cached,
      );
    }
    // 2. Fetch fresh circles
    loadCircles();
  }

  Future<void> loadCircles() async {
    if (state.circles.isEmpty) {
      state = state.copyWith(status: CirclesStatus.loading, clearError: true);
    }
    try {
      final circles = await _repository.getCircles();
      _offlineCache.saveCircles(circles);
      state = state.copyWith(
        status: CirclesStatus.loaded,
        circles: circles,
      );
    } on AppException catch (e) {
      // If we already have cached circles, stay loaded
      state = state.copyWith(
        status: state.circles.isNotEmpty ? CirclesStatus.loaded : CirclesStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: state.circles.isNotEmpty ? CirclesStatus.loaded : CirclesStatus.error,
        errorMessage: 'Failed to load circles: ${e.toString()}',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<CircleModel?> createCircle({
    required String name,
    String? handle,
    String discoverability = 'private',
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final circle = await _repository.createCircle(
        name: name,
        handle: handle,
        discoverability: discoverability,
      );

      final exists = state.circles.any((c) => c.id == circle.id);
      final updatedList = exists
          ? state.circles.map((c) => c.id == circle.id ? circle : c).toList()
          : [circle, ...state.circles];
      state = state.copyWith(
        isCreating: false,
        circles: updatedList,
        status: CirclesStatus.loaded,
      );
      return circle;
    } on AppException catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Failed to create circle: ${e.toString()}',
      );
      return null;
    }
  }

  Future<CircleModel?> joinCircle(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a valid invite code.');
      return null;
    }

    state = state.copyWith(isJoining: true, clearError: true);
    try {
      final circle = await _repository.joinCircle(cleanCode);

      // Check if circle is already in list
      final exists = state.circles.any((c) => c.id == circle.id);
      final updatedList = exists
          ? state.circles.map((c) => c.id == circle.id ? circle : c).toList()
          : [circle, ...state.circles];

      state = state.copyWith(
        isJoining: false,
        circles: updatedList,
        status: CirclesStatus.loaded,
      );
      return circle;
    } on AppException catch (e) {
      state = state.copyWith(
        isJoining: false,
        errorMessage: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        errorMessage: 'Failed to join circle: ${e.toString()}',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final circlesNotifierProvider =
    StateNotifierProvider<CirclesNotifier, CirclesState>((ref) {
  final repository = ref.watch(circleRepositoryProvider);
  final offlineCache = ref.watch(offlineCacheServiceProvider);
  return CirclesNotifier(repository, offlineCache);
});
