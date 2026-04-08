import 'package:employee_time_tracking/homePage/home_viewmodel.dart';
import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/dayOverview/day_overview.dart';
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

    await vm.pauseWorkTimer();
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

    await vm.pauseWorkTimer();
    vm.dispose();
  });

}

