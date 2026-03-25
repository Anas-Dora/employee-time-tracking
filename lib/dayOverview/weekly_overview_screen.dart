import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../AppColors.dart';

class WeeklyOverviewScreen extends StatefulWidget {
  const  WeeklyOverviewScreen({super.key});

  @override
  State<WeeklyOverviewScreen> createState() => _WeeklyOverviewScreenState();
}

class _WeeklyOverviewScreenState extends State<WeeklyOverviewScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Weekly Overview'),
      ),
      body:  Center(
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              width: double.infinity,
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                ],
              )
            )
          ],
        )
      ),
    );
  }
}
