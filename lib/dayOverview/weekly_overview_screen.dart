import 'package:employee_time_tracking/dayOverview/weekly_overview_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../AppColors.dart';
import 'day_overview.dart';

class WeeklyOverviewScreen extends ConsumerWidget {
  const WeeklyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weeklyOverviewProvider);
    final vm = ref.read(weeklyOverviewProvider.notifier);

    String weekRange =
        "${DateFormat('d. MMMM', 'de_DE').format(week.startDate)} – ${DateFormat('d. MMMM', 'de_DE').format(week.endDate)}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Weekly Overview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 280,
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
                            color: Color(0xFF002863),
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 40,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: vm.previousWeek,
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                  color: Color(0xFF002863),
                                ),
                              ),
                            ),
                            Text(
                              weekRange,
                              style: GoogleFonts.manrope(
                                textStyle: TextStyle(
                                  color: Color(0xFF002863),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: vm.nextWeek,
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color(0xFF002863),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Color(0xFF002863), AppColors.primary],
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
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Text(
                              '${week.totalWork.inHours}h ${week.totalWork.inMinutes.remainder(60)}m',
                              style: GoogleFonts.manrope(
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 60,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${vm.progressPercent}% wöchentliches Ziel erreicht',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: Color(0xFFAFC6FF),
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 170,
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
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
                            color: Color(0xFF002863),
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
                            color: Color(0xFF2A6675),
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
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    DayOverview day,
    WeeklyOverviewViewModel vm,
  ) {
    Color cardColor;
    Color borderColor;
    Color deteCardColor;
    Color primaryTextColor;
    Color secondaryTextColor;
    String title;

    switch (day.type) {
      case DayType.workday:
        cardColor = Colors.white;
        borderColor = Colors.white;
        deteCardColor = Color(0xFF002863);
        primaryTextColor = Color(0xFF002863);
        secondaryTextColor = AppColors.secondaryTextColor;
        title = "Werktag";
        break;
      case DayType.sick:
        cardColor = Color(0x33FFDAD6);
        borderColor = Color(0x1ABA1A1A);
        deteCardColor = Color(0xFFBA1A1A);
        primaryTextColor = Color(0xFFBA1A1A);
        secondaryTextColor = Color(0xB3BA1A1A);
        title = "Krank";
        break;
      case DayType.vacation:
        cardColor = Color(0x1AAFE9FA);
        borderColor = Color(0x1A2F6A79);
        deteCardColor = Color(0xFF2F6A79);
        primaryTextColor = Color(0xFF2F6A79);
        secondaryTextColor = Color(0xB32F6A79);
        title = "Urlaub";
        break;
      default:
        cardColor = Color(0x1AC3C6D3);
        borderColor = Colors.white;
        deteCardColor = Color(0xFF002863);
        primaryTextColor = Color(0xFF002863);
        secondaryTextColor = AppColors.secondaryTextColor;
        title = "Werktag";
    }

    return Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cardColor,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'E',
                              "de_DE",
                            ).format(day.date).toUpperCase(),
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                color: Color(0xFFF8F9FA),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    Column(
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
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: secondaryTextColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${day.type == DayType.workday && day.startTime != null ? DateFormat('HH:mm').format(day.startTime!) : '00:00'} - ${day.type == DayType.workday && day.endTime != null ? DateFormat('HH:mm').format(day.endTime!) : '00:00'}",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 72),
                    IconButton(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Arbeitszeit",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${day.workDuration?.inHours ?? 0}h ${day.workDuration?.inMinutes.remainder(60) ?? 0}m',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 32),
                    Column(
                      children: [
                        Text(
                          "Pausen",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${day.type == DayType.workday && day.breakDuration != null ? day.breakDuration?.inMinutes : "0"}m',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 32),
                    Row(
                      children: [
                        _buildDayButton(
                          isActive: day.type == DayType.sick,
                          icon: Icons.medical_services,
                          primaryTextColor: primaryTextColor,
                          onTap: () {
                            vm.toggleDayType(day.date, DayType.sick);
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildDayButton(
                          isActive: day.type == DayType.vacation,
                          icon: Icons.beach_access,
                          primaryTextColor: primaryTextColor,
                          onTap: () {
                            vm.toggleDayType(day.date, DayType.vacation);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  Widget _buildDayButton({
    required bool isActive,
    required IconData icon,
    required Color primaryTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? primaryTextColor : const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isActive ? Icons.check : icon,
          size: 24,
          color: isActive ? Colors.white : const Color(0xFF434651),
        ),
      ),
    );
  }
}
