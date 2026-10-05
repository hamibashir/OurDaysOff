import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/circle_availability_data.dart';

class MatchingRepository {
  final ApiClient apiClient;

  MatchingRepository({required this.apiClient});

  /// Fetch circle match matrix, common availability, summaries, and suggestions
  Future<CircleAvailabilityData> getCircleAvailability({
    required int circleId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await apiClient.get(
      '/circles/$circleId/availability',
      queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    return CircleAvailabilityData.fromJson(data);
  }

  /// Run 1-on-1 or multi-user compare across a custom list of user IDs
  Future<CircleAvailabilityData> compareUsers({
    required List<int> userIds,
    required String startDate,
    required String endDate,
    int? circleId,
  }) async {
    final payload = <String, dynamic>{
      'user_ids': userIds,
      'start_date': startDate,
      'end_date': endDate,
      if (circleId != null) 'circle_id': circleId,
    };

    final response = await apiClient.post(
      '/availability/compare',
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    return CircleAvailabilityData.fromJson(data);
  }
}

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MatchingRepository(apiClient: client);
});
