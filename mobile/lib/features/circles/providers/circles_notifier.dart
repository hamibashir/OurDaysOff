import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_handler.dart';
import '../data/circle_repository.dart';
import '../models/circle_model.dart';
import 'circles_state.dart';

class CirclesNotifier extends StateNotifier<CirclesState> {
  final CircleRepository _repository;

  CirclesNotifier(this._repository) : super(const CirclesState()) {
    loadCircles();
  }

  Future<void> loadCircles() async {
    state = state.copyWith(status: CirclesStatus.loading, clearError: true);
    try {
      final circles = await _repository.getCircles();
      state = state.copyWith(
        status: CirclesStatus.loaded,
        circles: circles,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: CirclesStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: CirclesStatus.error,
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
  return CirclesNotifier(repository);
});
