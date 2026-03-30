class Profile {
  final String name;
  final String jobTitle;
  final String company;
  final String employeeId;
  final String department;
  final bool remindersEnabled;

  const Profile({
    required this.name,
    required this.jobTitle,
    required this.company,
    required this.employeeId,
    required this.department,
    required this.remindersEnabled,
  });

  Profile copyWith({
    String? name,
    String? jobTitle,
    String? company,
    String? employeeId,
    String? department,
    bool? remindersEnabled,
  }) {
    return Profile(
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}