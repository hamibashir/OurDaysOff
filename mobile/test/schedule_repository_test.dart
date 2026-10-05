import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/network/api_client.dart';
import 'package:our_days_off/core/storage/secure_storage_service.dart';
import 'package:our_days_off/features/schedule/data/schedule_repository.dart';
import 'package:our_days_off/features/schedule/data/shift_template_repository.dart';

class MockSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'fake_token';
}

class FakeApiClient extends ApiClient {
  dynamic nextGetResponse;
  dynamic nextPostResponse;
  dynamic nextPutResponse;
  dynamic nextDeleteResponse;

  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;

  FakeApiClient() : super(storage: MockSecureStorage());

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    return nextGetResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    return nextPostResponse;
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    return nextPutResponse;
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    return nextDeleteResponse;
  }
}

void main() {
  group('ShiftTemplateRepository Tests', () {
    late FakeApiClient fakeApi;
    late ShiftTemplateRepository repo;

    setUp(() {
      fakeApi = FakeApiClient();
      repo = ShiftTemplateRepository(apiClient: fakeApi);
    });

    test('getTemplates returns list of parsed ShiftTemplate models', () async {
      fakeApi.nextGetResponse = {
        'data': [
          {
            'id': 1,
            'name': 'Day',
            'start_time': '08:00',
            'end_time': '16:00',
            'is_overnight': false,
            'color': '#3B82F6',
          },
          {
            'id': 2,
            'name': 'Night',
            'start_time': '20:00',
            'end_time': '08:00',
            'is_overnight': true,
            'color': '#8B5CF6',
          }
        ]
      };

      final templates = await repo.getTemplates();

      expect(fakeApi.lastPath, '/shift-templates');
      expect(templates.length, 2);
      expect(templates[0].name, 'Day');
      expect(templates[1].isOvernight, true);
    });

    test('createTemplate posts correct fields and returns created ShiftTemplate', () async {
      fakeApi.nextPostResponse = {
        'data': {
          'id': 3,
          'name': 'Twilight',
          'start_time': '16:00',
          'end_time': '00:00',
          'is_overnight': false,
          'color': '#F59E0B',
        }
      };

      final created = await repo.createTemplate(
        name: 'Twilight',
        startTime: '16:00',
        endTime: '00:00',
        color: '#F59E0B',
      );

      expect(fakeApi.lastPath, '/shift-templates');
      expect(fakeApi.lastData['name'], 'Twilight');
      expect(created.id, 3);
      expect(created.name, 'Twilight');
    });
  });

  group('ScheduleRepository Tests', () {
    late FakeApiClient fakeApi;
    late ScheduleRepository repo;

    setUp(() {
      fakeApi = FakeApiClient();
      repo = ScheduleRepository(apiClient: fakeApi);
    });

    test('getSchedules passes formatted date query parameters', () async {
      fakeApi.nextGetResponse = {
        'data': [
          {
            'id': 101,
            'user_id': 1,
            'date': '2026-10-05',
            'start_time': '07:00',
            'end_time': '15:00',
            'entry_type': 'work',
          }
        ]
      };

      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31);
      final entries = await repo.getSchedules(startDate: start, endDate: end);

      expect(fakeApi.lastPath, '/schedules');
      expect(fakeApi.lastQueryParams?['start_date'], '2026-10-01');
      expect(fakeApi.lastQueryParams?['end_date'], '2026-10-31');
      expect(entries.length, 1);
      expect(entries.first.id, 101);
    });

    test('batchSaveSchedules formats dates list for single API request', () async {
      fakeApi.nextPostResponse = {
        'data': [
          {
            'id': 1,
            'user_id': 1,
            'date': '2026-10-06',
            'start_time': '08:00',
            'end_time': '16:00',
            'entry_type': 'work',
          },
          {
            'id': 2,
            'user_id': 1,
            'date': '2026-10-07',
            'start_time': '08:00',
            'end_time': '16:00',
            'entry_type': 'work',
          }
        ]
      };

      final dates = [DateTime(2026, 10, 6), DateTime(2026, 10, 7)];
      final result = await repo.batchSaveSchedules(
        dates: dates,
        startTime: '08:00',
        endTime: '16:00',
        entryType: 'work',
        shiftTemplateId: 5,
      );

      expect(fakeApi.lastPath, '/schedules/batch');
      expect(fakeApi.lastData['dates'], ['2026-10-06', '2026-10-07']);
      expect(result.length, 2);
    });

    test('getPersonalAvailability parses daily blocks map', () async {
      fakeApi.nextGetResponse = {
        'data': {
          '2026-10-10': [
            {
              'start': '00:00:00',
              'end': '07:00:00',
              'status': 'available',
            },
            {
              'start': '07:00:00',
              'end': '19:00:00',
              'status': 'busy',
            }
          ]
        }
      };

      final availability = await repo.getPersonalAvailability(
        startDate: DateTime(2026, 10, 10),
        endDate: DateTime(2026, 10, 10),
      );

      expect(fakeApi.lastPath, '/availability/personal');
      expect(availability.containsKey('2026-10-10'), isTrue);
      expect(availability['2026-10-10']!.length, 2);
      expect(availability['2026-10-10']![0].isAvailable, isTrue);
      expect(availability['2026-10-10']![1].isAvailable, isFalse);
    });
  });
}
