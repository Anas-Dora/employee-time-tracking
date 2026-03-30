// screens/home_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../AppColors.dart';
import 'home_viewmodel.dart';

class HomePageScreen extends ConsumerWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Home Page',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                DateFormat('EEEE, d. MMMM', 'de_DE').format(DateTime.now()),
                style: GoogleFonts.manrope(
                  textStyle: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Arbeitszeit Container
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                height: 375,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Text(
                      'Gesamtarbeitszeit',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: state.workTime.hours.toString().padLeft(2, '0'),
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 80,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: ':',
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 80,
                                color: AppColors.textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: state.workTime.minutes.toString().padLeft(2, '0'),
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 80,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: ':',
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 80,
                                color: AppColors.textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: state.workTime.seconds.toString().padLeft(2, '0'),
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 30,
                                color: AppColors.secondaryTextColor1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 290,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: state.isRunning
                            ? viewModel.startBreakTimer
                            : viewModel.startWorkTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.isRunning
                              ? const Color(0xffAFE9FA)
                              : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: state.isRunning
                            ? const Icon(
                                Icons.coffee,
                                color: Color(0xff2F6A79),
                                size: 24,
                              )
                            : const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                        label: Text(
                          state.isRunning ? 'Pause' : 'Start',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: state.isRunning
                                  ? const Color(0xff2F6A79)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 45,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: viewModel.pauseWorkTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffE7E8E9),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Icon(Icons.pause),
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: 45,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: viewModel.stopTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFFDAD6),
                              foregroundColor: const Color(0xff93000A),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Icon(Icons.stop),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Pausenzeit Container
              Container(
                width: double.infinity,
                height: 180,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xffAFE9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.coffee_outlined,
                            color: Color(0xff2F6A79),
                          ),
                        ),
                        Text(
                          'Pausenzeit',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      state.breakTime.formatted,
                      style: GoogleFonts.manrope(
                        textStyle: TextStyle(
                          color: const Color(0xff1D2D3A),
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Du hast heute ${state.breakTime.formatted} Pause gemacht.',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Fortschritt Container
              Container(
                width: double.infinity,
                height: 180,
                padding: EdgeInsets.all(24),
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xff002863),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'FORTSCHRITT',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              color: const Color(0xff002863),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tagesziel (8 Std.)',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          '${(viewModel.progress() * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: const Color(0xff191C1D),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: viewModel.progress(),
                        minHeight: 8,
                        backgroundColor: const Color(0xffE7E8E9),
                        valueColor: AlwaysStoppedAnimation(
                          const Color(0xff002863),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      viewModel.remainingTime(),
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
