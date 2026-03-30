import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/profile/profile.dart';
import 'package:flutter_riverpod/legacy.dart';

final profileProvider = StateNotifierProvider<ProfileViewModel, Profile>((ref) {
  return ProfileViewModel();
});

const Profile _defaultProfile = Profile(
  name: 'Anas Dora',
  jobTitle: 'Software Developer',
  company: 'United Internet AG',
  employeeId: '00030397',
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
      state = Profile.fromMap(map);
    } else {
      // Standardprofil in DB speichern
      await DatabaseHelper.instance.upsertProfile(_defaultProfile.toMap());
    }
  }

  Future<void> updateProfile(Profile updated) async {
    state = updated;
    await DatabaseHelper.instance.upsertProfile(updated.toMap());
  }

  Future<void> toggleReminders(bool value) async {
    final updated = state.copyWith(remindersEnabled: value);
    state = updated;
    await DatabaseHelper.instance.upsertProfile(updated.toMap());
  }
}
