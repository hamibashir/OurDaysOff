import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/network/api_client.dart';
import 'package:our_days_off/core/storage/secure_storage_service.dart';
import 'package:our_days_off/features/matching/data/matching_repository.dart';
import 'package:our_days_off/features/matching/models/circle_availability_data.dart';
import 'package:our_days_off/features/matching/models/circle_plan_summary.dart';
import 'package:our_days_off/features/matching/models/circle_roster_member.dart';
import 'package:our_days_off/features/matching/models/days_off_summary.dart';
import 'package:our_days_off/features/matching/models/match_suggestion.dart';
import 'package:our_days_off/features/matching/models/member_daily_status.dart';
import 'package:our_days_off/features/matching/models/off_time_summary.dart';
import 'package:our_days_off/features/matching/models/roster_user_summary.dart';

class MockSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'fake_token';
}

class FakeApiClient extends ApiClient {
  dynamic nextGetResponse;
  dynamic nextPostResponse;
  String? lastGetPath;
  String? lastPostPath;
  Map<String, dynamic>? lastGetParams;
  dynamic lastPostData;

  FakeApiClient() : super(storage: MockSecureStorage());

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastGetPath = path;
    lastGetParams = queryParameters;
    return nextGetResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return nextPostResponse;
  }
}

void main() {
  group('MemberDailyStatus Model Tests', () {
    test('parses and checks statuses correctly', () {
      final off = MemberDailyStatus.fromJson({
        'status': 'off',
        'label': 'Off Day',
        'short_code': 'OFF',
        'is_day_off': true,
      });

      expect(off.isOff, isTrue);
      expect(off.isWork, isFalse);
      expect(off.isDayOff, isTrue);
      expect(off.shortCode, 'OFF');

      final work = MemberDailyStatus.fromJson({
        'status': 'work',
        'label': 'Day Shift',
        'short_code': '08–16',
        'is_day_off': false,
        'start_time': '08:00',
        'end_time': '16:00',
        'is_overnight': false,
        'notes': 'Ward 4B',
      });

      expect(work.isWork, isTrue);
      expect(work.isOff, isFalse);
      expect(work.startTime, '08:00');
      expect(work.endTime, '16:00');
      expect(work.notes, 'Ward 4B');
      expect(work.isOvernight, isFalse);

      final leave = MemberDailyStatus.fromJson({
        'status': 'leave',
        'label': 'Annual Leave',
        'short_code': 'A/L',
        'is_day_off': true,
      });
      expect(leave.isLeave, isTrue);

      final study = MemberDailyStatus.fromJson({
        'status': 'study',
        'label': 'Dev Day',
        'short_code': 'DEV',
        'is_day_off': false,
      });
      expect(study.isStudy, isTrue);

      final busy = MemberDailyStatus.fromJson({
        'status': 'busy',
        'label': 'Busy',
        'short_code': 'BUSY',
        'is_day_off': false,
      });
      expect(busy.isBusy, isTrue);

      final unknown = MemberDailyStatus.fromJson({
        'status': 'unknown',
        'label': 'Unknown Schedule',
        'short_code': '—',
        'is_day_off': false,
      });
      expect(unknown.isUnknown, isTrue);
    });

    test('serializes to json correctly', () {
      const status = MemberDailyStatus(
        status: 'work',
        label: 'Night Shift',
        shortCode: '20–08',
        isDayOff: false,
        startTime: '20:00',
        endTime: '08:00',
        isOvernight: true,
      );

      final json = status.toJson();
      expect(json['status'], 'work');
      expect(json['short_code'], '20–08');
      expect(json['is_overnight'], isTrue);
    });
  });

  group('RosterUserSummary Model Tests', () {
    test('parses json and formats handle', () {
      final user = RosterUserSummary.fromJson({
        'id': 10,
        'name': 'Sarah Connor',
        'handle': 'sconnor',
        'initials': 'SC',
      });

      expect(user.id, 10);
      expect(user.name, 'Sarah Connor');
      expect(user.displayHandle, '@sconnor');
      expect(user.initials, 'SC');

      const noHandle = RosterUserSummary(id: 11, name: 'John Doe', initials: 'JD');
      expect(noHandle.displayHandle, '');
    });
  });

  group('CircleRosterMember Model Tests', () {
    test('parses member with dailyStatus and availability map', () {
      final json = {
        'user': {
          'id': 1,
          'name': 'Alice Smith',
          'handle': 'asmith',
          'initials': 'AS',
        },
        'visibility': 'shifts',
        'daily_status': {
          '2026-10-15': {
            'status': 'work',
            'label': 'Day Duty',
            'short_code': '08–16',
            'is_day_off': false,
            'start_time': '08:00',
            'end_time': '16:00',
          },
          '2026-10-16': {
            'status': 'off',
            'label': 'Off Day',
            'short_code': 'OFF',
            'is_day_off': true,
          },
        },
        'availability': {
          '2026-10-15': [
            {'start': '16:00', 'end': '24:00', 'status': 'free'},
          ],
        },
      };

      final member = CircleRosterMember.fromJson(json);

      expect(member.user.name, 'Alice Smith');
      expect(member.visibility, 'shifts');
      expect(member.dailyStatus.length, 2);
      expect(member.dailyStatus['2026-10-15']!.isWork, isTrue);
      expect(member.dailyStatus['2026-10-16']!.isOff, isTrue);
      expect(member.availability['2026-10-15']!.first['start'], '16:00');
    });
  });

  group('DaysOffDateSummary Model Tests', () {
    test('parses free and working members', () {
      final json = {
        'free_count': 2,
        'total_count': 3,
        'all_free': false,
        'free_members': [
          {'id': 1, 'name': 'Alice', 'initials': 'A'},
          {'id': 2, 'name': 'Bob', 'initials': 'B'},
        ],
        'working_members': [
          {'id': 3, 'name': 'Charlie', 'initials': 'C'},
        ],
        'unknown_members': [],
      };

      final summary = DaysOffDateSummary.fromJson(json);

      expect(summary.freeCount, 2);
      expect(summary.totalCount, 3);
      expect(summary.allFree, isFalse);
      expect(summary.freeMembers.length, 2);
      expect(summary.workingMembers.length, 1);
      expect(summary.unknownMembers.isEmpty, isTrue);
    });
  });

  group('OffTimeDateSummary Model Tests', () {
    test('parses best window and overlap intervals', () {
      final json = {
        'best_window': {
          'start': '18:00',
          'end': '22:00',
          'duration_minutes': 240,
          'duration_formatted': '4.0 hrs',
        },
        'has_overlap': true,
        'free_count': 3,
        'total_count': 3,
        'all_free': true,
        'free_members': [
          {'id': 1, 'name': 'Alice', 'initials': 'A'},
        ],
        'common_intervals': [
          {'start': '18:00', 'end': '22:00', 'status': 'free'},
        ],
      };

      final summary = OffTimeDateSummary.fromJson(json);

      expect(summary.hasOverlap, isTrue);
      expect(summary.allFree, isTrue);
      expect(summary.bestWindow, isNotNull);
      expect(summary.bestWindow!.start, '18:00');
      expect(summary.bestWindow!.end, '22:00');
      expect(summary.bestWindow!.durationFormatted, '4.0 hrs');
      expect(summary.commonIntervals.length, 1);
    });
  });

  group('MatchSuggestion & CirclePlanSummary Model Tests', () {
    test('parses suggestion scores and dates', () {
      final json = {
        'date': '2026-10-18',
        'start': '14:00',
        'end': '19:00',
        'duration_hours': 5.0,
        'score': 95.5,
      };

      final suggestion = MatchSuggestion.fromJson(json);

      expect(suggestion.date, '2026-10-18');
      expect(suggestion.start, '14:00');
      expect(suggestion.end, '19:00');
      expect(suggestion.durationHours, 5.0);
      expect(suggestion.score, 95.5);
    });

    test('parses circle plan summary', () {
      final json = {
        'id': 105,
        'title': 'Dinner at Trattoria',
        'event_type': 'meal',
        'date': '2026-10-18',
        'start_time': '19:00',
        'end_time': '21:30',
        'status': 'confirmed',
        'created_by': 'Dr. Connor',
        'members_count': 4,
      };

      final plan = CirclePlanSummary.fromJson(json);

      expect(plan.id, 105);
      expect(plan.title, 'Dinner at Trattoria');
      expect(plan.eventType, 'meal');
      expect(plan.date, '2026-10-18');
      expect(plan.startTime, '19:00');
      expect(plan.endTime, '21:30');
      expect(plan.status, 'confirmed');
      expect(plan.createdBy, 'Dr. Connor');
      expect(plan.membersCount, 4);
    });
  });

  group('CircleAvailabilityData Top-Level Model Tests', () {
    test('parses aggregated availability response', () {
      final json = {
        'members': [
          {
            'user': {'id': 1, 'name': 'Doc Brown', 'initials': 'DB'},
            'visibility': 'shifts',
            'daily_status': {
              '2026-10-20': {'status': 'off', 'label': 'Off', 'short_code': 'OFF', 'is_day_off': true}
            },
            'availability': {},
          }
        ],
        'common_availability': {
          '2026-10-20': [
            {'start': '00:00', 'end': '24:00', 'status': 'free'}
          ]
        },
        'days_off': {
          '2026-10-20': {
            'free_count': 1,
            'total_count': 1,
            'all_free': true,
            'free_members': [],
            'working_members': [],
            'unknown_members': [],
          }
        },
        'off_time': {
          '2026-10-20': {
            'has_overlap': true,
            'free_count': 1,
            'total_count': 1,
            'all_free': true,
            'free_members': [],
            'common_intervals': [],
          }
        },
        'suggestions': [
          {'date': '2026-10-20', 'start': '10:00', 'end': '15:00', 'duration_hours': 5.0, 'score': 100.0}
        ],
        'plans': [],
      };

      final data = CircleAvailabilityData.fromJson(json);

      expect(data.members.length, 1);
      expect(data.commonAvailability['2026-10-20']!.length, 1);
      expect(data.daysOff['2026-10-20']!.allFree, isTrue);
      expect(data.offTime['2026-10-20']!.hasOverlap, isTrue);
      expect(data.suggestions.first.score, 100.0);
    });
  });

  group('MatchingRepository Tests', () {
    late FakeApiClient fakeApi;
    late MatchingRepository repository;

    setUp(() {
      fakeApi = FakeApiClient();
      repository = MatchingRepository(apiClient: fakeApi);
    });

    test('getCircleAvailability calls GET /circles/{id}/availability with query params', () async {
      fakeApi.nextGetResponse = {
        'data': {
          'members': [],
          'common_availability': {},
          'days_off': {},
          'off_time': {},
          'suggestions': [],
          'plans': [],
        }
      };

      final result = await repository.getCircleAvailability(
        circleId: 42,
        startDate: '2026-10-01',
        endDate: '2026-10-31',
      );

      expect(fakeApi.lastGetPath, '/circles/42/availability');
      expect(fakeApi.lastGetParams?['start_date'], '2026-10-01');
      expect(fakeApi.lastGetParams?['end_date'], '2026-10-31');
      expect(result.members.isEmpty, isTrue);
    });

    test('compareUsers calls POST /availability/compare with payload', () async {
      fakeApi.nextPostResponse = {
        'data': {
          'members': [],
          'common_availability': {},
          'days_off': {},
          'off_time': {},
          'suggestions': [],
          'plans': [],
        }
      };

      final result = await repository.compareUsers(
        userIds: [1, 2, 3],
        startDate: '2026-10-10',
        endDate: '2026-10-20',
        circleId: 99,
      );

      expect(fakeApi.lastPostPath, '/availability/compare');
      expect(fakeApi.lastPostData['user_ids'], [1, 2, 3]);
      expect(fakeApi.lastPostData['start_date'], '2026-10-10');
      expect(fakeApi.lastPostData['end_date'], '2026-10-20');
      expect(fakeApi.lastPostData['circle_id'], 99);
      expect(result.suggestions.isEmpty, isTrue);
    });
  });
}
