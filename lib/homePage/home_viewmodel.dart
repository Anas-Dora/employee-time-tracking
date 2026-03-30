// viewmodels/home_viewmodel.dart
import 'dart:async';

import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/homePage/work_time.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../dayOverview/day_overview.dart';


class HomeState {
  final bool isRunning;
  final bool isOnBreak;
  final WorkTime workTime;
  final WorkTime breakTime;
  /// Zeitpunkt, zu dem der Timer heute gestartet wurde
  final DateTime? startedAt;

  HomeState({
    required this.isRunning,
    required this.isOnBreak,
    required this.workTime,
    required this.breakTime,
    this.startedAt,
  });

  HomeState copyWith({
    bool? isRunning,
    bool? isOnBreak,
    WorkTime? workTime,
    WorkTime? breakTime,
    DateTime? startedAt,
  }) {
    return HomeState(
      isRunning: isRunning ?? this.isRunning,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      workTime: workTime ?? this.workTime,
      breakTime: breakTime ?? this.breakTime,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  Timer? _timer;

  HomeViewModel()
      : super(HomeState(
    isRunning: false,
    isOnBreak: false,
    workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
    breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
  )) {
    _loadTodayFromDb();
  }

  /// Explizites Reload vom Home-Tab (z. B. bei erneutem Tab-Klick).
  Future<void> loadToday() async {
    if (state.isRunning || state.isOnBreak) return;
    await _loadTodayFromDb();
  }

  /// Heutigen Eintrag aus DB laden (falls vorhanden)
  Future<void> _loadTodayFromDb() async {
    final today = DateTime.now();
    final entry = await DatabaseHelper.instance.getDayEntry(today);
    if (entry == null) {
      state = state.copyWith(
        startedAt: null,
        workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
        breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      );
      return;
    }

    final day = DayOverview.fromMap(entry);
    if (day.type != DayType.workday) {
      state = state.copyWith(
        startedAt: null,
        workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
        breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      );
      return;
    }

    final workedMinutes = day.workDuration?.inMinutes ?? 0;
    final breakMinutes = day.breakDuration?.inMinutes ?? 0;
    state = state.copyWith(
      startedAt: day.startTime,
      workTime: WorkTime(
        hours: workedMinutes ~/ 60,
        minutes: workedMinutes % 60,
        seconds: 0,
      ),
      breakTime: WorkTime(
        hours: breakMinutes ~/ 60,
        minutes: breakMinutes % 60,
        seconds: 0,
      ),
    );
  }

  void startWorkTimer() {
    if(state.isOnBreak){
      pauseBreakTimer();
    }
    if (!state.isRunning) {
      _timer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
      state = state.copyWith(
        isRunning: true,
        isOnBreak: false,
        startedAt: state.startedAt ?? DateTime.now(),
      );
    }
  }

  void startBreakTimer() {
    if (!state.isOnBreak) {
      pauseWorkTimer();
      _timer = Timer.periodic(Duration(seconds: 1), (_) => _tickBreak());
      state = state.copyWith(isOnBreak: true, isRunning: false);
    }
  }

  void pauseWorkTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void pauseBreakTimer() {
    _timer?.cancel();
    state = state.copyWith(isOnBreak: false);
  }

  Future<void> stopTimer() async {
    _timer?.cancel();

    final now = DateTime.now();
    final wt = state.workTime;
    final bt = state.breakTime;
    final startedAt = state.startedAt ?? now.subtract(
      Duration(
        hours: wt.hours,
        minutes: wt.minutes,
        seconds: wt.seconds,
      ),
    );

    // Arbeitstag in SQLite speichern
    final day = DayOverview(
      date: DateTime(now.year, now.month, now.day),
      type: DayType.workday,
      startTime: startedAt,
      endTime: now,
      breakDuration: Duration(
        hours: bt.hours,
        minutes: bt.minutes,
        seconds: bt.seconds,
      ),
    );
    await DatabaseHelper.instance.upsertDayEntry(day.toMap());

    state = state.copyWith(
      isRunning: false,
      isOnBreak: false,
      workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      startedAt: null,
    );
  }

  void _tick() {
    final wt = state.workTime;
    int newSeconds = wt.seconds + 1;
    int newMinutes = wt.minutes;
    int newHours = wt.hours;

    if (newSeconds >= 60) {
      newSeconds = 0;
      newMinutes += 1;
    }

    if (newMinutes >= 60) {
      newMinutes = 0;
      newHours += 1;
    }

    state = state.copyWith(
      workTime: wt.copyWith(hours: newHours, minutes: newMinutes, seconds: newSeconds),
    );
  }

  void _tickBreak() {
    final bt = state.breakTime;
    int newSeconds = bt.seconds + 1;
    int newMinutes = bt.minutes;
    int newHours = bt.hours;

    if (newSeconds >= 60) {
      newSeconds = 0;
      newMinutes += 1;
    }

    if (newMinutes >= 60) {
      newMinutes = 0;
      newHours += 1;
    }

    state = state.copyWith(
      breakTime: bt.copyWith(hours: newHours, minutes: newMinutes, seconds: newSeconds),
    );
  }

  double progress() {
    final totalSeconds = state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    return (totalSeconds / (8 * 3600)).clamp(0.0, 1.0);
  }

  String remainingTime() {
    const dailyTargetSeconds = 8 * 3600;
    final workedSeconds =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    final remainingSeconds = (dailyTargetSeconds - workedSeconds).clamp(0, dailyTargetSeconds);
    final remainingTotalMinutes = (remainingSeconds / 60).ceil();
    final remainingHours = remainingTotalMinutes ~/ 60;
    final remainingMinutes = remainingTotalMinutes % 60;

    return 'Noch ${remainingHours}h ${remainingMinutes}m';
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel();
});