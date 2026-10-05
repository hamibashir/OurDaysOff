class MatchSuggestion {
  final String date;
  final String start;
  final String end;
  final double durationHours;
  final double score;
  final List<String> reasons;
  final bool isMagicHour;

  const MatchSuggestion({
    required this.date,
    required this.start,
    required this.end,
    required this.durationHours,
    required this.score,
    this.reasons = const [],
    this.isMagicHour = false,
  });

  factory MatchSuggestion.fromJson(Map<String, dynamic> json) {
    final rawReasons = json['reasons'];
    List<String> parsedReasons = [];
    if (rawReasons is List) {
      parsedReasons = rawReasons.map((r) => r.toString()).toList();
    }

    return MatchSuggestion(
      date: json['date'] as String? ?? '',
      start: json['start'] as String? ?? '00:00',
      end: json['end'] as String? ?? '00:00',
      durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      reasons: parsedReasons,
      isMagicHour: json['is_magic_hour'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'start': start,
      'end': end,
      'duration_hours': durationHours,
      'score': score,
      'reasons': reasons,
      'is_magic_hour': isMagicHour,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchSuggestion &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          start == other.start &&
          end == other.end &&
          durationHours == other.durationHours &&
          score == other.score &&
          isMagicHour == other.isMagicHour;

  @override
  int get hashCode =>
      date.hashCode ^
      start.hashCode ^
      end.hashCode ^
      durationHours.hashCode ^
      score.hashCode ^
      isMagicHour.hashCode;
}
