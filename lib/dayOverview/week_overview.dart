// models/week_overview.dart
import 'day_overview.dart';

class WeekOverview {
  final DateTime startDate; // Montag
  final DateTime endDate;   // Freitag
  final List<DayOverview> days;

  WeekOverview({
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  WeekOverview copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<DayOverview>? days,
  }) {
    return WeekOverview(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
    );
  }

  Duration get totalWork => days.fold( // Gesamtarbeitszeit der Woche
      Duration.zero,
      (prev, day) => prev + (day.workDuration ?? Duration.zero));

  Duration get averageBreak { // durchschnittliche Pause pro Tag
    final workdays = days.where((day) => day.type == DayType.workday).toList();
    if (workdays.isEmpty) return Duration.zero;

    int totalMinutes = workdays.fold(
      0,
      (prev, day) => prev + (day.breakDuration?.inMinutes ?? 0),
    );
    return Duration(minutes: totalMinutes ~/ workdays.length);
  }
}