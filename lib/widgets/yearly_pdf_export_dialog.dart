import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/services/pdf_export_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../AppColors.dart';

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
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen des PDF: $e'),
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.orange,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel
            Text(
              'Monatliche PDF-Berichte',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF002863),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wählen Sie Monate zum Herunterladen aus',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Jahresnavigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _previousYear,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 120,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      selectedYear.toString(),
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF002863),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _nextYear,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
                Text(
                  'Alle Monate auswählen',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF002863),
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
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE7E8E9),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF002863),
                              ),
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
                                      ? Colors.grey
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
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : selectedMonths.length == 12
                    ? _downloadYearlyPdf
                    : _downloadSelectedMonths,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
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
                            Colors.white,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
