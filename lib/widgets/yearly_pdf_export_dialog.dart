import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/services/pdf_export_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

class YearlyPdfExportDialog extends StatefulWidget {
  final Profile profile;

  const YearlyPdfExportDialog({super.key, required this.profile});

  @override
  State<YearlyPdfExportDialog> createState() => _YearlyPdfExportDialogState();
}

class _YearlyPdfExportDialogState extends State<YearlyPdfExportDialog> {
  late int selectedYear;
  final Set<int> selectedMonths = {};
  bool isLoading = false;
  int? loadingMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
  }

  void _previousYear() {
    setState(() {
      selectedYear--;
      selectedMonths.clear();
    });
  }

  void _nextYear() {
    setState(() {
      selectedYear++;
      selectedMonths.clear();
    });
  }

  void _toggleMonth(int month) {
    setState(() {
      if (selectedMonths.contains(month)) {
        selectedMonths.remove(month);
      } else {
        selectedMonths.add(month);
      }
    });
  }

  void _selectAllMonths() {
    setState(() {
      if (selectedMonths.length == 12) {
        selectedMonths.clear();
      } else {
        for (int i = 1; i <= 12; i++) {
          selectedMonths.add(i);
        }
      }
    });
  }

  Future<void> _downloadMonth(int month) async {
    setState(() {
      isLoading = true;
      loadingMonth = month;
    });

    try {
      await PdfExportService.generateMonthlyPdf(
        selectedYear,
        month,
        widget.profile,
      );
      if (mounted) {
        final monthName = DateFormat.MMMM(
          'de_DE',
        ).format(DateTime(selectedYear, month));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$monthName $selectedYear PDF wird geöffnet...'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen des PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          loadingMonth = null;
        });
      }
    }
  }

  Future<void> _downloadSelectedMonths() async {
    if (selectedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie mindestens einen Monat aus'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      for (final month in selectedMonths) {
        await PdfExportService.generateMonthlyPdf(
          selectedYear,
          month,
          widget.profile,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedMonths.length} Monat(e) PDF(s) werden geöffnet!',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen des PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadYearlyPdf() async {
    setState(() {
      isLoading = true;
      loadingMonth = null;
    });

    try {
      await PdfExportService.generateYearlyPdf(selectedYear, widget.profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jahresbericht $selectedYear wird geoeffnet...'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen des Jahres-PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = ResponsiveUtils.isSmallDevice(context);
    final isVerySmall = screenWidth < 340;
    final horizontalPadding = isVerySmall
        ? 12.0
        : isSmall
        ? 16.0
        : 24.0;
    final yearControlSize = isVerySmall ? 38.0 : isSmall ? 42.0 : 50.0;
    final yearBoxWidth = isVerySmall ? 88.0 : isSmall ? 100.0 : 120.0;
    final yearSpacing = isVerySmall ? 8.0 : 16.0;
    final titleSize = ResponsiveUtils.getResponsiveFontSize(context, 28);
    final bodySize = ResponsiveUtils.getResponsiveFontSize(context, 14);

    final months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmall ? 360 : 460,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Titel
            Text(
              'Monatliche PDF-Berichte',
              style: GoogleFonts.manrope(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Wählen Sie Monate zum Herunterladen aus',
              style: GoogleFonts.inter(
                fontSize: bodySize,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // Jahresnavigation
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _previousYear,
                      child: Container(
                        width: yearControlSize,
                        height: yearControlSize,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: yearSpacing),
                    Container(
                      width: yearBoxWidth,
                      height: yearControlSize,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          selectedYear.toString(),
                          style: GoogleFonts.manrope(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: yearSpacing),
                    InkWell(
                      onTap: _nextYear,
                      child: Container(
                        width: yearControlSize,
                        height: yearControlSize,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Alle auswählen
            Row(
              children: [
                Checkbox(
                  value: selectedMonths.length == 12,
                  onChanged: (_) => _selectAllMonths(),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    'Alle Monate auswählen',
                    style: GoogleFonts.inter(
                      fontSize: bodySize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Monatsliste
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(12, (index) {
                    final month = index + 1;
                    final monthName = months[index];
                    final isSelected = selectedMonths.contains(month);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                               : AppColors.softOutline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleMonth(month),
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Text(
                              monthName,
                              style: GoogleFonts.inter(
                                fontSize: bodySize,
                                fontWeight: FontWeight.w600,
                                 color: AppColors.brandPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLoading && loadingMonth == month)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          else
                            InkWell(
                              onTap: isLoading
                                  ? null
                                  : () => _downloadMonth(month),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.file_download_outlined,
                                  color: isLoading
                                      ? AppColors.disabled
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: isVerySmall ? 60 : 55,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : selectedMonths.length == 12
                    ? _downloadYearlyPdf
                    : _downloadSelectedMonths,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.disabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(
                  isLoading
                      ? 'Wird heruntergeladen...'
                      : selectedMonths.length == 12
                      ? 'Jahresbericht herunterladen'
                      : 'Ausgewählte Monate herunterladen (${selectedMonths.length})',
                  style: GoogleFonts.inter(
                    fontSize: bodySize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Schließen',
                  style: GoogleFonts.inter(
                    fontSize: bodySize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
