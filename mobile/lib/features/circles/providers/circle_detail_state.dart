import '../models/circle_model.dart';

enum CircleDetailStatus {
  initial,
  loading,
  loaded,
  error,
  actionInProgress,
  deleted,
}

class CircleDetailState {
  final CircleModel? circle;
  final CircleDetailStatus status;
  final String? errorMessage;
  final String? successMessage;
  final int? activeMemberActionId;

  const CircleDetailState({
    this.circle,
    this.status = CircleDetailStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.activeMemberActionId,
  });

  bool get isLoading => status == CircleDetailStatus.loading;
  bool get isActionInProgress => status == CircleDetailStatus.actionInProgress;

  CircleDetailState copyWith({
    CircleModel? circle,
    CircleDetailStatus? status,
    String? errorMessage,
    String? successMessage,
    int? activeMemberActionId,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearActiveAction = false,
  }) {
    return CircleDetailState(
      circle: circle ?? this.circle,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      activeMemberActionId: clearActiveAction
          ? null
          : (activeMemberActionId ?? this.activeMemberActionId),
    );
  }
}
