import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/storage/offline_cache_service.dart';

void main() {
  group('OfflineCacheService Tests', () {
    test('OfflineCacheService handles unopened box gracefully without throwing', () {
      final cacheService = OfflineCacheService();

      // In unit test without Hive initialization, getters should return empty lists without crashing
      final schedules = cacheService.getCachedSchedule();
      final circles = cacheService.getCachedCircles();

      expect(schedules, isEmpty);
      expect(circles, isEmpty);
    });
  });
}
