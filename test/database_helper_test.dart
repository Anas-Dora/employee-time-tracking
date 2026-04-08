import 'package:employee_time_tracking/database/database_helper.dart';
import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_setup.dart';

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  setUp(() async {
    await clearDatabaseTables();
  });

  group('DatabaseHelper day entries', () {
    test('upsertDayEntry, getDayEntry, week und month liefern passende Daten', () async {
      final januaryMonday = DateTime(2026, 1, 5);
      final januarySunday = DateTime(2026, 1, 11);
      final februaryDay = DateTime(2026, 2, 2);

      await DatabaseHelper.instance.upsertDayEntry(
        DayOverview(date: januaryMonday, type: DayType.workday).toMap(),
      );
      await DatabaseHelper.instance.upsertDayEntry(
        DayOverview(date: januarySunday, type: DayType.vacation).toMap(),
      );
      await DatabaseHelper.instance.upsertDayEntry(
        DayOverview(date: februaryDay, type: DayType.sick).toMap(),
      );

      final single = await DatabaseHelper.instance.getDayEntry(januaryMonday);
      final weekEntries = await DatabaseHelper.instance.getDayEntriesForWeek(januaryMonday);
      final januaryEntries = await DatabaseHelper.instance.getDayEntriesForMonth(2026, 1);
      final februaryEntries = await DatabaseHelper.instance.getDayEntriesForMonth(2026, 2);

      expect(single, isNotNull);
      expect(single!['type'], 'workday');
      expect(weekEntries.map((entry) => entry['type']), containsAll(<String>['workday', 'vacation']));
      expect(januaryEntries, hasLength(2));
      expect(februaryEntries, hasLength(1));
    });

    test('deleteDayEntry entfernt Tageseintrag und Work-Segmente', () async {
      final date = DateTime(2026, 1, 5);

      await DatabaseHelper.instance.upsertDayEntry(
        DayOverview(date: date, type: DayType.workday).toMap(),
      );
      await DatabaseHelper.instance.insertWorkSegment(
        date: date,
        startTime: DateTime(2026, 1, 5, 9, 0),
        endTime: DateTime(2026, 1, 5, 12, 0),
      );

      await DatabaseHelper.instance.deleteDayEntry(date);

      expect(await DatabaseHelper.instance.getDayEntry(date), isNull);
      expect(await DatabaseHelper.instance.getWorkSegmentsForDate(date), isEmpty);
    });
  });

  group('DatabaseHelper work segments', () {
    test('replaceWorkSegmentsForDate ersetzt bestehende Segmente sortiert', () async {
      final date = DateTime(2026, 1, 6);

      await DatabaseHelper.instance.insertWorkSegment(
        date: date,
        startTime: DateTime(2026, 1, 6, 9, 0),
        endTime: DateTime(2026, 1, 6, 11, 0),
      );

      await DatabaseHelper.instance.replaceWorkSegmentsForDate(
        date: date,
        segments: <Map<String, String>>[
          WorkSegment(
            startTime: DateTime(2026, 1, 6, 13, 0),
            endTime: DateTime(2026, 1, 6, 17, 0),
          ).toDbMap(),
          WorkSegment(
            startTime: DateTime(2026, 1, 6, 8, 0),
            endTime: DateTime(2026, 1, 6, 12, 0),
          ).toDbMap(),
        ],
      );

      final segments = await DatabaseHelper.instance.getWorkSegmentsForDate(date);
      final weekSegments = await DatabaseHelper.instance.getWorkSegmentsForWeek(DateTime(2026, 1, 5));
      final monthSegments = await DatabaseHelper.instance.getWorkSegmentsForMonth(2026, 1);

      expect(segments, hasLength(2));
      expect(DateTime.parse(segments.first['start_time'] as String), DateTime(2026, 1, 6, 8, 0));
      expect(DateTime.parse(segments.last['start_time'] as String), DateTime(2026, 1, 6, 13, 0));
      expect(weekSegments, hasLength(2));
      expect(monthSegments, hasLength(2));
    });
  });

  group('DatabaseHelper profile und holiday cache', () {
    test('upsertProfile und getProfile funktionieren', () async {
      await DatabaseHelper.instance.upsertProfile(<String, dynamic>{
        'name': 'Ada Lovelace',
        'job_title': 'Engineer',
        'company': 'ACME',
        'employee_id': '123',
        'department': 'Platform',
        'reminders_enabled': 1,
      });

      final profile = await DatabaseHelper.instance.getProfile();

      expect(profile, isNotNull);
      expect(profile!['id'], 1);
      expect(profile['name'], 'Ada Lovelace');
      expect(profile['reminders_enabled'], 1);
    });

    test('holiday cache kann speichern, lesen und leeren', () async {
      await DatabaseHelper.instance.saveHoliday(
        date: '2026-12-25',
        name: 'Weihnachten',
        bundesland: 'BW',
      );
      await DatabaseHelper.instance.saveHolidays(
        holidays: <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-01-01', 'name': 'Neujahr'},
          <String, dynamic>{'date': '2026-04-03', 'name': 'Karfreitag'},
        ],
        bundesland: 'BW',
      );

      final cached = await DatabaseHelper.instance.isHolidayInCache(
        date: '2026-12-25',
        bundesland: 'BW',
      );
      final single = await DatabaseHelper.instance.getHolidayFromCache(
        date: '2026-12-25',
        bundesland: 'BW',
      );
      final yearHolidays = await DatabaseHelper.instance.getHolidaysForYear(
        year: 2026,
        bundesland: 'BW',
      );

      expect(cached, isTrue);
      expect(single, isNotNull);
      expect(single!['name'], 'Weihnachten');
      expect(yearHolidays, hasLength(3));

      await DatabaseHelper.instance.clearHolidayCache();

      expect(
        await DatabaseHelper.instance.getHolidaysForYear(year: 2026, bundesland: 'BW'),
        isEmpty,
      );
    });
  });
}

