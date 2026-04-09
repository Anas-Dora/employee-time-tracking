import 'package:employee_time_tracking/homePage/home_viewmodel.dart';
import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/services/day_entry_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_setup.dart';

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  setUp(() async {
    await clearDatabaseTables();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('HomeViewModel startet mit leerem Zustand', () async {
    final vm = HomeViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(vm.state.isRunning, isFalse);
    expect(vm.state.isOnBreak, isFalse);
    expect(vm.state.workTime.hours, 0);
    expect(vm.state.breakTime.minutes, 0);

    vm.dispose();
  });

  test('startWorkTimer setzt Running und erhoeht Arbeitszeit', () async {
    final vm = HomeViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    vm.startWorkTimer();
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final workSeconds = vm.state.workTime.hours * 3600 +
        vm.state.workTime.minutes * 60 +
        vm.state.workTime.seconds;

    expect(vm.state.isRunning, isTrue);
    expect(vm.state.startedAt, isNotNull);
    expect(workSeconds, greaterThanOrEqualTo(1));

    vm.dispose();
  });

  test('stellt laufenden Timer aus SharedPreferences wieder her', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'timer_is_running': true,
      'timer_is_on_break': false,
      'timer_work_start_ms': now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch,
      'timer_session_start_ms': now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
      'timer_accumulated_work_sec': 30,
      'timer_accumulated_break_sec': 10,
    });

    final vm = HomeViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final workSeconds = vm.state.workTime.hours * 3600 +
        vm.state.workTime.minutes * 60 +
        vm.state.workTime.seconds;

    expect(vm.state.isRunning, isTrue);
    expect(workSeconds, greaterThanOrEqualTo(150));

    vm.dispose();
  });

  test('uebernimmt Pausen-Aenderung sofort auf Home auch waehrend laufendem Timer', () async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day, 9, 0);
    final end = DateTime(today.year, today.month, today.day, 17, 0);

    await DatabaseHelper.instance.upsertDayEntry(
      DayOverview(
        date: today,
        type: DayType.workday,
        startTime: start,
        endTime: end,
        breakDuration: const Duration(minutes: 0),
      ).toMap(),
    );
    await DatabaseHelper.instance.replaceWorkSegmentsForDate(
      date: today,
      segments: <Map<String, String>>[
        WorkSegment(startTime: start, endTime: end).toDbMap(),
      ],
    );

    final vm = HomeViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    vm.startWorkTimer();
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final beforeWorkSec = vm.state.workTime.hours * 3600 +
        vm.state.workTime.minutes * 60 +
        vm.state.workTime.seconds;

    await DatabaseHelper.instance.upsertDayEntry(
      DayOverview(
        date: today,
        type: DayType.workday,
        startTime: start,
        endTime: end,
        breakDuration: const Duration(minutes: 30),
      ).toMap(),
    );

    DayEntrySyncService.instance.notifyDayChanged(today);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final afterWorkSec = vm.state.workTime.hours * 3600 +
        vm.state.workTime.minutes * 60 +
        vm.state.workTime.seconds;
    final breakSec = vm.state.breakTime.hours * 3600 +
        vm.state.breakTime.minutes * 60 +
        vm.state.breakTime.seconds;

    expect(vm.state.isRunning, isTrue);
    expect(breakSec, 30 * 60);
    expect(afterWorkSec, lessThan(beforeWorkSec));

    vm.dispose();
  });

}

