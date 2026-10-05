import '../models/activity_event.dart';

class ActivityFeedState {
  final List<ActivityEvent> events;
  final bool isLoading;
  final String? errorMessage;

  const ActivityFeedState({
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ActivityFeedState copyWith({
    List<ActivityEvent>? events,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActivityFeedState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
