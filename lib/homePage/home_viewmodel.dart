// viewmodels/home_viewmodel.dart
import 'dart:async';

import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/homePage/work_time.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dayOverview/day_overview.dart';


// SharedPreferences-Schlüssel
const _kIsRunning = 'timer_is_running';
const _kIsOnBreak = 'timer_is_on_break';
const _kWorkStartMs = 'timer_work_start_ms';
const _kBreakStartMs = 'timer_break_start_ms';
// Bereits akkumulierte Arbeitszeit in Sekunden (vor aktuellem Lauf)
const _kAccumulatedWorkSec = 'timer_accumulated_work_sec';
// Bereits akkumulierte Pausenzeit in Sekunden (vor aktuellem Lauf)
const _kAccumulatedBreakSec = 'timer_accumulated_break_sec';

class HomeState {
  final bool isRunning;
  final bool isOnBreak;
  final WorkTime workTime;
  final WorkTime breakTime;
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
    bool clearStartedAt = false,
  }) {
    return HomeState(
      isRunning: isRunning ?? this.isRunning,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      workTime: workTime ?? this.workTime,
      breakTime: breakTime ?? this.breakTime,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
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
    _init();
  }

  Future<void> _init() async {
    await _restoreTimerState();
  }

  // ──────────────────────────────────────────────────────────────
  // Persistenz
  // ──────────────────────────────────────────────────────────────

  Future<void> _saveTimerState({
    required bool isRunning,
    required bool isOnBreak,
    DateTime? workStartedAt,
    DateTime? breakStartedAt,
    required int accumulatedWorkSec,
    required int accumulatedBreakSec,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsRunning, isRunning);
    await prefs.setBool(_kIsOnBreak, isOnBreak);
    await prefs.setInt(_kAccumulatedWorkSec, accumulatedWorkSec);
    await prefs.setInt(_kAccumulatedBreakSec, accumulatedBreakSec);
    if (workStartedAt != null) {
      await prefs.setInt(_kWorkStartMs, workStartedAt.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_kWorkStartMs);
    }
    if (breakStartedAt != null) {
      await prefs.setInt(_kBreakStartMs, breakStartedAt.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_kBreakStartMs);
    }
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool(_kIsRunning) ?? false;
    final isOnBreak = prefs.getBool(_kIsOnBreak) ?? false;
    final accWorkSec = prefs.getInt(_kAccumulatedWorkSec) ?? 0;
    final accBreakSec = prefs.getInt(_kAccumulatedBreakSec) ?? 0;
    final workStartMs = prefs.getInt(_kWorkStartMs);
    final breakStartMs = prefs.getInt(_kBreakStartMs);

    if (!isRunning && !isOnBreak) {
      await _loadTodayFromDb();
      return;
    }

    final now = DateTime.now();

    // Arbeitszeit berechnen (akkumuliert + laufender Abschnitt)
    int totalWorkSec = accWorkSec;
    DateTime? workStart;
    if (isRunning && workStartMs != null) {
      workStart = DateTime.fromMillisecondsSinceEpoch(workStartMs);
      totalWorkSec += now.difference(workStart).inSeconds;
    }

    // Pausenzeit berechnen
    int totalBreakSec = accBreakSec;
    DateTime? breakStart;
    if (isOnBreak && breakStartMs != null) {
      breakStart = DateTime.fromMillisecondsSinceEpoch(breakStartMs);
      totalBreakSec += now.difference(breakStart).inSeconds;
    }

    final startedAt = workStartMs != null
        ? DateTime.fromMillisecondsSinceEpoch(workStartMs)
        : (workStart ?? now);

    state = HomeState(
      isRunning: isRunning,
      isOnBreak: isOnBreak,
      workTime: _secondsToWorkTime(totalWorkSec),
      breakTime: _secondsToWorkTime(totalBreakSec),
      startedAt: startedAt,
    );

    if (isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (isOnBreak) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickBreak());
    }
  }

  // ──────────────────────────────────────────────────────────────

  Future<void> loadToday() async {
    if (state.isRunning || state.isOnBreak) return;
    await _loadTodayFromDb();
  }

  Future<void> _loadTodayFromDb() async {
    final today = DateTime.now();
    final entry = await DatabaseHelper.instance.getDayEntry(today);
    if (entry == null) {
      state = state.copyWith(
        clearStartedAt: true,
        workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
        breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      );
      return;
    }

    final day = DayOverview.fromMap(entry);
    if (day.type != DayType.workday) {
      state = state.copyWith(
        clearStartedAt: true,
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

  // ──────────────────────────────────────────────────────────────
  // Timer-Steuerung
  // ──────────────────────────────────────────────────────────────

  void startWorkTimer() {
    if (state.isOnBreak) {
      pauseBreakTimer();
    }
    if (!state.isRunning) {
      final workStart = DateTime.now();
      final startedAt = state.startedAt ?? workStart;
      final accWorkSec =
          state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
      final accBreakSec =
          state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;

      _saveTimerState(
        isRunning: true,
        isOnBreak: false,
        workStartedAt: workStart,
        accumulatedWorkSec: accWorkSec,
        accumulatedBreakSec: accBreakSec,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      state = state.copyWith(
        isRunning: true,
        isOnBreak: false,
        startedAt: startedAt,
      );
    }
  }

  void startBreakTimer() {
    if (!state.isOnBreak) {
      pauseWorkTimer();
      final breakStart = DateTime.now();
      final accWorkSec =
          state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
      final accBreakSec =
          state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;

      _saveTimerState(
        isRunning: false,
        isOnBreak: true,
        breakStartedAt: breakStart,
        accumulatedWorkSec: accWorkSec,
        accumulatedBreakSec: accBreakSec,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickBreak());
      state = state.copyWith(isOnBreak: true, isRunning: false);
    }
  }

  void pauseWorkTimer() {
    _timer?.cancel();
    final accWorkSec =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    final accBreakSec =
        state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;
    _saveTimerState(
      isRunning: false,
      isOnBreak: false,
      accumulatedWorkSec: accWorkSec,
      accumulatedBreakSec: accBreakSec,
    );
    state = state.copyWith(isRunning: false);
  }

  void pauseBreakTimer() {
    _timer?.cancel();
    final accWorkSec =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    final accBreakSec =
        state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;
    _saveTimerState(
      isRunning: false,
      isOnBreak: false,
      accumulatedWorkSec: accWorkSec,
      accumulatedBreakSec: accBreakSec,
    );
    state = state.copyWith(isOnBreak: false);
  }

  Future<void> stopTimer() async {
    _timer?.cancel();

    final now = DateTime.now();
    final wt = state.workTime;
    final bt = state.breakTime;
    final startedAt = state.startedAt ??
        now.subtract(Duration(
          hours: wt.hours,
          minutes: wt.minutes,
          seconds: wt.seconds,
        ));

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

    // SharedPreferences leeren
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsRunning);
    await prefs.remove(_kIsOnBreak);
    await prefs.remove(_kWorkStartMs);
    await prefs.remove(_kBreakStartMs);
    await prefs.remove(_kAccumulatedWorkSec);
    await prefs.remove(_kAccumulatedBreakSec);

    state = state.copyWith(
      isRunning: false,
      isOnBreak: false,
      clearStartedAt: true,
      workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Tick
  // ──────────────────────────────────────────────────────────────

  void _tick() {
    final wt = state.workTime;
    int s = wt.seconds + 1;
    int m = wt.minutes;
    int h = wt.hours;
    if (s >= 60) { s = 0; m++; }
    if (m >= 60) { m = 0; h++; }
    state = state.copyWith(workTime: wt.copyWith(hours: h, minutes: m, seconds: s));
  }

  void _tickBreak() {
    final bt = state.breakTime;
    int s = bt.seconds + 1;
    int m = bt.minutes;
    int h = bt.hours;
    if (s >= 60) { s = 0; m++; }
    if (m >= 60) { m = 0; h++; }
    state = state.copyWith(breakTime: bt.copyWith(hours: h, minutes: m, seconds: s));
  }

  // ──────────────────────────────────────────────────────────────
  // Hilfsmethoden
  // ──────────────────────────────────────────────────────────────

  WorkTime _secondsToWorkTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return WorkTime(hours: h, minutes: m, seconds: s);
  }

  double progress() {
    final totalSeconds =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    return (totalSeconds / (8 * 3600)).clamp(0.0, 1.0);
  }

  String remainingTime() {
    const dailyTargetSeconds = 8 * 3600;
    final workedSeconds =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    final remainingSeconds =
        (dailyTargetSeconds - workedSeconds).clamp(0, dailyTargetSeconds);
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