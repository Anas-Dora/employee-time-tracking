import '../dayOverview/day_overview.dart';

class WorkDay {
  final DateTime date;
  final String start;
  final String end;
  final String pause;
  final String total;
  final String diff;
  final DayType type;

  WorkDay({
    required this.date,
    this.start = '-',
    this.end = '-',
    this.pause = '-',
    this.total = '-',
    this.diff = '-',
    this.type = DayType.none,
  });

  WorkDay copyWith({
    DateTime? date,
    String? start,
    String? end,
    String? pause,
    String? total,
    String? diff,
    DayType? type,
  }) {
    return WorkDay(
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      pause: pause ?? this.pause,
      total: total ?? this.total,
      diff: diff ?? this.diff,
      type: type ?? this.type,
    );
  }
}