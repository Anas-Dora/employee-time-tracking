import 'dart:async';

class DayEntrySyncService {
  DayEntrySyncService._();

  static final DayEntrySyncService instance = DayEntrySyncService._();

  final StreamController<DateTime> _changedDaysController =
      StreamController<DateTime>.broadcast();

  Stream<DateTime> get changedDays => _changedDaysController.stream;

  void notifyDayChanged(DateTime date) {
    _changedDaysController.add(DateTime(date.year, date.month, date.day));
  }
}

