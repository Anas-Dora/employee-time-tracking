import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../AppColors.dart';
import 'monthly_overview_vm.dart';

class MonthlyOverviewScreen extends ConsumerWidget {
  const MonthlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monthlyOverviewProvider);
    final vm = ref.read(monthlyOverviewProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Monthly Overview'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monatliche Übersicht',
                      style: GoogleFonts.inter(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vm.formattedMonth,
                          style: GoogleFonts.manrope(
                            color: Color(0xFF002863),
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(
                          child: Row(
                            children: [
                              InkWell(
                                onTap: vm.previousMonth,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF3F4F5),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Color(0xff434651),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: vm.nextMonth,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF3F4F5),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xff434651),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoBox('Gesamtstunden', vm.totalHours),
                        vm.overtime == 0
                            ? _infoBox('Überstunden', vm.overtime)
                            : _overtimeInfoBox('Überstunden', vm.overtime),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 400,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 900),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Table(
                          border: TableBorder.all(
                            color: Color(0xFFE7E8E9),
                            width: 1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth(),
                            3: FlexColumnWidth(),
                            4: FlexColumnWidth(),
                            5: FlexColumnWidth(),
                          },
                          children: [
                            // Header Row
                            TableRow(
                              decoration: BoxDecoration(
                                color: Color(0xFFF3F4F5),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              children: [
                                _header('Datum'),
                                _header('Start'),
                                _header('Ende'),
                                _header('Pause'),
                                _header('Gesamtzeit'),
                                _header('+/- Stunden'),
                              ],
                            ),
                            ...state.days.map((day) {
                              return _row(context, ref, day, vm);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                height: 255,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 24,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Monatliche Benachrichtigungen',
                            style: GoogleFonts.manrope(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 24,
                              color: Color(0xFF2F6A79),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Ihr Überstundenguthaben für September \nhat den Zielwert erreicht.',
                              style: GoogleFonts.inter(
                                color: AppColors.secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 24,
                              color: Color(0xFFBA1A1A),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Fehlende Ausstempelung am 15. September. \nBitte überprüfen Sie dies manuell.',
                              style: GoogleFonts.inter(
                                color: AppColors.secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TableRow _row(
    BuildContext context,
    WidgetRef ref,
    WorkDay day,
    MonthlyOverviewVM vm,
  ) {
    return TableRow(
      children: [
        _buildLongPressCell(
          context,
          ref,
          day,
          vm,
          dateCell(DateFormat('dd. MMM, E', 'de_DE').format(day.date)),
        ),
        _buildLongPressCell(context, ref, day, vm, cell(day.start)),
        _buildLongPressCell(context, ref, day, vm, cell(day.end)),
        _buildLongPressCell(context, ref, day, vm, cell(day.pause)),
        _buildLongPressCell(context, ref, day, vm, toTalWorkCell(day.total)),
        _buildLongPressCell(
          context,
          ref,
          day,
          vm,
          day.diff == '+00:00' || day.diff == '-00:00'
              ? cell(day.diff)
              : diffCell(day.diff),
        ),
      ],
    );
  }

  static Widget _buildLongPressCell(
    BuildContext context,
    WidgetRef ref,
    WorkDay day,
    MonthlyOverviewVM vm,
    Widget child,
  ) {
    return GestureDetector(
      onLongPress: () {
        vm.showDayEditDialog(context, day);
      },
      child: child,
    );
  }


  static Widget _infoBox(String title, double value) {
    return Container(
      width: 165,
      height: 75,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}h',
            style: GoogleFonts.manrope(
              color: Color(0xFF002863),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _overtimeInfoBox(String title, double value) {
    return Container(
      width: 165,
      height: 75,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: value > 0 ? Color(0xFFAFE9FA) : Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Überstunden',
            style: GoogleFonts.inter(
              color: value > 0 ? Color(0xFF2F6A79) : Color(0xFFB00020),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}h',
            style: GoogleFonts.manrope(
              color: value > 0 ? Color(0xFF2F6A79) : Color(0xFFB00020),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget dateCell(String date) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          date,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF191C1D),
          ),
        ),
      ),
    );
  }

  static Widget cell(String text) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(8.0), child: Text(text)),
    );
  }

  static Widget toTalWorkCell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002863),
          ),
        ),
      ),
    );
  }

  static Widget diffCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        alignment: Alignment.center,
        height: 20,
        decoration: BoxDecoration(
          color: text.startsWith('+') ? Color(0xFFAFE9FA) : Color(0xFFFFE5E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: text.startsWith('+') ? Color(0xFF2F6A79) : Color(0xFFB00020),
          ),
        ),
      ),
    );
  }

  static TableCell _header(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              textStyle: const TextStyle(
                color: Color(0xFF002863),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
