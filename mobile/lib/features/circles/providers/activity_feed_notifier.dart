import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_handler.dart';
import '../data/circle_repository.dart';
import 'activity_feed_state.dart';

class ActivityFeedNotifier extends StateNotifier<ActivityFeedState> {
  final CircleRepository repository;
  final int circleId;

  ActivityFeedNotifier({
    required this.repository,
    required this.circleId,
  }) : super(const ActivityFeedState()) {
    loadActivity();
  }

  Future<void> loadActivity({bool force = false}) async {
    if (state.isLoading && !force) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await repository.getCircleActivity(circleId);
      state = state.copyWith(
        isLoading: false,
        events: events,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load activity: ${e.toString()}',
      );
    }
  }
}

final activityFeedProvider = StateNotifierProvider.autoDispose
    .family<ActivityFeedNotifier, ActivityFeedState, int>((ref, circleId) {
  final repo = ref.watch(circleRepositoryProvider);
  return ActivityFeedNotifier(
    repository: repo,
    circleId: circleId,
  );
});
