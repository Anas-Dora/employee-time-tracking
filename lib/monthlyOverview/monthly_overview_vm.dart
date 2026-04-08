import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:employee_time_tracking/services/holiday_service.dart';
import 'package:employee_time_tracking/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../dayOverview/day_overview.dart';
import '../widgets/day_edit_dialog.dart';
import 'MonthlyNotification.dart';


final monthlyOverviewProvider =
    StateNotifierProvider.autoDispose<MonthlyOverviewVM, MonthlyOverviewState>(
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
  static const double overtimeGoalHours = 8.0;
  final String bundesland;
  final HolidayService _holidayService;

  MonthlyOverviewVM({
    this.bundesland = 'BW',
    HolidayService? holidayService,
  }) : _holidayService = holidayService ?? HolidayService(),
       super(
          MonthlyOverviewState(
            currentMonth: DateTime.now(),
            days: [],
          ),
        ) {
    loadMonth();
  }

  Future<void> loadMonth() async {
    final date = state.currentMonth;
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);

    // Alle gespeicherten Einträge aus der DB laden
    final dbEntries = await DatabaseHelper.instance
        .getDayEntriesForMonth(date.year, date.month);
    final segmentRows = await DatabaseHelper.instance
        .getWorkSegmentsForMonth(date.year, date.month);

    final Map<String, List<WorkSegment>> segmentsByDate = {};
    for (final row in segmentRows) {
      final segDate = DateTime.parse(row['date'] as String);
      final key = '${segDate.year}-${segDate.month}-${segDate.day}';
      segmentsByDate.putIfAbsent(key, () => []).add(WorkSegment.fromMap(row));
    }

    // DB-Einträge nach Datum indexieren
    final Map<String, WorkDay> dbMap = {};
    for (final entry in dbEntries) {
      final wdBase = WorkDay.fromMap(entry);
      final wdKey = '${wdBase.date.year}-${wdBase.date.month}-${wdBase.date.day}';
      final wd = wdBase.copyWith(segments: segmentsByDate[wdKey] ?? const []);
      // Berechnete Felder (total, diff) neu berechnen
      final computed = _computeWorkDay(wd);
      final dateKey =
          '${computed.date.year}-${computed.date.month}-${computed.date.day}';
      dbMap[dateKey] = computed;
    }

    List<WorkDay> baseDays = [];
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      if (_isWeekend(day)) {
        continue;
      }
      final key = '${day.year}-${day.month}-${day.day}';
      baseDays.add(dbMap[key] ?? WorkDay(date: day));
    }

    final holidayFlags = await Future.wait(
      baseDays.map((day) => _isHoliday(day.date)),
    );

    final days = List<WorkDay>.generate(baseDays.length, (i) {
      final day = baseDays[i];
      if (!holidayFlags[i]) return day;
      return day.copyWith(
        isHoliday: true,
        type: DayType.none,
        start: '-',
        end: '-',
        pause: '-',
        total: '-',
        diff: '-',
      );
    });

    state = state.copyWith(days: days);
  }

  bool _isWeekend(DateTime day) {
    return day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;
  }

  Future<void> nextMonth() async {
    state = state.copyWith(
      currentMonth: DateTime(
        state.currentMonth.year,
        state.currentMonth.month + 1,
      ),
    );
    await loadMonth();
  }

  Future<void> previousMonth() async {
    state = state.copyWith(
      currentMonth: DateTime(
        state.currentMonth.year,
        state.currentMonth.month - 1,
      ),
    );
    await loadMonth();
  }

  /// Berechnet total und diff für einen WorkDay (helper)
  WorkDay _computeWorkDay(WorkDay wd) {
    if (wd.type == DayType.workday && wd.segments.isNotEmpty) {
      return _computeWorkDayFromSegments(wd);
    }

    const int targetMinutes = 8 * 60;
    String totalStr = '-';
    String diffStr = '-';

    if (wd.type == DayType.workday &&
        wd.start != '-' &&
        wd.end != '-' &&
        wd.start.isNotEmpty &&
        wd.end.isNotEmpty) {
      final startParts = wd.start.split(':');
      final endParts = wd.end.split(':');
      final breakMinutes =
          (wd.pause != '-' && wd.pause.isNotEmpty) ? (int.tryParse(wd.pause) ?? 0) : 0;

      final startDt = DateTime(wd.date.year, wd.date.month, wd.date.day,
          int.parse(startParts[0]), int.parse(startParts[1]));
      final endDt = DateTime(wd.date.year, wd.date.month, wd.date.day,
          int.parse(endParts[0]), int.parse(endParts[1]));

      final workedMinutes =
          endDt.difference(startDt).inMinutes - breakMinutes;
      totalStr = _minutesToTimeString(workedMinutes);
      final diffMinutes = workedMinutes - targetMinutes;
      final sign = diffMinutes >= 0 ? '+' : '-';
      diffStr = '$sign${_minutesToTimeString(diffMinutes.abs())}';
    } else if (wd.type == DayType.vacation || wd.type == DayType.sick) {
      totalStr = _minutesToTimeString(targetMinutes);
      diffStr = '+00:00';
    }

    return wd.copyWith(total: totalStr, diff: diffStr);
  }

  WorkDay _computeWorkDayFromSegments(WorkDay wd) {
    const int targetMinutes = 8 * 60;
    final ordered = List<WorkSegment>.from(wd.segments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final startLines = ordered
        .map((segment) => DateFormat('HH:mm').format(segment.startTime))
        .join('\n');
    final endLines = ordered
        .map((segment) => DateFormat('HH:mm').format(segment.endTime))
        .join('\n');

    int workedMinutes = 0;
    int breakMinutes = 0;
    for (int i = 0; i < ordered.length; i++) {
      workedMinutes += ordered[i].duration.inMinutes;
      if (i > 0) {
        final pause = ordered[i].startTime.difference(ordered[i - 1].endTime).inMinutes;
        if (pause > 0) {
          breakMinutes += pause;
        }
      }
    }

    final totalStr = _minutesToTimeString(workedMinutes);
    final diffMinutes = workedMinutes - targetMinutes;
    final sign = diffMinutes >= 0 ? '+' : '-';
    final diffStr = '$sign${_minutesToTimeString(diffMinutes.abs())}';

    return wd.copyWith(
      start: startLines,
      end: endLines,
      pause: breakMinutes.toString(),
      total: totalStr,
      diff: diffStr,
    );
  }

  Future<void> _updateDayDetails({
    required DateTime date,
    required DayType type,
    required TimeOfDay? start,
    required TimeOfDay? end,
    required int breakMinutes,
  }) async {
    if (!await _ensureNotHoliday(date)) return;

    // Standardarbeitszeit in Minuten (8 Stunden)
    const int targetMinutes = 8 * 60;

    String startStr = '-';
    String endStr = '-';
    String pauseStr = '-';
    String totalStr = '-';
    String diffStr = '-';

    if (type == DayType.workday && start != null && end != null) {
      final startDt = DateTime(date.year, date.month, date.day, start.hour, start.minute);
      final endDt = DateTime(date.year, date.month, date.day, end.hour, end.minute);
      final workedMinutes = endDt.difference(startDt).inMinutes - breakMinutes;

      startStr = formatTime(start);
      endStr = formatTime(end);
      pauseStr = breakMinutes.toString();
      totalStr = _minutesToTimeString(workedMinutes);

      final diffMinutes = workedMinutes - targetMinutes;
      final sign = diffMinutes >= 0 ? '+' : '-';
      diffStr = '$sign${_minutesToTimeString(diffMinutes.abs())}';
    } else if (type == DayType.vacation || type == DayType.sick) {
      // Urlaubstage und Kranktage zählen als volle Arbeitstage
      totalStr = _minutesToTimeString(targetMinutes);
      diffStr = '+00:00';
    }

    final updatedDays = state.days.map((d) {
      if (d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day) {
        return d.copyWith(
          type: type,
          start: startStr,
          end: endStr,
          pause: pauseStr,
          total: totalStr,
          diff: diffStr,
        );
      }
      return d;
    }).toList();

    state = state.copyWith(days: updatedDays);

    // In SQLite speichern
    final updatedWd = WorkDay(
      date: date,
      type: type,
      start: startStr,
      end: endStr,
      pause: pauseStr,
      total: totalStr,
      diff: diffStr,
    );
    await DatabaseHelper.instance.upsertDayEntry(updatedWd.toMap());
    await DatabaseHelper.instance.replaceWorkSegmentsForDate(
      date: date,
      segments: type == DayType.workday && start != null && end != null
          ? [
              WorkSegment(
                startTime: DateTime(date.year, date.month, date.day, start.hour, start.minute),
                endTime: DateTime(date.year, date.month, date.day, end.hour, end.minute),
              ).toDbMap(),
            ]
          : const [],
    );
  }

  String _minutesToTimeString(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedMonth {
    return DateFormat('MMMM yyyy', 'de_DE').format(state.currentMonth);
  }

  double get totalHours =>
      _sumMinutes(state.days.map((day) => day.total), allowSignedValues: false) /
          60;

  double get overtime =>
      _sumMinutes(state.days.map((day) => day.diff), allowSignedValues: true) /
          60;

  List<MonthlyNotification> get notifications => buildNotifications(
        days: state.days,
        overtimeHours: overtime,
        currentMonth: state.currentMonth,
      );

  List<String> get notificationMessages =>
      notifications.map((notification) => notification.message).toList();

  static List<MonthlyNotification> buildNotifications({
    required List<WorkDay> days,
    required double overtimeHours,
    required DateTime currentMonth,
  }) {
    final notifications = <MonthlyNotification>[];
    final relevantDays = _relevantNotificationDays(days, currentMonth);
    final monthLabel = DateFormat('MMMM yyyy', 'de_DE').format(currentMonth);

    final missingEntryDays = relevantDays
        .where((day) => day.type == DayType.none && !day.isHoliday)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final incompleteWorkDays = relevantDays
        .where(
          (day) =>
              day.type == DayType.workday &&
              (_isMissingValue(day.start) || _isMissingValue(day.end)),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (missingEntryDays.isNotEmpty) {
      notifications.add(
        MonthlyNotification(
          type: MonthlyNotificationType.missingEntry,
          message: _buildMissingEntryMessage(missingEntryDays),
        ),
      );
    }

    if (incompleteWorkDays.isNotEmpty) {
      notifications.add(
        MonthlyNotification(
          type: MonthlyNotificationType.incompleteEntry,
          message: _buildIncompleteEntryMessage(incompleteWorkDays),
        ),
      );
    }

    if (overtimeHours >= overtimeGoalHours) {
      notifications.add(
        MonthlyNotification(
          type: MonthlyNotificationType.overtimeGoal,
          message:
              'Ihr Überstundenguthaben hat mit ${_formatHours(overtimeHours)} h den Zielwert von ${_formatHours(overtimeGoalHours)} h erreicht.',
        ),
      );
    }

    if (overtimeHours < 0) {
      notifications.add(
        MonthlyNotification(
          type: MonthlyNotificationType.negativeOvertime,
          message:
              'Sie haben aktuell ${_formatHours(overtimeHours.abs())} Minusstunden in $monthLabel.',
        ),
      );
    }

    if (notifications.isEmpty) {
      notifications.add(
        MonthlyNotification(
          type: MonthlyNotificationType.none,
          message: 'Für $monthLabel liegen aktuell keine offenen Hinweise vor.',
        ),
      );
    }

    return notifications;
  }

  int _sumMinutes(Iterable<String> values,
      {required bool allowSignedValues}) {
    return values.fold<int>(0, (sum, value) {
      final minutes = _parseMinutes(
          value, allowSignedValues: allowSignedValues);
      return sum + (minutes ?? 0);
    });
  }

  int? _parseMinutes(String value, {required bool allowSignedValues}) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') return null;

    final match = RegExp(r'^([+-])?(\d+):(\d{2})$').firstMatch(normalized);
    if (match == null) return null;

    final sign = match.group(1);
    if (!allowSignedValues && sign == '-') return null;

    final hours = int.tryParse(match.group(2)!);
    final minutes = int.tryParse(match.group(3)!);

    if (hours == null || minutes == null || minutes >= 60) return null;

    final totalMinutes = (hours * 60) + minutes;
    return sign == '-' ? -totalMinutes : totalMinutes;
  }

  static List<WorkDay> _relevantNotificationDays(
    List<WorkDay> days,
    DateTime currentMonth,
  ) {
    final now = DateTime.now();
    final selectedMonth = DateTime(currentMonth.year, currentMonth.month);
    final thisMonth = DateTime(now.year, now.month);

    if (selectedMonth.isAfter(thisMonth)) {
      return const <WorkDay>[];
    }

    final cutoff = _isSameMonth(currentMonth, now)
        ? DateTime(now.year, now.month, now.day - 1)
        : DateTime(currentMonth.year, currentMonth.month + 1, 0);

    return days.where((day) => !day.date.isAfter(cutoff)).toList();
  }

  static bool _isSameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  static bool _isMissingValue(String value) {
    final normalized = value.trim();
    return normalized.isEmpty || normalized == '-' || normalized == '--:--';
  }

  static String _buildMissingEntryMessage(List<WorkDay> days) {
    final formattedDays = _formatDayList(days);

    if (days.length == 1) {
      return 'Für den $formattedDays fehlt noch ein Eintrag. Bitte nachtragen.';
    }

    return 'Für folgende Tage fehlen noch Einträge: $formattedDays.';
  }

  static String _buildIncompleteEntryMessage(List<WorkDay> days) {
    final formattedDays = _formatDayList(days);

    if (days.length == 1) {
      return 'Am $formattedDays ist die Arbeitszeit unvollständig. Bitte Start- und Endzeit prüfen.';
    }

    return 'An diesen Tagen sind Arbeitszeiten unvollständig: $formattedDays.';
  }

  static String _formatDayList(List<WorkDay> days, {int maxVisibleDays = 3}) {
    final formatter = DateFormat('dd. MMMM', 'de_DE');
    final visibleDays = days.take(maxVisibleDays).map((day) {
      return formatter.format(day.date);
    }).toList();

    final remainingDays = days.length - visibleDays.length;
    if (remainingDays > 0) {
      visibleDays.add('und $remainingDays weitere');
    }

    return visibleDays.join(', ');
  }

  static String _formatHours(double value) {
    return NumberFormat('0.0', 'de_DE').format(value);
  }

  TimeOfDay? parseTimeOfDay(String time) {
    if (time == '-' || time.isEmpty) return null;
    try {
      final normalized = time.split('\n').first.trim();
      final parts = normalized.split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String getDayTypeLabel(DayType type) {
    switch (type) {
      case DayType.workday:
        return 'Arbeitstag';
      case DayType.sick:
        return 'Krank';
      case DayType.vacation:
        return 'Urlaub';
      case DayType.none:
        return 'Keine';
    }
  }

  Future<void> showDayEditDialog(
      BuildContext parentContext,
      WorkDay day,
      ) async {
    if (!await _ensureNotHoliday(day.date)) return;

    DayType selectedType = day.type;

    TimeOfDay? start = parseTimeOfDay(day.start);
    TimeOfDay? end = parseTimeOfDay(day.end);

    final breakMinutesInitial =
        (day.pause != '-' && day.pause.isNotEmpty) ? day.pause : '0';
    final breakController = TextEditingController(
      text: breakMinutesInitial,
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
                        useMaterial3: true,
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
              dayTypeLabel: getDayTypeLabel,
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

  Future<bool> _ensureNotHoliday(DateTime date) async {
    if (!await _isHoliday(date)) return true;
    _markHolidayInState(date);
    return false;
  }

  void _markHolidayInState(DateTime date) {
    final updatedDays = state.days.map((day) {
      if (day.date.year != date.year ||
          day.date.month != date.month ||
          day.date.day != date.day) {
        return day;
      }

      return day.copyWith(
        isHoliday: true,
        type: DayType.none,
        start: '-',
        end: '-',
        pause: '-',
        total: '-',
        diff: '-',
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
}