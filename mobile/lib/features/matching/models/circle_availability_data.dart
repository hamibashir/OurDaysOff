import 'circle_plan_summary.dart';
import 'circle_roster_member.dart';
import 'days_off_summary.dart';
import 'match_suggestion.dart';
import 'off_time_summary.dart';

class CircleAvailabilityData {
  final List<CircleRosterMember> members;
  final Map<String, List<Map<String, dynamic>>> commonAvailability;
  final Map<String, DaysOffDateSummary> daysOff;
  final Map<String, OffTimeDateSummary> offTime;
  final List<MatchSuggestion> suggestions;
  final List<CirclePlanSummary> plans;

  const CircleAvailabilityData({
    this.members = const [],
    this.commonAvailability = const {},
    this.daysOff = const {},
    this.offTime = const {},
    this.suggestions = const [],
    this.plans = const [],
  });

  factory CircleAvailabilityData.fromJson(Map<String, dynamic> json) {
    // 1. Members
    final rawMembers = json['members'] as List? ?? [];
    final members = rawMembers
        .whereType<Map>()
        .map((m) => CircleRosterMember.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // 2. Common Availability
    final rawCommon = json['common_availability'] is Map
        ? Map<String, dynamic>.from(json['common_availability'] as Map)
        : <String, dynamic>{};
    final commonAvailability = rawCommon.map(
      (k, v) => MapEntry(
        k,
        v is List
            ? v
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
            : <Map<String, dynamic>>[],
      ),
    );

    // 3. Days Off Summary
    final rawDaysOff = json['days_off'] is Map
        ? Map<String, dynamic>.from(json['days_off'] as Map)
        : <String, dynamic>{};
    final daysOff = rawDaysOff.map(
      (k, v) => MapEntry(
        k,
        v is Map
            ? DaysOffDateSummary.fromJson(Map<String, dynamic>.from(v))
            : const DaysOffDateSummary(freeCount: 0, totalCount: 0, allFree: false),
      ),
    );

    // 4. Off Time Summary
    final rawOffTime = json['off_time'] is Map
        ? Map<String, dynamic>.from(json['off_time'] as Map)
        : <String, dynamic>{};
    final offTime = rawOffTime.map(
      (k, v) => MapEntry(
        k,
        v is Map
            ? OffTimeDateSummary.fromJson(Map<String, dynamic>.from(v))
            : const OffTimeDateSummary(hasOverlap: false, freeCount: 0, totalCount: 0, allFree: false),
      ),
    );

    // 5. Suggestions
    final rawSuggestions = json['suggestions'] as List? ?? [];
    final suggestions = rawSuggestions
        .whereType<Map>()
        .map((s) => MatchSuggestion.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    // 6. Plans
    final rawPlans = json['plans'] as List? ?? [];
    final plans = rawPlans
        .whereType<Map>()
        .map((p) => CirclePlanSummary.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    return CircleAvailabilityData(
      members: members,
      commonAvailability: commonAvailability,
      daysOff: daysOff,
      offTime: offTime,
      suggestions: suggestions,
      plans: plans,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'members': members.map((m) => m.toJson()).toList(),
      'common_availability': commonAvailability,
      'days_off': daysOff.map((k, v) => MapEntry(k, v.toJson())),
      'off_time': offTime.map((k, v) => MapEntry(k, v.toJson())),
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'plans': plans.map((p) => p.toJson()).toList(),
    };
  }
}
