import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/profile/profile_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../AppColors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final vm = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
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
                  color: Color(0xFF002863),
                ),
              ),
              Text(
                'Verwalten Sie Ihre persönlichen und organisatorischen chronometrischen Daten',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 290,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                            color: Color(0xFFD9E2FF),
                          ),
                          child: Icon(
                            Icons.person_outlined,
                            color: Color(0xFF002863),
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
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF002863),
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
                height: 205,
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Einstellungen',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF002863),
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
                                color: Color(0xFFE7E8E9),
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
                                Text(
                                  'Erinnerungen',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF191C1D),
                                  ),
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
                          onChanged: vm.toggleReminders,
                          trackColor: WidgetStateProperty<Color?>.fromMap(
                            <WidgetStatesConstraint, Color>{
                              WidgetState.selected: Color(0xFF002863)
                            },
                          ),
                          thumbColor: const WidgetStatePropertyAll<Color>(
                            Colors.white,
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
              color: Color(0xFF1D2D3A),
            ),
          ),
        ],
      ),
    );
  }
}
