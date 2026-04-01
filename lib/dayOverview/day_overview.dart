
enum DayType { workday, sick, vacation, none }

class DayOverview {
  final DateTime date;
  final DayType type;
  final bool isHoliday;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? breakDuration;

  DayOverview({
    required this.date,
    required this.type,
    this.isHoliday = false,
    this.startTime,
    this.endTime,
    this.breakDuration,
  });

  DayOverview copyWith({
    DateTime? date,
    DayType? type,
    bool? isHoliday,
    DateTime? startTime,
    DateTime? endTime,
    Duration? breakDuration,
  }) {
    return DayOverview(
      date: date ?? this.date,
      type: type ?? this.type,
      isHoliday: isHoliday ?? this.isHoliday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration: breakDuration ?? this.breakDuration,
    );
  }

  Duration? get workDuration {
    if (isHoliday) return null;
    if (type != DayType.workday) return null;
    if (startTime == null || endTime == null) return null;

    final pause = breakDuration ?? Duration.zero;
    return endTime!.difference(startTime!) - pause;
  }

  /// Konvertierung für SQLite
  Map<String, dynamic> toMap() {
    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'type': type.name,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'break_minutes': breakDuration?.inMinutes ?? 0,
    };
  }

  factory DayOverview.fromMap(Map<String, dynamic> map) {
    return DayOverview(
      date: DateTime.parse(map['date'] as String),
      type: DayType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => DayType.none,
      ),
      isHoliday: (map['is_holiday'] as int?) == 1,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      breakDuration: map['break_minutes'] != null
          ? Duration(minutes: map['break_minutes'] as int)
          : null,
    );
  }
}