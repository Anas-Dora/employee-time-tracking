// view_models/weekly_overview_vm.dart
import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/widgets/day_edit_dialog.dart';
import 'package:employee_time_tracking/dayOverview/week_overview.dart';
import 'package:employee_time_tracking/services/holiday_service.dart';
import 'package:employee_time_tracking/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'day_overview.dart';

final weeklyOverviewProvider =
    StateNotifierProvider<WeeklyOverviewViewModel, WeekOverview>(
      (ref) => WeeklyOverviewViewModel(),
    );

class WeeklyOverviewViewModel extends StateNotifier<WeekOverview> {
  final int weeklyGoalHours; // Wochenziel in Stunden
  final String bundesland;
  final HolidayService _holidayService;

  WeeklyOverviewViewModel({
    this.weeklyGoalHours = 40,
    this.bundesland = 'BW',
    HolidayService? holidayService,
  }) : _holidayService = holidayService ?? HolidayService(),
       super(_buildEmptyWeek(DateTime.now())) {
    _loadWeekFromDb(DateTime.now());
  }

  int get progressPercent {
    final totalWorkMinutes = state.totalWork.inMinutes;
    final weeklyGoalMinutes = weeklyGoalHours * 60;
    if (weeklyGoalMinutes == 0) return 0;
    return ((totalWorkMinutes / weeklyGoalMinutes) * 100).toInt();
  }

  Future<void> loadWeek([DateTime? date]) async {
    final current = date ?? DateTime.now();
    await _loadWeekFromDb(current);
  }

  /// Leere Woche ohne DB-Daten erzeugen
  static WeekOverview _buildEmptyWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final friday = monday.add(const Duration(days: 4));
    final List<DayOverview> days = List.generate(
      5,
      (i) => DayOverview(
        date: monday.add(Duration(days: i)),
        type: DayType.none,
      ),
    );
    return WeekOverview(startDate: monday, endDate: friday, days: days);
  }

  /// Wochendaten aus SQLite laden
  Future<void> _loadWeekFromDb(DateTime date) async {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    final dbEntries =
        await DatabaseHelper.instance.getDayEntriesForWeek(monday);
    final segmentRows =
        await DatabaseHelper.instance.getWorkSegmentsForWeek(monday);

    final Map<String, List<WorkSegment>> segmentsByDate = {};
    for (final row in segmentRows) {
      final key = DateTime.parse(row['date'] as String);
      final dateKey = '${key.year}-${key.month}-${key.day}';
      segmentsByDate.putIfAbsent(dateKey, () => []).add(WorkSegment.fromMap(row));
    }

    final Map<String, DayOverview> dbMap = {};
    for (final entry in dbEntries) {
      final day = DayOverview.fromMap(entry);
      final key = '${day.date.year}-${day.date.month}-${day.date.day}';
      dbMap[key] = day.copyWith(segments: segmentsByDate[key] ?? const []);
    }

    final List<DayOverview> baseDays = List.generate(5, (i) {
      final d = monday.add(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      return dbMap[key] ??
          DayOverview(
            date: d,
            type: DayType.none,
            segments: segmentsByDate[key] ?? const [],
          );
    });

    final holidayFlags = await Future.wait(
      baseDays.map((day) => _isHoliday(day.date)),
    );

    final List<DayOverview> days = List.generate(baseDays.length, (i) {
      final day = baseDays[i];
      if (!holidayFlags[i]) return day;
      return day.copyWith(
        isHoliday: true,
        type: DayType.none,
        startTime: null,
        endTime: null,
        breakDuration: null,
        clearSegments: true,
      );
    });

    state = WeekOverview(startDate: monday, endDate: friday, days: days);
  }

  Future<void> toggleDayType(DateTime date, DayType targetType) async {
    if (!await _ensureNotHoliday(date)) return;

    final updatedDays = state.days.map((day) {
      if (!_isSameDay(day.date, date)) return day;

      final nextType = day.type == targetType ? DayType.workday : targetType;
      return day.copyWith(type: nextType);
    }).toList();

    state = state.copyWith(days: updatedDays);

    // Typwechsel direkt persistieren (z. B. Krank/Urlaub per Schnellbutton).
    final updatedDay = updatedDays.firstWhere((d) => _isSameDay(d.date, date));
    await DatabaseHelper.instance.upsertDayEntry(updatedDay.toMap());
  }

  Future<void> _updateDayDetails({
    required DateTime date,
    required DayType type,
    required TimeOfDay? start,
    required TimeOfDay? end,
    required int breakMinutes,
  }) async {
    if (!await _ensureNotHoliday(date)) return;

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
        segments: type == DayType.workday && startDateTime != null && endDateTime != null
            ? [WorkSegment(startTime: startDateTime, endTime: endDateTime)]
            : const [],
      );
    }).toList();

    state = state.copyWith(days: updatedDays);

    // In SQLite speichern
    final updatedDay = updatedDays.firstWhere(
      (d) => _isSameDay(d.date, date),
    );
    await DatabaseHelper.instance.upsertDayEntry(updatedDay.toMap());
    await DatabaseHelper.instance.replaceWorkSegmentsForDate(
      date: date,
      segments: updatedDay.orderedSegments.map((s) => s.toDbMap()).toList(),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<bool> _ensureNotHoliday(DateTime date) async {
    if (!await _isHoliday(date)) return true;
    _markHolidayInState(date);
    return false;
  }

  void _markHolidayInState(DateTime date) {
    final updatedDays = state.days.map((day) {
      if (!_isSameDay(day.date, date)) return day;

      return day.copyWith(
        isHoliday: true,
        type: DayType.none,
        startTime: null,
        endTime: null,
        breakDuration: null,
        clearSegments: true,
      );
    }).toList();

    state = state.copyWith(days: updatedDays);
  }

  Future<bool> _isHoliday(DateTime date) async {
    try {
      return await _holidayService.isHoliday(
        date: date,
        bundesland: bundesland,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> previousWeek() async {
    final newDate = state.startDate.subtract(const Duration(days: 7));
    await _loadWeekFromDb(newDate);
  }

  Future<void> nextWeek() async {
    final newDate = state.startDate.add(const Duration(days: 7));
    await _loadWeekFromDb(newDate);
  }

  Future<void> showEditDialog(
    BuildContext parentContext,
    DayOverview day,
  ) async {
    if (!await _ensureNotHoliday(day.date)) return;

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
                          seedColor: AppColors.timePickerSeed,
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
                          seedColor: AppColors.timePickerSeed,
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
            Future<void> onSave() async {
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
              await _updateDayDetails(
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
