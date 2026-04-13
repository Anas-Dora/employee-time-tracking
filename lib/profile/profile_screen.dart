import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/profile/profile_vm.dart';
import 'package:employee_time_tracking/widgets/yearly_pdf_export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final vm = ref.read(profileProvider.notifier);

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
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Benutzerprofil',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandPrimary,
                ),
              ),
              Text(
                'Verwalte deine persönlichen und organisatorischen chronometrischen Daten.',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: ResponsiveUtils.isMediumDevice(context) ? 180 : 290,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => YearlyPdfExportDialog(profile: profile),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text('Monatliches PDF herunterladen'),
                  icon: Icon(Icons.picture_as_pdf_outlined),
                ),
              ),
              SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: ResponsiveUtils.getResponsivePadding(context),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.brandAccentSoft,
                          ),
                          child: Icon(
                            Icons.person_outlined,
                            color: AppColors.brandPrimary,
                            size: 40,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: GoogleFonts.manrope(
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        32,
                                      ),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              Text(
                                profile.jobTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showEditProfileDialog(context, ref, profile),
                          icon: Icon(Icons.edit, color: AppColors.primary),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    _buildProfileInfo('Firma', profile.company),
                    _buildProfileInfo('Mitarbeiter-ID', profile.employeeId),
                    _buildProfileInfo('Abteilung', profile.department),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: ResponsiveUtils.getResponsivePadding(context),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Einstellungen',
                      style: GoogleFonts.manrope(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          32,
                        ),
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.softOutline,
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: AppColors.secondaryTextColor,
                                size: 30,
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Erinnerungen',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _showReminderInfoDialog(context),
                                      icon: const Icon(Icons.info_outline),
                                      iconSize: 18,
                                      color: AppColors.secondaryTextColor,
                                      tooltip:
                                          'Welche Benachrichtigungen gibt es?',
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Push-Benachrichtigungen',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Switch(
                          value: profile.remindersEnabled,
                          onChanged: (value) async {
                            final remindersEnabled = await vm.toggleReminders(
                              value,
                            );

                            if (!context.mounted ||
                                !value ||
                                remindersEnabled) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Benachrichtigungen wurden nicht freigegeben.',
                                ),
                              ),
                            );
                          },
                          trackColor: WidgetStateProperty<Color?>.fromMap(
                            <WidgetStatesConstraint, Color>{
                              WidgetState.selected: AppColors.brandPrimary,
                            },
                          ),
                          thumbColor: const WidgetStatePropertyAll<Color>(
                            AppColors.white,
                          ),
                        ),
                      ],
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

  Future<void> _showReminderInfoDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Benachrichtigungen bei Erinnerungen'),
        content: const Text(
          'Wenn Erinnerungen aktiviert sind, bekommst du Hinweise bei wichtigen Zeitgrenzen:\n\n'
          '- Nach 6 Stunden Arbeit, falls weniger als 30 Minuten Pause erfasst sind.\n'
          '- Nach 9 Stunden Arbeit, falls insgesamt weniger als 45 Minuten Pause erfasst sind.\n'
          '- Beim Ueberschreiten von 8 Stunden Arbeitszeit.\n'
          '- Eine deutliche Warnung beim Ueberschreiten von 10 Stunden Arbeitszeit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final nameController = TextEditingController(text: profile.name);
    final jobController = TextEditingController(text: profile.jobTitle);
    final companyController = TextEditingController(text: profile.company);
    final idController = TextEditingController(text: profile.employeeId);
    final departmentController = TextEditingController(
      text: profile.department,
    );

    final result = await showDialog<Profile>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Profil bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileTextField(controller: nameController, label: 'Name'),
              _buildProfileTextField(
                controller: jobController,
                label: 'Position',
              ),
              _buildProfileTextField(
                controller: companyController,
                label: 'Firma',
              ),
              _buildProfileTextField(
                controller: idController,
                label: 'Mitarbeiter-ID',
              ),
              _buildProfileTextField(
                controller: departmentController,
                label: 'Abteilung',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                profile.copyWith(
                  name: nameController.text,
                  jobTitle: jobController.text,
                  company: companyController.text,
                  employeeId: idController.text,
                  department: departmentController.text,
                ),
              );
            },
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionBackground,
                  foregroundColor: AppColors.brandPrimary,
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(MaterialState.pressed)) {
                      return AppColors.overlayPrimaryPressed;
                    }
                    return null;
                  }),
                ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(profileProvider.notifier).updateProfile(result);
    }
  }

  Widget _buildProfileTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Bitte $label eingeben';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textBreakTimer,
            ),
          ),
        ],
      ),
    );
  }
}
