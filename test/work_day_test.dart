import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/monthlyOverview/work_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkDay', () {
    test('toMap serialisiert Zeiten, Typ und Pause korrekt', () {
      final workDay = WorkDay(
        date: DateTime(2026, 2, 10),
        start: '08:30',
        end: '17:15',
        pause: '45',
        type: DayType.workday,
      );

      final map = workDay.toMap();

      expect(map['date'], DateTime(2026, 2, 10).toIso8601String());
      expect(map['type'], 'workday');
      expect(map['start_time'], DateTime(2026, 2, 10, 8, 30).toIso8601String());
      expect(map['end_time'], DateTime(2026, 2, 10, 17, 15).toIso8601String());
      expect(map['break_minutes'], 45);
    });

    test('fromMap parst DB-Werte in Anzeigeformat zurueck', () {
      final restored = WorkDay.fromMap(<String, dynamic>{
        'date': DateTime(2026, 2, 10).toIso8601String(),
        'type': 'workday',
        'start_time': DateTime(2026, 2, 10, 8, 30).toIso8601String(),
        'end_time': DateTime(2026, 2, 10, 17, 15).toIso8601String(),
        'break_minutes': 45,
        'is_holiday': 1,
      });

      expect(restored.date, DateTime(2026, 2, 10));
      expect(restored.type, DayType.workday);
      expect(restored.start, '08:30');
      expect(restored.end, '17:15');
      expect(restored.pause, '45');
      expect(restored.isHoliday, isTrue);
    });

    test('copyWith ueberschreibt nur angegebene Felder', () {
      final original = WorkDay(
        date: DateTime(2026, 2, 10),
        start: '09:00',
        end: '17:00',
        pause: '30',
        total: '07:30',
        diff: '-00:30',
        type: DayType.workday,
      );

      final updated = original.copyWith(diff: '+00:15', type: DayType.vacation);

      expect(updated.date, original.date);
      expect(updated.start, original.start);
      expect(updated.diff, '+00:15');
      expect(updated.type, DayType.vacation);
    });

    test('toMap behandelt fehlende Zeiten robust', () {
      final empty = WorkDay(
        date: DateTime(2026, 2, 10),
        type: DayType.none,
      );

      final map = empty.toMap();

      expect(map['start_time'], isNull);
      expect(map['end_time'], isNull);
      expect(map['break_minutes'], 0);
    });
  });
}

