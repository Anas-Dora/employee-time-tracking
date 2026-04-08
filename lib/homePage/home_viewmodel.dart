// viewmodels/home_viewmodel.dart
import 'dart:async';

import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/homePage/work_time.dart';
import 'package:employee_time_tracking/profile/profile_vm.dart';
import 'package:employee_time_tracking/services/notification_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dayOverview/day_overview.dart';


// SharedPreferences-Schlüssel
const _kIsRunning = 'timer_is_running';
const _kIsOnBreak = 'timer_is_on_break';
const _kWorkStartMs = 'timer_work_start_ms';
const _kBreakStartMs = 'timer_break_start_ms';
const _kSessionStartMs = 'timer_session_start_ms';
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
    DateTime? sessionStartedAt,
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
    if (sessionStartedAt != null) {
      await prefs.setInt(_kSessionStartMs, sessionStartedAt.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_kSessionStartMs);
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
    final sessionStartMs = prefs.getInt(_kSessionStartMs);

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

    final startedAt = sessionStartMs != null
        ? DateTime.fromMillisecondsSinceEpoch(sessionStartMs)
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

    _syncScheduledNotifications();
  }

  // ──────────────────────────────────────────────────────────────

  Future<void> loadToday() async {
    if (state.isRunning || state.isOnBreak) return;
    await _loadTodayFromDb();
  }

  Future<void> _loadTodayFromDb() async {
    final today = DateTime.now();
    final entry = await DatabaseHelper.instance.getDayEntry(today);
    final segmentRows = await DatabaseHelper.instance.getWorkSegmentsForDate(today);
    final segments = segmentRows.map(WorkSegment.fromMap).toList();
    if (entry == null) {
      state = state.copyWith(
        clearStartedAt: true,
        workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
        breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      );
      return;
    }

    final day = DayOverview.fromMap(entry).copyWith(segments: segments);
    if (day.type != DayType.workday) {
      state = state.copyWith(
        clearStartedAt: true,
        workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
        breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      );
      return;
    }

    final workedMinutes = day.workDuration?.inMinutes ?? 0;
    final breakMinutes = day.computedBreakDuration.inMinutes;
    state = state.copyWith(
      startedAt: day.effectiveStartTime,
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

  Future<void> _storeCurrentRunningSegment(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    final workStartMs = prefs.getInt(_kWorkStartMs);
    if (workStartMs == null) return;

    final startTime = DateTime.fromMillisecondsSinceEpoch(workStartMs);
    if (!endTime.isAfter(startTime)) return;

    await DatabaseHelper.instance.insertWorkSegment(
      date: startTime,
      startTime: startTime,
      endTime: endTime,
    );
  }

  void startWorkTimer() async {
    if (!state.isRunning && !state.isOnBreak && state.startedAt == null) {
      await _loadTodayFromDb();
    }

    if (state.isOnBreak) {
      final currentBreakSec =
          state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;

      _timer?.cancel();
      final accWorkSec =
          state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
      final accBreakSec = currentBreakSec;

      _saveTimerState(
        isRunning: true,
        isOnBreak: false,
        workStartedAt: DateTime.now(),
        sessionStartedAt: state.startedAt,
        accumulatedWorkSec: accWorkSec,
        accumulatedBreakSec: accBreakSec,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      state = state.copyWith(
        isRunning: true,
        isOnBreak: false,
        breakTime: _secondsToWorkTime(accBreakSec),
      );
      _syncScheduledNotifications();
      return;
    }

    // Wenn Arbeit nicht läuft: starte Arbeit
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
        sessionStartedAt: startedAt,
        accumulatedWorkSec: accWorkSec,
        accumulatedBreakSec: accBreakSec,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      state = state.copyWith(
        isRunning: true,
        isOnBreak: false,
        startedAt: startedAt,
      );
      _syncScheduledNotifications();
    }
  }

  void startBreakTimer() async {
    if (!state.isRunning) return;

    // Speichere den Arbeits-Segment
    await _storeCurrentRunningSegment(DateTime.now());

    // Starte Pausen-Timer
    _timer?.cancel();
    final breakStart = DateTime.now();
    final accWorkSec =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    final accBreakSec =
        state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;

    _saveTimerState(
      isRunning: false,
      isOnBreak: true,
      breakStartedAt: breakStart,
      sessionStartedAt: state.startedAt,
      accumulatedWorkSec: accWorkSec,
      accumulatedBreakSec: accBreakSec,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tickBreak());
    state = state.copyWith(
      isRunning: false,
      isOnBreak: true,
    );
  }

  Future<void> pauseWorkTimer() async {
    if (state.isRunning) {
      await _storeCurrentRunningSegment(DateTime.now());
    }

    _timer?.cancel();
    final accWorkSec =
        state.workTime.hours * 3600 + state.workTime.minutes * 60 + state.workTime.seconds;
    final accBreakSec =
        state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;
    _saveTimerState(
      isRunning: false,
      isOnBreak: false,
      sessionStartedAt: state.startedAt,
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
      sessionStartedAt: state.startedAt,
      accumulatedWorkSec: accWorkSec,
      accumulatedBreakSec: accBreakSec,
    );
    state = state.copyWith(isOnBreak: false);
  }

  Future<void> stopTimer() async {
    _timer?.cancel();

    final now = DateTime.now();
    // Speichere laufenden Segment falls Arbeit noch läuft
    if (state.isRunning) {
      await _storeCurrentRunningSegment(now);
    }

    final today = DateTime(now.year, now.month, now.day);
    final segmentsRaw = await DatabaseHelper.instance.getWorkSegmentsForDate(today);
    final segments = segmentsRaw.map(WorkSegment.fromMap).toList();

    if (segments.isEmpty) {
      // Keine Segmente: reset
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kIsRunning);
      await prefs.remove(_kIsOnBreak);
      await prefs.remove(_kWorkStartMs);
      await prefs.remove(_kBreakStartMs);
      await prefs.remove(_kSessionStartMs);
      await prefs.remove(_kAccumulatedWorkSec);
      await prefs.remove(_kAccumulatedBreakSec);

      state = state.copyWith(
        isRunning: false,
        isOnBreak: false,
        clearStartedAt: true,
        workTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
        breakTime: WorkTime(hours: 0, minutes: 0, seconds: 0),
      );
      NotificationService.instance.resetDailyFlags();
      await NotificationService.instance.syncBackgroundSchedules(
        isRunning: false,
        workSeconds: 0,
        breakSeconds: 0,
      );
      return;
    }

    // Berechne Gesamtarbeitszeit aus Segmenten
    final workedSeconds = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.duration.inSeconds,
    );
    // Pausenzeit: nur die manuell gezählte (nicht aus Lücken)
    final breakSeconds =
        state.breakTime.hours * 3600 + state.breakTime.minutes * 60 + state.breakTime.seconds;

    final day = DayOverview(
      date: today,
      type: DayType.workday,
      startTime: segments.first.startTime,
      endTime: segments.last.endTime,
      breakDuration: Duration(seconds: breakSeconds),
      segments: segments,
    );
    await DatabaseHelper.instance.upsertDayEntry(day.toMap());

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsRunning);
    await prefs.remove(_kIsOnBreak);
    await prefs.remove(_kWorkStartMs);
    await prefs.remove(_kBreakStartMs);
    await prefs.remove(_kSessionStartMs);
    await prefs.remove(_kAccumulatedWorkSec);
    await prefs.remove(_kAccumulatedBreakSec);

    state = state.copyWith(
      isRunning: false,
      isOnBreak: false,
      clearStartedAt: true,
      workTime: _secondsToWorkTime(workedSeconds),
      breakTime: _secondsToWorkTime(breakSeconds),
    );

    NotificationService.instance.resetDailyFlags();
    await NotificationService.instance.syncBackgroundSchedules(
      isRunning: false,
      workSeconds: 0,
      breakSeconds: 0,
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
    final newWorkTime = wt.copyWith(hours: h, minutes: m, seconds: s);
    state = state.copyWith(workTime: newWorkTime);

    // Benachrichtigungen prüfen
    final workSec = h * 3600 + m * 60 + s;
    final bt = state.breakTime;
    final breakSec = bt.hours * 3600 + bt.minutes * 60 + bt.seconds;
    NotificationService.instance.checkAndNotify(
      workSeconds: workSec,
      breakSeconds: breakSec,
    );
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

  void _syncScheduledNotifications() {
    final wt = state.workTime;
    final bt = state.breakTime;
    final workSec = wt.hours * 3600 + wt.minutes * 60 + wt.seconds;
    final breakSec = bt.hours * 3600 + bt.minutes * 60 + bt.seconds;

    NotificationService.instance.syncBackgroundSchedules(
      isRunning: state.isRunning,
      workSeconds: workSec,
      breakSeconds: breakSec,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final vm = HomeViewModel();

  // Startwert aus dem Profil setzen und geplante Hinweise direkt synchronisieren
  NotificationService.instance.enabled =
      ref.read(profileProvider).remindersEnabled;
  vm._syncScheduledNotifications();

  // Bei jeder Profiländerung synchronisieren
  ref.listen(profileProvider, (_, next) {
    NotificationService.instance.enabled = next.remindersEnabled;
    vm._syncScheduledNotifications();
  });

  return vm;
});