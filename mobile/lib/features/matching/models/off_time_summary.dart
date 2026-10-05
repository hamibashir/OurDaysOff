import 'roster_user_summary.dart';

class BestWindow {
  final String start;
  final String end;
  final int durationMinutes;
  final String durationFormatted;

  const BestWindow({
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.durationFormatted,
  });

  factory BestWindow.fromJson(Map<String, dynamic> json) {
    return BestWindow(
      start: json['start'] as String? ?? '00:00',
      end: json['end'] as String? ?? '00:00',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      durationFormatted: json['duration_formatted'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'duration_minutes': durationMinutes,
      'duration_formatted': durationFormatted,
    };
  }
}

class OffTimeDateSummary {
  final BestWindow? bestWindow;
  final bool hasOverlap;
  final int freeCount;
  final int totalCount;
  final bool allFree;
  final List<RosterUserSummary> freeMembers;
  final List<Map<String, dynamic>> commonIntervals;

  const OffTimeDateSummary({
    this.bestWindow,
    required this.hasOverlap,
    required this.freeCount,
    required this.totalCount,
    required this.allFree,
    this.freeMembers = const [],
    this.commonIntervals = const [],
  });

  factory OffTimeDateSummary.fromJson(Map<String, dynamic> json) {
    List<RosterUserSummary> parseUsers(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((u) => RosterUserSummary.fromJson(u))
            .toList();
      }
      return [];
    }

    final rawIntervals = json['common_intervals'] as List? ?? [];
    final commonIntervals = rawIntervals.whereType<Map<String, dynamic>>().toList();

    return OffTimeDateSummary(
      bestWindow: json['best_window'] is Map<String, dynamic>
          ? BestWindow.fromJson(json['best_window'] as Map<String, dynamic>)
          : null,
      hasOverlap: json['has_overlap'] as bool? ?? false,
      freeCount: json['free_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      allFree: json['all_free'] as bool? ?? false,
      freeMembers: parseUsers(json['free_members']),
      commonIntervals: commonIntervals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bestWindow != null) 'best_window': bestWindow!.toJson(),
      'has_overlap': hasOverlap,
      'free_count': freeCount,
      'total_count': totalCount,
      'all_free': allFree,
      'free_members': freeMembers.map((m) => m.toJson()).toList(),
      'common_intervals': commonIntervals,
    };
  }
}
