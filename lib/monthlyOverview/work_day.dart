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

  /// Konvertierung für SQLite: WorkDay → DayOverview → Map
  Map<String, dynamic> toMap() {
    DateTime? startDt;
    DateTime? endDt;
    int breakMinutes = 0;

    if (start != '-' && start.isNotEmpty) {
      final parts = start.split(':');
      if (parts.length == 2) {
        startDt = DateTime(date.year, date.month, date.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }
    }

    if (end != '-' && end.isNotEmpty) {
      final parts = end.split(':');
      if (parts.length == 2) {
        endDt = DateTime(date.year, date.month, date.day,
            int.parse(parts[0]), int.parse(parts[1]));
      }
    }

    if (pause != '-' && pause.isNotEmpty) {
      breakMinutes = int.tryParse(pause) ?? 0;
    }

    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'type': type.name,
      'start_time': startDt?.toIso8601String(),
      'end_time': endDt?.toIso8601String(),
      'break_minutes': breakMinutes,
    };
  }

  factory WorkDay.fromMap(Map<String, dynamic> map) {
    final date = DateTime.parse(map['date'] as String);
    final type = DayType.values.firstWhere(
      (e) => e.name == (map['type'] as String),
      orElse: () => DayType.none,
    );

    String startStr = '-';
    String endStr = '-';
    String pauseStr = '-';

    if (map['start_time'] != null) {
      final dt = DateTime.parse(map['start_time'] as String);
      startStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    if (map['end_time'] != null) {
      final dt = DateTime.parse(map['end_time'] as String);
      endStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    if (map['break_minutes'] != null && (map['break_minutes'] as int) > 0) {
      pauseStr = (map['break_minutes'] as int).toString();
    }

    return WorkDay(
      date: date,
      type: type,
      start: startStr,
      end: endStr,
      pause: pauseStr,
    );
  }
}