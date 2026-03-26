
enum DayType { workday, sick, vacation, none }

class DayOverview {
  final DateTime date;
  final DayType type;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? breakDuration;

  DayOverview({
    required this.date,
    required this.type,
    this.startTime,
    this.endTime,
    this.breakDuration,
  });

  DayOverview copyWith({
    DateTime? date,
    DayType? type,
    DateTime? startTime,
    DateTime? endTime,
    Duration? breakDuration,
  }) {
    return DayOverview(
      date: date ?? this.date,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration: breakDuration ?? this.breakDuration,
    );
  }

  Duration? get workDuration {
    if (type != DayType.workday) return null;
    if (startTime == null || endTime == null) return null;

    final pause = breakDuration ?? Duration.zero;
    return endTime!.difference(startTime!) - pause;
  }
}