import 'package:employee_time_tracking/profile/profile.dart';
import 'package:flutter_riverpod/legacy.dart';

final profileProvider = StateNotifierProvider<ProfileViewModel, Profile>((ref) {
  return ProfileViewModel();
});

class ProfileViewModel extends StateNotifier<Profile> {
  ProfileViewModel()
    : super(
        const Profile(
          name: 'Anas Dora',
          jobTitle: 'Software Developer',
          company: 'United Internet AG',
          employeeId: '00030397',
          department: 'Customer App Development',
          remindersEnabled: false,
        ),
      );

  void updateProfile(Profile updated) {
    state = updated;
  }

  void toggleReminders(bool value) {
    state = state.copyWith(remindersEnabled: value);
  }
}
