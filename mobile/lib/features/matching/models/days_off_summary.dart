import 'roster_user_summary.dart';

class DaysOffDateSummary {
  final int freeCount;
  final int totalCount;
  final bool allFree;
  final List<RosterUserSummary> freeMembers;
  final List<RosterUserSummary> workingMembers;
  final List<RosterUserSummary> unknownMembers;

  const DaysOffDateSummary({
    required this.freeCount,
    required this.totalCount,
    required this.allFree,
    this.freeMembers = const [],
    this.workingMembers = const [],
    this.unknownMembers = const [],
  });

  factory DaysOffDateSummary.fromJson(Map<String, dynamic> json) {
    List<RosterUserSummary> parseUsers(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((u) => RosterUserSummary.fromJson(u))
            .toList();
      }
      return [];
    }

    return DaysOffDateSummary(
      freeCount: json['free_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      allFree: json['all_free'] as bool? ?? false,
      freeMembers: parseUsers(json['free_members']),
      workingMembers: parseUsers(json['working_members']),
      unknownMembers: parseUsers(json['unknown_members']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'free_count': freeCount,
      'total_count': totalCount,
      'all_free': allFree,
      'free_members': freeMembers.map((m) => m.toJson()).toList(),
      'working_members': workingMembers.map((m) => m.toJson()).toList(),
      'unknown_members': unknownMembers.map((m) => m.toJson()).toList(),
    };
  }
}
