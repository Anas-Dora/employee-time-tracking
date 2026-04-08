import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/monthlyOverview/MonthlyNotification.dart';
import 'package:employee_time_tracking/monthlyOverview/monthly_overview_vm.dart';
import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_setup.dart';

DateTime _firstWeekdayOfMonth(DateTime date) {
  var current = DateTime(date.year, date.month, 1);
  while (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) {
    current = current.add(const Duration(days: 1));
  }
  return current;
}

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
    await initializeDateFormatting('de_DE');
  });

  setUp(() async {
    await clearDatabaseTables();
  });

  test('loadMonth berechnet totalHours und overtime aus Segmenten', () async {
    final workDate = _firstWeekdayOfMonth(DateTime.now());
    final firstStart = DateTime(workDate.year, workDate.month, workDate.day, 9, 0);
    final firstEnd = DateTime(workDate.year, workDate.month, workDate.day, 12, 0);
    final secondStart = DateTime(workDate.year, workDate.month, workDate.day, 13, 0);
    final secondEnd = DateTime(workDate.year, workDate.month, workDate.day, 18, 0);

    await DatabaseHelper.instance.upsertDayEntry(
      DayOverview(
        date: workDate,
        type: DayType.workday,
        startTime: firstStart,
        endTime: secondEnd,
        breakDuration: const Duration(minutes: 60),
      ).toMap(),
    );

    await DatabaseHelper.instance.replaceWorkSegmentsForDate(
      date: workDate,
      segments: <Map<String, String>>[
        WorkSegment(startTime: firstStart, endTime: firstEnd).toDbMap(),
        WorkSegment(startTime: secondStart, endTime: secondEnd).toDbMap(),
      ],
    );

    final vm = MonthlyOverviewVM(
      holidayService: FakeHolidayService(holidayDates: <DateTime>{}),
    );

    await vm.loadMonth();

    expect(vm.state.days.any((d) => d.date.day == workDate.day), isTrue);
    expect(vm.totalHours, closeTo(8.0, 0.01));
    expect(vm.overtime, closeTo(0.0, 0.01));
  });

  test('parse/format Helfer funktionieren fuer Zeiten und Typen', () async {
    final vm = MonthlyOverviewVM(
      holidayService: FakeHolidayService(holidayDates: <DateTime>{}),
    );

    await vm.loadMonth();

    expect(vm.parseTimeOfDay('08:45'), const TimeOfDay(hour: 8, minute: 45));
    expect(vm.parseTimeOfDay('-'), isNull);
    expect(vm.formatTime(const TimeOfDay(hour: 7, minute: 5)), '07:05');
    expect(vm.getDayTypeLabel(DayType.sick), 'Krank');
  });
}
