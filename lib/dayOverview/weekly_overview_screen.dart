import 'package:employee_time_tracking/dayOverview/weekly_overview_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'day_overview.dart';

class WeeklyOverviewScreen extends ConsumerWidget {
  const WeeklyOverviewScreen({super.key});

  static String _formatDuration(Duration value) {
    final h = value.inHours;
    final m = value.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  static void _showSegmentsSheet(BuildContext context, DayOverview day) {
    if (day.orderedSegments.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arbeitszeiten am ${DateFormat('dd.MM.yyyy', 'de_DE').format(day.date)}',
                    style: GoogleFonts.manrope(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: day.orderedSegments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final segment = day.orderedSegments[index];
                        return Text(
                          '${DateFormat('HH:mm').format(segment.startTime)} - ${DateFormat('HH:mm').format(segment.endTime)}',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20),
                  Text('Gesamtarbeitszeit: ${_formatDuration(day.workDuration ?? Duration.zero)}'),
                  const SizedBox(height: 4),
                  Text('Gesamtpause: ${_formatDuration(day.computedBreakDuration)}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weeklyOverviewProvider);
    final vm = ref.read(weeklyOverviewProvider.notifier);

    String weekRange =
        "${DateFormat('d. MMMM', 'de_DE').format(week.startDate)} – ${DateFormat('d. MMMM', 'de_DE').format(week.endDate)}";

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'de_DE').format(DateTime.now()),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Wochen-übersicht',
                      style: GoogleFonts.manrope(
                        textStyle: TextStyle(
                          color: AppColors.brandPrimary,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 48),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.subtleSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: vm.previousWeek,
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              weekRange,
                              style: GoogleFonts.manrope(
                                textStyle: TextStyle(
                                  color: AppColors.brandPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: vm.nextWeek,
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [AppColors.brandPrimary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gesamtarbeitsstunden',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            '${week.totalWork.inHours}h ${week.totalWork.inMinutes.remainder(60)}m',
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                color: AppColors.white,
                                fontSize: 60,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${vm.progressPercent}% wöchentliches Ziel erreicht',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                color: AppColors.textOnPrimaryDim,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -35,
                      bottom: -35,
                      child: Opacity(
                        opacity: 0.10,
                        child: Icon(
                          Icons.access_time_filled,
                          size: 220,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackground,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Durchschnittliche Pause",
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${week.averageBreak.inMinutes}m',
                      style: GoogleFonts.manrope(
                        textStyle: TextStyle(
                          color: AppColors.brandPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Innerhalb der Zielreichweite",
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.textVacation,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),
              for (int i = 0; i < week.days.length; i++) ...[
                _buildDayCard(context, week.days[i], vm),
                if (i != week.days.length - 1) SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    DayOverview day,
    WeeklyOverviewViewModel vm,
  ) {
    final isSmall = ResponsiveUtils.isSmallDevice(context);
    final labelFontSize = isSmall ? 11.0 : 12.0;
    final valueFontSize = isSmall ? 16.0 : 18.0;
    final sectionSpacing = isSmall ? 10.0 : 16.0;
    final buttonGap = isSmall ? 8.0 : 12.0;
    final buttonSize = isSmall ? 40.0 : 45.0;

    Color cardColor;
    Color borderColor;
    Color deteCardColor;
    Color primaryTextColor;
    Color secondaryTextColor;
    String title;

    if (day.isHoliday) {
      cardColor = AppColors.holidayBackground;
      borderColor = AppColors.vacationOutline;
      deteCardColor = AppColors.textHoliday;
      primaryTextColor = AppColors.textHoliday;
      secondaryTextColor = AppColors.textHolidayMuted;
      title = 'Feiertag';
    } else {
      switch (day.type) {
        case DayType.workday:
          cardColor = AppColors.white;
          borderColor = AppColors.white;
          deteCardColor = AppColors.brandPrimary;
          primaryTextColor = AppColors.brandPrimary;
          secondaryTextColor = AppColors.secondaryTextColor;
          title = "Werktag";
          break;
        case DayType.sick:
          cardColor = AppColors.sickBackgroundSoft;
          borderColor = AppColors.sickOutline;
          deteCardColor = AppColors.textSickStrong;
          primaryTextColor = AppColors.textSickStrong;
          secondaryTextColor = AppColors.textSickMuted;
          title = "Krank";
          break;
        case DayType.vacation:
          cardColor = AppColors.vacationBackgroundSoft;
          borderColor = AppColors.vacationOutline;
          deteCardColor = AppColors.textVacation;
          primaryTextColor = AppColors.textVacation;
          secondaryTextColor = AppColors.textVacationMuted;
          title = "Urlaub";
          break;
        default:
          cardColor = AppColors.neutralTint;
          borderColor = AppColors.white;
          deteCardColor = AppColors.brandPrimary;
          primaryTextColor = AppColors.brandPrimary;
          secondaryTextColor = AppColors.secondaryTextColor;
          title = "Werktag";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: deteCardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('d').format(day.date),
                        style: GoogleFonts.manrope(
                          textStyle: TextStyle(
                             color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('E', "de_DE").format(day.date).toUpperCase(),
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                             color: AppColors.textDateOnDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            color: primaryTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.5),
                      Row(
                        children: [
                          day.isHoliday
                              ? SizedBox.shrink()
                              : Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: secondaryTextColor,
                                ),
                          SizedBox(width: 4),
                          Expanded(
                            child: day.isHoliday
                                ? SizedBox.shrink()
                                : Text(
                                    "${day.type == DayType.workday && day.effectiveStartTime != null ? DateFormat('HH:mm').format(day.effectiveStartTime!) : '00:00'} - ${day.type == DayType.workday && day.effectiveEndTime != null ? DateFormat('HH:mm').format(day.effectiveEndTime!) : '00:00'}",
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                day.isHoliday
                    ? SizedBox.shrink()
                    : IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          vm.showEditDialog(context, day);
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 24,
                          color: secondaryTextColor,
                        ),
                      ),
              ],
            ),
            SizedBox(height: 16),
            day.isHoliday
                ? SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              "Arbeitszeit",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(minWidth: isSmall ? 70 : 90),
                              child: GestureDetector(
                                onLongPress: () => _showSegmentsSheet(context, day),
                                child: Text(
                                  '${day.workDuration?.inHours ?? 0}h ${day.workDuration?.inMinutes.remainder(60) ?? 0}m',
                                  style: GoogleFonts.manrope(
                                    textStyle: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: valueFontSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: sectionSpacing),
                        Column(
                          children: [
                            Text(
                              "Pausen",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(minWidth: isSmall ? 55 : 70),
                              child: Text(
                                '${day.type == DayType.workday ? day.computedBreakDuration.inMinutes : 0}m',
                                style: GoogleFonts.manrope(
                                  textStyle: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: valueFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: sectionSpacing),
                        Row(
                          children: [
                            _buildDayButton(
                              isActive: day.type == DayType.sick,
                              icon: Icons.medical_services,
                              primaryTextColor: primaryTextColor,
                              size: buttonSize,
                              onTap: () {
                                vm.toggleDayType(day.date, DayType.sick);
                              },
                            ),
                            SizedBox(width: buttonGap),
                            _buildDayButton(
                              isActive: day.type == DayType.vacation,
                              icon: Icons.beach_access,
                              primaryTextColor: primaryTextColor,
                              size: buttonSize,
                              onTap: () {
                                vm.toggleDayType(day.date, DayType.vacation);
                              },
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayButton({
    required bool isActive,
    required IconData icon,
    required Color primaryTextColor,
    required VoidCallback onTap,
    double size = 45,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? primaryTextColor : AppColors.buttonNeutral,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isActive ? Icons.check : icon,
          size: size * 0.44,
          color: isActive ? AppColors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

