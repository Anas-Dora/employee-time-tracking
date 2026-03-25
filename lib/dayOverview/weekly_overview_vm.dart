// view_models/weekly_overview_vm.dart
import 'package:employee_time_tracking/dayOverview/week_overview.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'day_overview.dart';


final weeklyOverviewProvider =
StateNotifierProvider<WeeklyOverviewViewModel, WeekOverview>(
        (ref) => WeeklyOverviewViewModel());

class WeeklyOverviewViewModel extends StateNotifier<WeekOverview> {
  final int weeklyGoalHours; // Wochenziel in Stunden

  WeeklyOverviewViewModel({this.weeklyGoalHours = 40}) : super(_generateWeek(DateTime.now()));

  int get progressPercent {
    final totalWorkMinutes = state.totalWork.inMinutes;
    final weeklyGoalMinutes = weeklyGoalHours * 60;
    if (weeklyGoalMinutes == 0) return 0;
    return ((totalWorkMinutes / weeklyGoalMinutes) * 100).toInt();
  }


  static WeekOverview _generateWeek(DateTime date) {
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    DateTime friday = monday.add(Duration(days: 4));

    // Beispielhafte Tage
    List<DayOverview> days = [
      DayOverview(
        date: monday,
        type: DayType.workday,
        startTime: DateTime(monday.year, monday.month, monday.day, 9, 0),
        endTime: DateTime(monday.year, monday.month, monday.day, 17, 15),
        breakDuration: Duration(minutes: 45),
      ),
      DayOverview(
        date: monday.add(Duration(days: 1)),
        type: DayType.sick,
      ),
      DayOverview(
        date: monday.add(Duration(days: 2)),
        type: DayType.vacation,
      ),
      DayOverview(
        date: monday.add(Duration(days: 3)),
        startTime: DateTime(monday.year, monday.month, monday.day + 3, 7, 15),
        endTime: DateTime(monday.year, monday.month, monday.day + 3, 16, 00),
        type: DayType.workday,
        breakDuration: Duration(minutes: 30),
      ),
      DayOverview(
        date: monday.add(Duration(days: 4)),
        startTime: DateTime(monday.year, monday.month, monday.day + 4, 8, 0),
        endTime: DateTime(monday.year, monday.month, monday.day + 4, 17, 0),
        type: DayType.workday,
        breakDuration: Duration(minutes: 60),
      ),
    ];

    return WeekOverview(startDate: monday, endDate: friday, days: days);
  }

  void previousWeek() {
    DateTime newDate = state.startDate.subtract(Duration(days: 7));
    state = _generateWeek(newDate);
  }

  void nextWeek() {
    DateTime newDate = state.startDate.add(Duration(days: 7));
    state = _generateWeek(newDate);
  }
}