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

  /// Konvertierung für SQLite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'job_title': jobTitle,
      'company': company,
      'employee_id': employeeId,
      'department': department,
      'reminders_enabled': remindersEnabled ? 1 : 0,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: map['name'] as String? ?? '',
      jobTitle: map['job_title'] as String? ?? '',
      company: map['company'] as String? ?? '',
      employeeId: map['employee_id'] as String? ?? '',
      department: map['department'] as String? ?? '',
      remindersEnabled: (map['reminders_enabled'] as int? ?? 0) == 1,
    );
  }
}