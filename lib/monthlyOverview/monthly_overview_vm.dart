import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';


final monthlyOverviewProvider =
    StateNotifierProvider<MonthlyOverviewVM, MonthlyOverviewState>(
  (ref) => MonthlyOverviewVM(),
);

class MonthlyOverviewState {
  final DateTime currentMonth;
  final List<WorkDay> days;

  MonthlyOverviewState({
    required this.currentMonth,
    required this.days,
  });

  MonthlyOverviewState copyWith({
    DateTime? currentMonth,
    List<WorkDay>? days,
  }) {
    return MonthlyOverviewState(
      currentMonth: currentMonth ?? this.currentMonth,
      days: days ?? this.days,
    );
  }
}

class MonthlyOverviewVM extends StateNotifier<MonthlyOverviewState> {
  MonthlyOverviewVM()
      : super(
          MonthlyOverviewState(
            currentMonth: DateTime.now(),
            days: [],
          ),
        ) {
    loadMonth();
  }

  void loadMonth() {
    final date = state.currentMonth;
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);

    List<WorkDay> days = [];

    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));

      days.add(WorkDay(date: day));
    }

    state = state.copyWith(days: days);
  }

  void nextMonth() {
    state = state.copyWith(
      currentMonth: DateTime(
        state.currentMonth.year,
        state.currentMonth.month + 1,
      ),
    );
    loadMonth();
  }

  void previousMonth() {
    state = state.copyWith(
      currentMonth: DateTime(
        state.currentMonth.year,
        state.currentMonth.month - 1,
      ),
    );
    loadMonth();
  }

  String get formattedMonth {
    return DateFormat('MMMM yyyy', 'de_DE').format(state.currentMonth);
  }

  double get totalHours => 164.5; // später berechnen
  double get overtime => 12.2; // später berechnen
}