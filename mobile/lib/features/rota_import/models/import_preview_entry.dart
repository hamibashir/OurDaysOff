class ImportPreviewEntry {
  final String date; // YYYY-MM-DD
  final String shiftLabel;
  final String label;
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final String entryType; // work, leave, off, personal, other
  final bool isOvernight;

  const ImportPreviewEntry({
    required this.date,
    required this.shiftLabel,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.entryType = 'work',
    this.isOvernight = false,
  });

  bool get isDayOff => entryType.toLowerCase() == 'off';

  factory ImportPreviewEntry.fromJson(Map<String, dynamic> json) {
    final rawLabel = json['shift_label']?.toString() ?? json['label']?.toString() ?? 'Imported Shift';
    final start = json['start_time']?.toString() ?? '09:00';
    final end = json['end_time']?.toString() ?? '17:00';

    bool overnight = false;
    if (json['is_overnight'] != null) {
      if (json['is_overnight'] is bool) {
        overnight = json['is_overnight'] as bool;
      } else {
        overnight = json['is_overnight'].toString() == '1' || json['is_overnight'].toString().toLowerCase() == 'true';
      }
    } else {
      // Auto-detect if end time is before start time
      overnight = end.compareTo(start) < 0;
    }

    return ImportPreviewEntry(
      date: json['date']?.toString() ?? '',
      shiftLabel: rawLabel,
      label: rawLabel,
      startTime: start,
      endTime: end,
      entryType: json['entry_type']?.toString().toLowerCase() ?? 'work',
      isOvernight: overnight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'shift_label': shiftLabel,
      'label': label,
      'start_time': startTime,
      'end_time': endTime,
      'entry_type': entryType,
      'is_overnight': isOvernight,
    };
  }

  ImportPreviewEntry copyWith({
    String? date,
    String? shiftLabel,
    String? label,
    String? startTime,
    String? endTime,
    String? entryType,
    bool? isOvernight,
  }) {
    final newLabel = label ?? shiftLabel ?? this.label;
    return ImportPreviewEntry(
      date: date ?? this.date,
      shiftLabel: shiftLabel ?? newLabel,
      label: newLabel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      entryType: entryType ?? this.entryType,
      isOvernight: isOvernight ?? this.isOvernight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportPreviewEntry &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          shiftLabel == other.shiftLabel &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          entryType == other.entryType &&
          isOvernight == other.isOvernight;

  @override
  int get hashCode =>
      date.hashCode ^
      shiftLabel.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      entryType.hashCode ^
      isOvernight.hashCode;
}
