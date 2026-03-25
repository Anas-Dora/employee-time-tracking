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

  Duration get totalWork => days.fold( // Gesamtarbeitszeit der Woche
      Duration.zero,
      (prev, day) => prev + (day.workDuration ?? Duration.zero));

  Duration get averageBreak { // durchschnittliche Pause pro Tag
    if (days.isEmpty) return Duration.zero;
    int totalMinutes = days.fold(
        0, (prev, day) => prev + (day.breakDuration?.inMinutes ?? 0));
    return Duration(minutes: totalMinutes ~/ days.length);
  }
}