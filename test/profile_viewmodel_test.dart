import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/profile/profile.dart';
import 'package:employee_time_tracking/profile/profile_vm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_setup.dart';

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  setUp(() async {
    await clearDatabaseTables();
  });

  test('legt bei leerer DB ein Default-Profil an', () async {
    final vm = ProfileViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final stored = await DatabaseHelper.instance.getProfile();

    expect(vm.state.name, 'Max Mustermann');
    expect(vm.state.remindersEnabled, isFalse);
    expect(stored, isNotNull);
    expect(stored!['name'], 'Max Mustermann');
  });

  test('updateProfile aktualisiert State und DB', () async {
    final vm = ProfileViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    const updated = Profile(
      name: 'Ada Lovelace',
      jobTitle: 'Engineer',
      company: 'ACME',
      employeeId: '999',
      department: 'R&D',
      remindersEnabled: false,
    );

    await vm.updateProfile(updated);
    final stored = await DatabaseHelper.instance.getProfile();

    expect(vm.state.name, 'Ada Lovelace');
    expect(stored!['name'], 'Ada Lovelace');
    expect(stored['employee_id'], '999');
  });

  test('toggleReminders(false) deaktiviert Erinnerungen und speichert', () async {
    final vm = ProfileViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await vm.updateProfile(vm.state.copyWith(remindersEnabled: true));
    final result = await vm.toggleReminders(false);
    final stored = await DatabaseHelper.instance.getProfile();

    expect(result, isFalse);
    expect(vm.state.remindersEnabled, isFalse);
    expect(stored!['reminders_enabled'], 0);
  });
}

