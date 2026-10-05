import '../../circles/models/circle_model.dart';
import '../models/availability_mode.dart';
import '../models/circle_availability_data.dart';

class MatchingGridState {
  final List<CircleModel> circles;
  final int? selectedCircleId;
  final DateTime startDate;
  final DateTime endDate;
  final CircleAvailabilityData? availabilityData;
  final AvailabilityMode mode;
  final List<int> selectedMemberIds;
  final bool isCustomCompare;
  final bool isLoading;
  final String? errorMessage;

  const MatchingGridState({
    this.circles = const [],
    this.selectedCircleId,
    required this.startDate,
    required this.endDate,
    this.availabilityData,
    this.mode = AvailabilityMode.daysOff,
    this.selectedMemberIds = const [],
    this.isCustomCompare = false,
    this.isLoading = false,
    this.errorMessage,
  });

  factory MatchingGridState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 6));
    return MatchingGridState(
      startDate: today,
      endDate: nextWeek,
      isLoading: true,
    );
  }

  CircleModel? get selectedCircle {
    if (selectedCircleId == null) return null;
    try {
      return circles.firstWhere((c) => c.id == selectedCircleId);
    } catch (_) {
      return null;
    }
  }

  MatchingGridState copyWith({
    List<CircleModel>? circles,
    int? selectedCircleId,
    DateTime? startDate,
    DateTime? endDate,
    CircleAvailabilityData? availabilityData,
    bool clearAvailability = false,
    AvailabilityMode? mode,
    List<int>? selectedMemberIds,
    bool? isCustomCompare,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MatchingGridState(
      circles: circles ?? this.circles,
      selectedCircleId: selectedCircleId ?? this.selectedCircleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      availabilityData: clearAvailability
          ? null
          : (availabilityData ?? this.availabilityData),
      mode: mode ?? this.mode,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      isCustomCompare: isCustomCompare ?? this.isCustomCompare,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
