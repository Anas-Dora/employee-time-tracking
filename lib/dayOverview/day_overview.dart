
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

  Duration? get workDuration {
    if (startTime == null || endTime == null) return null;

    final pause = breakDuration ?? Duration.zero;
    return endTime!.difference(startTime!) - pause;
  }
}