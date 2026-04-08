import 'package:employee_time_tracking/profile/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile', () {
    test('toMap und fromMap konvertieren konsistent', () {
      const profile = Profile(
        name: 'Ada Lovelace',
        jobTitle: 'Engineer',
        company: 'ACME',
        employeeId: '42',
        department: 'Platform',
        remindersEnabled: true,
      );

      final map = profile.toMap();
      final restored = Profile.fromMap(map);

      expect(restored.name, profile.name);
      expect(restored.jobTitle, profile.jobTitle);
      expect(restored.company, profile.company);
      expect(restored.employeeId, profile.employeeId);
      expect(restored.department, profile.department);
      expect(restored.remindersEnabled, isTrue);
    });

    test('copyWith aktualisiert nur uebergebene Werte', () {
      const profile = Profile(
        name: 'Ada Lovelace',
        jobTitle: 'Engineer',
        company: 'ACME',
        employeeId: '42',
        department: 'Platform',
        remindersEnabled: false,
      );

      final updated = profile.copyWith(company: 'Contoso', remindersEnabled: true);

      expect(updated.name, profile.name);
      expect(updated.company, 'Contoso');
      expect(updated.remindersEnabled, isTrue);
    });
  });
}

