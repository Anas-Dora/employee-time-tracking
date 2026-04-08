import 'dart:ffi';
import 'dart:isolate';

import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/services/holiday_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

class FakeHolidayService extends HolidayService {
  FakeHolidayService({required this.holidayDates});

  final Set<DateTime> holidayDates;

  @override
  Future<bool> isHoliday({required DateTime date, required String bundesland}) async {
    final day = DateTime(date.year, date.month, date.day);
    return holidayDates.contains(day);
  }
}

Future<void> configureTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Linux-Runner liefern oft nur libsqlite3.so.0 statt libsqlite3.so.
  open.overrideFor(
    OperatingSystem.linux,
    () => DynamicLibrary.open('libsqlite3.so.0'),
  );

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final dbName = 'employee_time_tracking_test_${Isolate.current.hashCode}.db';
  DatabaseHelper.testDatabaseNameOverride = dbName;

  final dbPath = await getDatabasesPath();
  await deleteDatabase('$dbPath/$dbName');
  await DatabaseHelper.instance.database;
  await clearDatabaseTables();
}

Future<void> clearDatabaseTables() async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('work_segments');
  await db.delete('day_entries');
  await db.delete('profile');
  await db.delete('holidays');
}
