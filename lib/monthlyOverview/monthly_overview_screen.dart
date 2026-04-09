import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'MonthlyNotification.dart';
import 'monthly_overview_vm.dart';

class MonthlyOverviewScreen extends ConsumerWidget {
  const MonthlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monthlyOverviewProvider);
    final vm = ref.read(monthlyOverviewProvider.notifier);
    final notifications = vm.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Zeitify',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.appBarBackground,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: ResponsiveUtils.getResponsivePadding(context),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
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
                        Expanded(
                          child: Text(
                            vm.formattedMonth,
                            style: GoogleFonts.manrope(
                              color: AppColors.brandPrimary,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                30,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
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
                                    color: AppColors.subtleSurface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: vm.nextMonth,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.subtleSurface,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.textSecondary,
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
                        SizedBox(
                          width: ResponsiveUtils.getResponsiveSize(context, 12),
                        ),
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
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 900),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        border: TableBorder.all(
                          color: AppColors.softOutline,
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
                              color: AppColors.subtleSurface,
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
              SizedBox(height: 20),
              Container(
                padding: ResponsiveUtils.getResponsivePadding(context),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.subtleSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              16,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    for (int i = 0; i < notifications.length; i++) ...[
                      _notificationCard(notifications[i]),
                      if (i < notifications.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
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
    final formattedDate = DateFormat('dd. MMM, E', 'de_DE').format(day.date);

    Widget resolveDateCell() {
      if (day.isHoliday) {
        return dateCell(
          formattedDate,
          backgroundColor: AppColors.holidayBackground,
          textColor: AppColors.textHoliday,
        );
      }

      switch (day.type) {
        case DayType.vacation:
          return dateCell(
            formattedDate,
            backgroundColor: AppColors.vacationBackground,
            textColor: AppColors.textVacation,
          );
        case DayType.sick:
          return dateCell(
            formattedDate,
            backgroundColor: AppColors.sickBackground,
            textColor: AppColors.textSick,
          );
        default:
          return dateCell(formattedDate);
      }
    }

    Widget resolveCell(Widget Function() defaultBuilder) {
      if (day.isHoliday) {
        return holidayCell();
      }

      switch (day.type) {
        case DayType.vacation:
          return vacationCell();
        case DayType.sick:
          return sickCell();
        default:
          return defaultBuilder();
      }
    }

    return TableRow(
      children: [
        _wrap(context, ref, day, vm, resolveDateCell()),

        _wrap(context, ref, day, vm, resolveCell(() => cell(day.start))),

        _wrap(context, ref, day, vm, resolveCell(() => cell(day.end))),

        _wrap(context, ref, day, vm, resolveCell(() => cell(day.pause))),

        _wrap(
          context,
          ref,
          day,
          vm,
          resolveCell(() => toTalWorkCell(day.total)),
        ),

        _wrap(
          context,
          ref,
          day,
          vm,
          resolveCell(
            () => (day.diff == '+00:00' || day.diff == '-00:00')
                ? cell(day.diff)
                : diffCell(day.diff),
          ),
        ),
      ],
    );
  }

  static Widget _wrap(
    BuildContext context,
    WidgetRef ref,
    WorkDay day,
    MonthlyOverviewVM vm,
    Widget child,
  ) {
    return _buildLongPressCell(context, ref, day, vm, child);
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

  static Widget _notificationCard(MonthlyNotification notification) {
    final config = _notificationVisuals(notification.type);

    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, size: 24, color: config.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notification.message,
              style: GoogleFonts.inter(
                color: AppColors.secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static _NotificationVisuals _notificationVisuals(
    MonthlyNotificationType type,
  ) {
    switch (type) {
      case MonthlyNotificationType.missingEntry:
        return const _NotificationVisuals(
          icon: Icons.edit_calendar_outlined,
          color: AppColors.textWarning,
        );
      case MonthlyNotificationType.incompleteEntry:
      case MonthlyNotificationType.negativeOvertime:
        return const _NotificationVisuals(
          icon: Icons.error_outline,
          color: AppColors.textSickStrong,
        );
      case MonthlyNotificationType.overtimeGoal:
        return const _NotificationVisuals(
          icon: Icons.check_circle_outline,
          color: AppColors.textVacation,
        );
      case MonthlyNotificationType.none:
        return const _NotificationVisuals(
          icon: Icons.notifications_none_outlined,
          color: AppColors.primary,
        );
    }
  }

  static Widget _infoBox(String title, double value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.subtleSurface,
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
                color: AppColors.brandPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _overtimeInfoBox(String title, double value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value > 0
              ? AppColors.vacationBackground
              : AppColors.sickBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Überstunden',
              style: GoogleFonts.inter(
                color: value > 0 ? AppColors.textVacation : AppColors.textSick,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}h',
              style: GoogleFonts.manrope(
                color: value > 0 ? AppColors.textVacation : AppColors.textSick,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget dateCell(
    String date, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  static Widget cell(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  static Widget vacationCell() {
    return Container(
      color: AppColors.vacationBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "-",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textVacation,
            ),
          ),
        ),
      ),
    );
  }

  static Widget sickCell() {
    return Container(
      color: AppColors.sickBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "-",
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSick),
          ),
        ),
      ),
    );
  }

  static Widget holidayCell() {
    return Container(
      color: AppColors.holidayBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "-",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textHoliday,
            ),
          ),
        ),
      ),
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
            color: AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }

  static Widget diffCell(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        right: 34.0,
        left: 34.0,
      ),
      child: Container(
        alignment: Alignment.center,
        height: 20,
        decoration: BoxDecoration(
          color: text == '-'
              ? AppColors.white
              : (text.startsWith('+')
                    ? AppColors.vacationBackground
                    : AppColors.sickBackground),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: text == '-'
              ? GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary)
              : GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: text.startsWith('+')
                      ? AppColors.textVacation
                      : AppColors.textSick,
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
                color: AppColors.brandPrimary,
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

class _NotificationVisuals {
  final IconData icon;
  final Color color;

  const _NotificationVisuals({required this.icon, required this.color});
}
