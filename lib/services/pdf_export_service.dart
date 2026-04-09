import 'dart:io';

import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/services/holiday_service.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  static const String _defaultBundesland = 'BW';
  static final HolidayService _holidayService = HolidayService();

  static Future<void> generateMonthlyPdf(
    int year,
    int month,
    Profile profile,
  ) async {
    final monthName = DateFormat.MMMM('de_DE').format(DateTime(year, month));
    final fileName = '${profile.name}_${monthName.toLowerCase()}_$year.pdf';

    await _generatePdfForMonths(
      year: year,
      months: [month],
      profile: profile,
      fileName: fileName,
    );
  }

  static Future<void> generateSelectedMonthsPdf(
    int year,
    List<int> months,
    Profile profile,
  ) async {
    final normalizedMonths = _normalizeMonths(months);
    final startMonth = normalizedMonths.first.toString().padLeft(2, '0');
    final endMonth = normalizedMonths.last.toString().padLeft(2, '0');
    final fileName =
        'Monatsbericht_${profile.name}_${year}_${startMonth}-${endMonth}.pdf';

    await _generatePdfForMonths(
      year: year,
      months: normalizedMonths,
      profile: profile,
      fileName: fileName,
    );
  }

  static Future<void> generateYearlyPdf(int year, Profile profile) async {
    await _generatePdfForMonths(
      year: year,
      months: List<int>.generate(12, (index) => index + 1),
      profile: profile,
      fileName: 'Jahresbericht_${profile.name}_$year.pdf',
    );
  }

  static Future<void> _generatePdfForMonths({
    required int year,
    required List<int> months,
    required Profile profile,
    required String fileName,
  }) async {
    final normalizedMonths = _normalizeMonths(months);
    final pdf = pw.Document();
    final List<pw.Widget> content = [];

    if (normalizedMonths.length == 1) {
      content.add(
        _buildMonthProfileHeader(profile, year, normalizedMonths.first),
      );
    } else {
      content.add(_buildYearProfileHeader(profile, year));
    }
    content.add(pw.SizedBox(height: 20));

    for (int index = 0; index < normalizedMonths.length; index++) {
      final month = normalizedMonths[index];
      final days = await _buildDaysForMonth(year, month);
      final totalMinutes = _sumMonthMinutes(days);

      content.addAll(_buildMonthPage(year, month, days, totalMinutes));
      if (index != normalizedMonths.length - 1) {
        content.add(pw.NewPage());
      }
    }

    pdf.addPage(
      pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (ctx) => content),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  static List<int> _normalizeMonths(List<int> months) {
    final normalized = months.where((month) => month >= 1 && month <= 12).toSet().toList()..sort();
    if (normalized.isEmpty) {
      throw ArgumentError('Mindestens ein gueltiger Monat (1-12) ist erforderlich.');
    }
    return normalized;
  }

  static pw.Widget _buildYearProfileHeader(Profile profile, int year) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Jahresbericht $year',
          style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        _buildProfileInfo(profile),
      ],
    );
  }

  static pw.Widget _buildMonthProfileHeader(
    Profile profile,
    int year,
    int month,
  ) {
    final monthName = DateFormat.MMMM('de_DE').format(DateTime(year, month));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monatsbericht $monthName $year',
          style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        _buildProfileInfo(profile),
      ],
    );
  }

  static pw.Widget _buildProfileInfo(Profile profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Row(
              children: [
                pw.Text(
                  'Name: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(profile.name),
              ],
            ),
            pw.SizedBox(width: 20),
            pw.Row(
              children: [
                pw.Text(
                  'Mitarbeiter-ID: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(profile.employeeId),
              ],
            ),
            pw.SizedBox(width: 20),
            pw.Row(
              children: [
                pw.Text(
                  'Position: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(profile.jobTitle),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),

        pw.Row(
          children: [
            pw.Row(
              children: [
                pw.Text(
                  'Abteilung: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(profile.department),
              ],
            ),
            pw.SizedBox(width: 20),

            pw.Row(
              children: [
                pw.Text(
                  'Firma: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(profile.company),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),
      ],
    );
  }

  static List<pw.Widget> _buildMonthPage(
    int year,
    int month,
    List<WorkDay> days,
    double totalMinutes,
  ) {
    final monthName = DateFormat.MMMM('de_DE').format(DateTime(year, month));

    return [
      pw.Text(
        '$monthName $year',
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 20),

      _buildMonthTable(days),

      pw.SizedBox(height: 20),

      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Gesamtstunden: ',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${(totalMinutes / 60).toStringAsFixed(2)} h',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    ];
  }

  static Future<List<WorkDay>> _buildDaysForMonth(int year, int month) async {
    final entries = await DatabaseHelper.instance.getDayEntriesForMonth(
      year,
      month,
    );
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final byDate = <String, WorkDay>{};
    for (final entry in entries) {
      final computed = _computeWorkDay(WorkDay.fromMap(entry));
      final key =
          '${computed.date.year}-${computed.date.month}-${computed.date.day}';
      byDate[key] = computed;
    }

    final days = <WorkDay>[];
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      if (_isWeekend(day)) {
        continue;
      }
      final key = '${day.year}-${day.month}-${day.day}';
      days.add(byDate[key] ?? WorkDay(date: day));
    }
    return _applyHolidayFlags(days);
  }

  static Future<List<WorkDay>> _applyHolidayFlags(List<WorkDay> days) async {
    final holidayFlags = await Future.wait(
      days.map((day) async {
        if (day.isHoliday) {
          return true;
        }

        try {
          return await _holidayService.isHoliday(
            date: day.date,
            bundesland: _defaultBundesland,
          );
        } catch (_) {
          return false;
        }
      }),
    );

    return List<WorkDay>.generate(days.length, (index) {
      final day = days[index];
      if (!holidayFlags[index]) {
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
    });
  }

  static bool _isWeekend(DateTime day) {
    return day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  }

  static double _sumMonthMinutes(List<WorkDay> days) {
    double total = 0;
    for (final day in days) {
      total += _parseTimeToMinutes(day.total);
    }
    return total;
  }

  static WorkDay _computeWorkDay(WorkDay wd) {
    const targetMinutes = 8 * 60;
    String totalStr = '-';
    String diffStr = '-';

    if (wd.type.name == 'workday' &&
        wd.start != '-' &&
        wd.end != '-' &&
        wd.start.isNotEmpty &&
        wd.end.isNotEmpty) {
      final startParts = wd.start.split(':');
      final endParts = wd.end.split(':');
      final breakMinutes = (wd.pause != '-' && wd.pause.isNotEmpty)
          ? (int.tryParse(wd.pause) ?? 0)
          : 0;

      final startDt = DateTime(
        wd.date.year,
        wd.date.month,
        wd.date.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      final endDt = DateTime(
        wd.date.year,
        wd.date.month,
        wd.date.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      final workedMinutes = endDt.difference(startDt).inMinutes - breakMinutes;
      totalStr = _minutesToTimeString(workedMinutes);
      final diffMinutes = workedMinutes - targetMinutes;
      final sign = diffMinutes >= 0 ? '+' : '-';
      diffStr = '$sign${_minutesToTimeString(diffMinutes.abs())}';
    } else if (wd.type.name == 'vacation' || wd.type.name == 'sick') {
      totalStr = _minutesToTimeString(targetMinutes);
      diffStr = '+00:00';
    }

    return wd.copyWith(total: totalStr, diff: diffStr);
  }

  static String _minutesToTimeString(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static pw.Widget _buildMonthTable(List<WorkDay> days) {
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    const cellStyle = pw.TextStyle(fontSize: 9);

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _headerCell('Datum', headerStyle),
          _headerCell('Start', headerStyle),
          _headerCell('Ende', headerStyle),
          _headerCell('Pause', headerStyle),
          _headerCell('Gesamt', headerStyle),
          _headerCell('Differenz', headerStyle),
        ],
      ),
    ];

    for (final day in days) {
      final rowColor = _dayRowColor(day);
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            _cell(DateFormat('dd.MM.yyyy').format(day.date), cellStyle),
            _cell(day.start, cellStyle),
            _cell(day.end, cellStyle),
            _cell(day.pause, cellStyle),
            _cell(day.total, cellStyle),
            _cell(day.diff, cellStyle),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static PdfColor _dayRowColor(WorkDay day) {
    if (day.isHoliday) {
      return PdfColors.deepPurple100;
    }
    if (day.type == DayType.sick) {
      return PdfColors.red100;
    }
    if (day.type == DayType.vacation) {
      return PdfColors.lightBlue100;
    }
    return PdfColors.white;
  }

  static pw.Widget _headerCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static double _parseTimeToMinutes(String timeStr) {
    if (timeStr == '-' || timeStr.isEmpty) return 0;
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final mins = int.tryParse(parts[1]) ?? 0;
    return (hours * 60 + mins).toDouble();
  }
}
