// view_models/weekly_overview_vm.dart
import 'package:employee_time_tracking/dayOverview/day_edit_dialog.dart';
import 'package:employee_time_tracking/dayOverview/week_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'day_overview.dart';

final weeklyOverviewProvider =
    StateNotifierProvider<WeeklyOverviewViewModel, WeekOverview>(
      (ref) => WeeklyOverviewViewModel(),
    );

class WeeklyOverviewViewModel extends StateNotifier<WeekOverview> {
  final int weeklyGoalHours; // Wochenziel in Stunden

  WeeklyOverviewViewModel({this.weeklyGoalHours = 40})
    : super(_generateWeek(DateTime.now()));

  int get progressPercent {
    final totalWorkMinutes = state.totalWork.inMinutes;
    final weeklyGoalMinutes = weeklyGoalHours * 60;
    if (weeklyGoalMinutes == 0) return 0;
    return ((totalWorkMinutes / weeklyGoalMinutes) * 100).toInt();
  }

  void toggleDayType(DateTime date, DayType targetType) {
    final updatedDays = state.days.map((day) {
      if (!_isSameDay(day.date, date)) return day;

      final nextType = day.type == targetType ? DayType.workday : targetType;
      return day.copyWith(type: nextType);
    }).toList();

    state = state.copyWith(days: updatedDays);
  }

  void _updateDayDetails({
    required DateTime date,
    required DayType type,
    required TimeOfDay? start,
    required TimeOfDay? end,
    required int breakMinutes,
  }) {
    final updatedDays = state.days.map((day) {
      if (!_isSameDay(day.date, date)) return day;

      DateTime? startDateTime;
      DateTime? endDateTime;
      Duration? pause;

      if (type == DayType.workday) {
        if (start != null) {
          startDateTime = DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
            start.hour,
            start.minute,
          );
        }

        if (end != null) {
          endDateTime = DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
            end.hour,
            end.minute,
          );
        }

        pause = Duration(minutes: breakMinutes);
      }

      return DayOverview(
        date: day.date,
        type: type,
        startTime: startDateTime,
        endTime: endDateTime,
        breakDuration: pause,
      );
    }).toList();

    state = state.copyWith(days: updatedDays);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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
      DayOverview(date: monday.add(Duration(days: 1)), type: DayType.sick),
      DayOverview(date: monday.add(Duration(days: 2)), type: DayType.vacation),
      DayOverview(
        date: monday.add(Duration(days: 3)),
        startTime: DateTime(monday.year, monday.month, monday.day + 3, 7, 15),
        endTime: DateTime(monday.year, monday.month, monday.day + 3, 16, 00),
        type: DayType.workday,
        breakDuration: Duration(minutes: 30),
      ),
      DayOverview(date: monday.add(Duration(days: 4)), type: DayType.none),
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

  Future<void> showEditDialog(
    BuildContext parentContext,
    DayOverview day,
  ) async {
    DayType selectedType = day.type;

    TimeOfDay? start = day.startTime != null
        ? TimeOfDay.fromDateTime(day.startTime!)
        : null;

    TimeOfDay? end = day.endTime != null
        ? TimeOfDay.fromDateTime(day.endTime!)
        : null;

    final breakController = TextEditingController(
      text: (day.breakDuration?.inMinutes ?? 0).toString(),
    );

    await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            //  Startzeit wählen
            Future<void> pickStart() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: start ?? const TimeOfDay(hour: 9, minute: 0),
                helpText: "Wähle eine Uhrzeit",
                cancelText: "Abbrechen",
                confirmText: "OK",
                hourLabelText: "Stunde",
                minuteLabelText: "Minute",
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: Colors.blue,
                          brightness: Brightness.light,
                        ),
                        useMaterial3: true,
                      ),
                      child: child!,
                    );
                  }
              );

              if (picked != null) {
                setState(() => start = picked);
              }
            }

            // Endzeit wählen
            Future<void> pickEnd() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: end ?? const TimeOfDay(hour: 17, minute: 0),
                helpText: "Wähle eine Uhrzeit",
                cancelText: "Abbrechen",
                confirmText: "OK",
                hourLabelText: "Stunde",
                minuteLabelText: "Minute",
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: Colors.blue, // 👈 DEIN BLAU
                          brightness: Brightness.light,
                        ),
                        useMaterial3: true, // wichtig!
                      ),
                      child: child!,
                    );
                  }
              );

              if (picked != null) {
                setState(() => end = picked);
              }
            }

            // Typ ändern
            void onTypeChanged(DayType? value) {
              if (value == null) return;

              setState(() {
                selectedType = value;

                if (selectedType != DayType.workday) {
                  start = null;
                  end = null;
                  breakController.text = '0';
                }
              });
            }

            // Dialog schließen
            void onCancel() {
              Navigator.of(dialogContext).pop(false);
            }

            // Speichern + Validierung
            void onSave() {
              if (selectedType == DayType.workday &&
                  (start == null || end == null)) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte Start- und Endzeit setzen.'),
                  ),
                );
                return;
              }

              final breakMinutes = int.tryParse(breakController.text) ?? 0;

              if (selectedType == DayType.workday) {
                final startDateTime = DateTime(
                  day.date.year,
                  day.date.month,
                  day.date.day,
                  start!.hour,
                  start!.minute,
                );

                final endDateTime = DateTime(
                  day.date.year,
                  day.date.month,
                  day.date.day,
                  end!.hour,
                  end!.minute,
                );

                if (!endDateTime.isAfter(startDateTime)) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Endzeit muss nach der Startzeit liegen.'),
                    ),
                  );
                  return;
                }

                final maxBreak = endDateTime
                    .difference(startDateTime)
                    .inMinutes;

                if (breakMinutes > maxBreak) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pause darf nicht länger als die Arbeitszeit sein.',
                      ),
                    ),
                  );
                  return;
                }
              }

              //bestehende Save-Logik
              _updateDayDetails(
                date: day.date,
                type: selectedType,
                start: start,
                end: end,
                breakMinutes: breakMinutes,
              );

              Navigator.of(dialogContext).pop(true);
            }

            return DayEditDialog(
              selectedType: selectedType,
              start: start,
              end: end,
              breakController: breakController,
              dayTypeLabel: dayTypeLabel,
              formatTime: formatTime,
              onTypeChanged: onTypeChanged,
              onPickStart: pickStart,
              onPickEnd: pickEnd,
              onCancel: onCancel,
              onSave: onSave,
            );
          },
        );
      },
    );
  }

  String dayTypeLabel(DayType type) {
    switch (type) {
      case DayType.workday:
        return 'Werktag';
      case DayType.sick:
        return 'Krank';
      case DayType.vacation:
        return 'Urlaub';
      case DayType.none:
        return 'Kein Eintrag';
    }
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
