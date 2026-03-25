// models/work_time.dart
class WorkTime {
  final int hours;
  final int minutes;
  final int seconds;

  WorkTime({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  WorkTime copyWith({int? hours, int? minutes, int? seconds}) {
    return WorkTime(
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
    );
  }

  String get formatted => '${hours.toString().padLeft(2,'0')}:${minutes.toString().padLeft(2,'0')}:${seconds.toString().padLeft(2,'0')}';
}