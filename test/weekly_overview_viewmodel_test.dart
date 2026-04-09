import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/dayOverview/weekly_overview_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_setup.dart';

DateTime _mondayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  setUp(() async {
    await clearDatabaseTables();
  });

  test('loadWeek laedt Segmente und berechnet Fortschritt', () async {
    final monday = _mondayOf(DateTime.now());
    final start = DateTime(monday.year, monday.month, monday.day, 9, 0);
    final end = DateTime(monday.year, monday.month, monday.day, 17, 0);

    final day = DayOverview(
      date: monday,
      type: DayType.workday,
      startTime: start,
      endTime: end,
      breakDuration: const Duration(minutes: 30),
    );

    await DatabaseHelper.instance.upsertDayEntry(day.toMap());
    await DatabaseHelper.instance.replaceWorkSegmentsForDate(
      date: monday,
      segments: <Map<String, String>>[
        WorkSegment(startTime: start, endTime: end).toDbMap(),
      ],
    );

    final vm = WeeklyOverviewViewModel(
      holidayService: FakeHolidayService(holidayDates: <DateTime>{}),
    );

    await vm.loadWeek(monday);

    expect(vm.state.days.length, 5);
    expect(vm.state.days.first.type, DayType.workday);
    expect(vm.state.totalWork.inMinutes, 450);
    expect(vm.progressPercent, greaterThanOrEqualTo(18));
  });

  test('toggleDayType speichert geaenderten Typ', () async {
    final monday = _mondayOf(DateTime.now());
    final vm = WeeklyOverviewViewModel(
      holidayService: FakeHolidayService(holidayDates: <DateTime>{}),
    );

    await vm.loadWeek(monday);
    await vm.toggleDayType(monday, DayType.sick);

    final stored = await DatabaseHelper.instance.getDayEntry(monday);

    expect(vm.state.days.first.type, DayType.sick);
    expect(stored!['type'], 'sick');
    expect(vm.dayTypeLabel(DayType.vacation), 'Urlaub');
    expect(vm.formatTime(const TimeOfDay(hour: 8, minute: 5)), '08:05');
  });
}

