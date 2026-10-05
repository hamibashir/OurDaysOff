import 'member_daily_status.dart';
import 'roster_user_summary.dart';

class CircleRosterMember {
  final RosterUserSummary user;
  final String visibility; // 'free_busy' | 'shifts' | 'details'
  final Map<String, MemberDailyStatus> dailyStatus;
  final Map<String, List<Map<String, dynamic>>> availability;

  const CircleRosterMember({
    required this.user,
    this.visibility = 'free_busy',
    this.dailyStatus = const {},
    this.availability = const {},
  });

  String get visibilityLabel {
    switch (visibility.toLowerCase()) {
      case 'shifts':
        return 'SHIFTS';
      case 'details':
        return 'DETAILS';
      case 'free_busy':
      default:
        return 'FREE/BUSY';
    }
  }

  factory CircleRosterMember.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};
    final user = RosterUserSummary.fromJson(userRaw);

    final dailyStatusRaw = json['daily_status'] is Map
        ? Map<String, dynamic>.from(json['daily_status'] as Map)
        : <String, dynamic>{};
    final dailyStatus = dailyStatusRaw.map(
      (key, value) => MapEntry(
        key,
        value is Map
            ? MemberDailyStatus.fromJson(Map<String, dynamic>.from(value))
            : const MemberDailyStatus(
                status: 'unknown',
                label: 'Unknown',
                shortCode: '—',
                isDayOff: false,
              ),
      ),
    );

    final rawAvailability = json['availability'] is Map
        ? Map<String, dynamic>.from(json['availability'] as Map)
        : <String, dynamic>{};
    final availability = rawAvailability.map(
      (key, value) => MapEntry(
        key,
        value is List
            ? value
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
            : <Map<String, dynamic>>[],
      ),
    );

    return CircleRosterMember(
      user: user,
      visibility: json['visibility'] as String? ?? 'free_busy',
      dailyStatus: dailyStatus,
      availability: availability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'visibility': visibility,
      'daily_status': dailyStatus.map((k, v) => MapEntry(k, v.toJson())),
      'availability': availability,
    };
  }
}
