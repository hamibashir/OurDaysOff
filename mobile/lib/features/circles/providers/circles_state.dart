import '../models/circle_model.dart';

enum CirclesStatus {
  initial,
  loading,
  loaded,
  error,
}

class CirclesState {
  final CirclesStatus status;
  final List<CircleModel> circles;
  final String searchQuery;
  final String? errorMessage;
  final bool isCreating;
  final bool isJoining;

  const CirclesState({
    this.status = CirclesStatus.initial,
    this.circles = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.isCreating = false,
    this.isJoining = false,
  });

  bool get isLoading => status == CirclesStatus.loading;

  List<CircleModel> get filteredCircles {
    if (searchQuery.trim().isEmpty) return circles;
    final query = searchQuery.trim().toLowerCase();
    return circles.where((c) {
      final nameMatches = c.name.toLowerCase().contains(query);
      final handleMatches = c.handle?.toLowerCase().contains(query) ?? false;
      return nameMatches || handleMatches;
    }).toList();
  }

  CirclesState copyWith({
    CirclesStatus? status,
    List<CircleModel>? circles,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    bool? isCreating,
    bool? isJoining,
  }) {
    return CirclesState(
      status: status ?? this.status,
      circles: circles ?? this.circles,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCreating: isCreating ?? this.isCreating,
      isJoining: isJoining ?? this.isJoining,
    );
  }
}
