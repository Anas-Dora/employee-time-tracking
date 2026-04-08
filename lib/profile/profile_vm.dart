import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/services/notification_service.dart';
import 'package:flutter_riverpod/legacy.dart';

final profileProvider = StateNotifierProvider<ProfileViewModel, Profile>((ref) {
  return ProfileViewModel();
});

const Profile _defaultProfile = Profile(
  name: 'Max Mustermann',
  jobTitle: 'Software Engineer',
  company: '1&1 AG',
  employeeId: '123456',
  department: 'Customer App Development',
  remindersEnabled: false,
);

class ProfileViewModel extends StateNotifier<Profile> {
  ProfileViewModel() : super(_defaultProfile) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final map = await DatabaseHelper.instance.getProfile();
    if (map != null) {
      final profile = Profile.fromMap(map);
      if (profile.remindersEnabled) {
        await NotificationService.instance.init();
      }
      NotificationService.instance.enabled = profile.remindersEnabled;
      state = profile;
    } else {
      // Standardprofil in DB speichern
      NotificationService.instance.enabled = false;
      await DatabaseHelper.instance.upsertProfile(_defaultProfile.toMap());
    }
  }

  Future<void> updateProfile(Profile updated) async {
    state = updated;
    await DatabaseHelper.instance.upsertProfile(updated.toMap());
  }

  Future<bool> toggleReminders(bool value) async {
    if (value == state.remindersEnabled) {
      return state.remindersEnabled;
    }

    if (value) {
      final permissionGranted =
          await NotificationService.instance.initAndRequestPermission();

      if (!permissionGranted) {
        NotificationService.instance.enabled = false;
        return false;
      }
    } else {
      await NotificationService.instance.disableReminders();
    }

    final updated = state.copyWith(remindersEnabled: value);
    NotificationService.instance.enabled = value;
    state = updated;
    await DatabaseHelper.instance.upsertProfile(updated.toMap());

    return state.remindersEnabled;
  }
}
