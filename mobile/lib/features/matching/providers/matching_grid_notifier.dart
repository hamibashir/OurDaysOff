import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../circles/data/circle_repository.dart';
import '../data/matching_repository.dart';
import '../models/availability_mode.dart';
import 'matching_grid_state.dart';

class MatchingGridNotifier extends StateNotifier<MatchingGridState> {
  final MatchingRepository matchingRepository;
  final CircleRepository circleRepository;

  MatchingGridNotifier({
    required this.matchingRepository,
    required this.circleRepository,
  }) : super(MatchingGridState.initial());

  final _dateFormatter = DateFormat('yyyy-MM-dd');

  /// Initialize state by loading user's circles and fetching the availability matrix
  Future<void> loadCirclesAndAvailability({int? initialCircleId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final circles = await circleRepository.getCircles();
      if (circles.isEmpty) {
        state = state.copyWith(
          circles: [],
          clearAvailability: true,
          isLoading: false,
        );
        return;
      }

      int targetCircleId = circles.first.id;
      if (initialCircleId != null &&
          circles.any((c) => c.id == initialCircleId)) {
        targetCircleId = initialCircleId;
      }

      state = state.copyWith(
        circles: circles,
        selectedCircleId: targetCircleId,
      );

      await _fetchAvailability(targetCircleId, state.startDate, state.endDate);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Change active circle and refetch availability
  Future<void> selectCircle(int circleId) async {
    if (state.selectedCircleId == circleId && state.availabilityData != null) {
      return;
    }
    state = state.copyWith(
      selectedCircleId: circleId,
      isLoading: true,
      isCustomCompare: false,
      clearError: true,
    );
    await _fetchAvailability(circleId, state.startDate, state.endDate);
  }

  /// Change queried date range and refetch
  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
      isLoading: true,
      clearError: true,
    );

    if (state.isCustomCompare && state.selectedMemberIds.length >= 2) {
      await runCustomCompare();
    } else if (state.selectedCircleId != null) {
      await _fetchAvailability(state.selectedCircleId!, state.startDate, state.endDate);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Toggle between Days Off and Off Time availability modes
  void setMode(AvailabilityMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
  }

  /// Toggle a member in the custom compare cohort
  void toggleMember(int userId) {
    final current = List<int>.from(state.selectedMemberIds);
    if (current.contains(userId)) {
      current.remove(userId);
    } else {
      current.add(userId);
    }
    state = state.copyWith(selectedMemberIds: current);
  }

  /// Select all members for comparison
  void selectAllMembers() {
    if (state.availabilityData != null) {
      final allIds = state.availabilityData!.members.map((m) => m.user.id).toList();
      state = state.copyWith(selectedMemberIds: allIds);
    }
  }

  /// Deselect all members
  void deselectAllMembers() {
    state = state.copyWith(selectedMemberIds: []);
  }

  /// Run 1-on-1 or custom cohort comparison across selected user IDs
  Future<void> runCustomCompare() async {
    if (state.selectedMemberIds.length < 2) {
      state = state.copyWith(
        errorMessage: 'Select at least 2 members to calculate common free time.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final startStr = _dateFormatter.format(state.startDate);
      final endStr = _dateFormatter.format(state.endDate);

      final customData = await matchingRepository.compareUsers(
        userIds: state.selectedMemberIds,
        startDate: startStr,
        endDate: endStr,
        circleId: state.selectedCircleId,
      );

      state = state.copyWith(
        availabilityData: customData,
        isCustomCompare: true,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Reset comparison to full circle
  Future<void> resetToFullCircle() async {
    if (state.selectedCircleId != null) {
      state = state.copyWith(
        isLoading: true,
        isCustomCompare: false,
        clearError: true,
      );
      await _fetchAvailability(state.selectedCircleId!, state.startDate, state.endDate);
    }
  }

  /// Force refetch current circle availability
  Future<void> refresh() async {
    if (state.isCustomCompare && state.selectedMemberIds.length >= 2) {
      await runCustomCompare();
    } else if (state.selectedCircleId != null) {
      state = state.copyWith(isLoading: true, clearError: true);
      await _fetchAvailability(state.selectedCircleId!, state.startDate, state.endDate);
    } else {
      await loadCirclesAndAvailability();
    }
  }

  Future<void> _fetchAvailability(int circleId, DateTime start, DateTime end) async {
    try {
      final startStr = _dateFormatter.format(start);
      final endStr = _dateFormatter.format(end);

      final data = await matchingRepository.getCircleAvailability(
        circleId: circleId,
        startDate: startStr,
        endDate: endStr,
      );

      final memberIds = data.members.map((m) => m.user.id).toList();

      state = state.copyWith(
        availabilityData: data,
        selectedMemberIds: memberIds,
        isCustomCompare: false,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final matchingGridProvider =
    StateNotifierProvider<MatchingGridNotifier, MatchingGridState>((ref) {
  final matchingRepo = ref.watch(matchingRepositoryProvider);
  final circleRepo = ref.watch(circleRepositoryProvider);
  return MatchingGridNotifier(
    matchingRepository: matchingRepo,
    circleRepository: circleRepo,
  );
});
