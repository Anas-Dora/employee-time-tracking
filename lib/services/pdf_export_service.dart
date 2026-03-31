import 'dart:io';

import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:employee_time_tracking/profile/profile.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  static Future<void> generateMonthlyPdf(
    int year,
    int month,
    Profile profile,
  ) async {
    final pdf = pw.Document();

    final days = await _buildDaysForMonth(year, month);
    final totalMinutes = _sumMonthMinutes(days);

    final List<pw.Widget> content = [];

    content.add(_buildProfileHeader(profile, year));
    content.add(pw.SizedBox(height: 20));

    content.addAll(_buildMonthPage(year, month, days, totalMinutes));
    pdf.addPage(
      pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (ctx) => content),
    );

    final monthName = DateFormat.MMMM('de_DE').format(DateTime(year, month));
    final fileName = '${profile.name}_${monthName.toLowerCase()}_$year.pdf';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // PDF direkt öffnen
    await OpenFilex.open(file.path);
  }

  static Future<void> generateYearlyPdf(int year, Profile profile) async {
    final pdf = pw.Document();

    final List<pw.Widget> content = [];

    content.add(_buildProfileHeader(profile, year));
    content.add(pw.SizedBox(height: 20));

    for (int month = 1; month <= 12; month++) {
      final days = await _buildDaysForMonth(year, month);
      final totalMinutes = _sumMonthMinutes(days);

      content.addAll(_buildMonthPage(year, month, days, totalMinutes));
      // Seitenumbruch
      if (month != 12) {
        content.add(pw.NewPage());
      }

      content.add(pw.SizedBox(height: 30));
    }

    pdf.addPage(
      pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (ctx) => content),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Jahresbericht_${profile.name}_$year.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildProfileHeader(Profile profile, int year) {
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
    return days;
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
    if (day.type.name == 'sick') {
      return PdfColors.red100;
    }
    if (day.type.name == 'vacation') {
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
