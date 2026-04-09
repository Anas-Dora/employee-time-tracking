import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkSegment', () {
    test('berechnet die Dauer korrekt und serialisiert nach DB-Format', () {
      final start = DateTime(2026, 1, 5, 9, 0);
      final end = DateTime(2026, 1, 5, 12, 15);
      final segment = WorkSegment(startTime: start, endTime: end);

      expect(segment.duration, const Duration(hours: 3, minutes: 15));
      expect(segment.toDbMap(), <String, String>{
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
      });
      expect(WorkSegment.fromMap(segment.toDbMap()).duration, segment.duration);
    });
  });

  group('DayOverview', () {
    test('orderedSegments sortiert Segmente aufsteigend', () {
      final date = DateTime(2026, 1, 5);
      final early = WorkSegment(
        startTime: DateTime(2026, 1, 5, 8, 0),
        endTime: DateTime(2026, 1, 5, 10, 0),
      );
      final late = WorkSegment(
        startTime: DateTime(2026, 1, 5, 13, 0),
        endTime: DateTime(2026, 1, 5, 17, 0),
      );

      final day = DayOverview(
        date: date,
        type: DayType.workday,
        segments: <WorkSegment>[late, early],
      );

      expect(day.orderedSegments.first.startTime, early.startTime);
      expect(day.orderedSegments.last.endTime, late.endTime);
    });

    test('effectiveStartTime und effectiveEndTime bevorzugen Segmente', () {
      final explicitStart = DateTime(2026, 1, 5, 9, 30);
      final explicitEnd = DateTime(2026, 1, 5, 16, 30);
      final firstSegment = WorkSegment(
        startTime: DateTime(2026, 1, 5, 8, 45),
        endTime: DateTime(2026, 1, 5, 11, 30),
      );
      final secondSegment = WorkSegment(
        startTime: DateTime(2026, 1, 5, 12, 0),
        endTime: DateTime(2026, 1, 5, 17, 15),
      );

      final day = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        startTime: explicitStart,
        endTime: explicitEnd,
        segments: <WorkSegment>[secondSegment, firstSegment],
      );

      expect(day.effectiveStartTime, firstSegment.startTime);
      expect(day.effectiveEndTime, secondSegment.endTime);
    });

    test('computedBreakDuration summiert nur positive Luecken zwischen Segmenten', () {
      final day = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        segments: <WorkSegment>[
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 9, 0),
            endTime: DateTime(2026, 1, 5, 11, 0),
          ),
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 11, 30),
            endTime: DateTime(2026, 1, 5, 13, 0),
          ),
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 12, 50),
            endTime: DateTime(2026, 1, 5, 15, 0),
          ),
        ],
      );

      expect(day.computedBreakDuration, const Duration(minutes: 30));
    });

    test('computedBreakDuration faellt bei einem Segment auf breakDuration zurueck', () {
      final day = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        breakDuration: const Duration(minutes: 45),
        segments: <WorkSegment>[
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 9, 0),
            endTime: DateTime(2026, 1, 5, 17, 0),
          ),
        ],
      );

      expect(day.computedBreakDuration, const Duration(minutes: 45));
    });

    test('workDuration summiert Segmentdauer fuer Arbeitstage', () {
      final day = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        segments: <WorkSegment>[
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 9, 0),
            endTime: DateTime(2026, 1, 5, 12, 0),
          ),
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 13, 0),
            endTime: DateTime(2026, 1, 5, 18, 0),
          ),
        ],
      );

      expect(day.workDuration, const Duration(hours: 8));
    });

    test('workDuration zieht explizite Pause bei einem Segment von der Segmentdauer ab', () {
      final day = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        breakDuration: const Duration(minutes: 30),
        segments: <WorkSegment>[
          WorkSegment(
            startTime: DateTime(2026, 1, 5, 9, 0),
            endTime: DateTime(2026, 1, 5, 17, 0),
          ),
        ],
      );

      expect(day.workDuration, const Duration(hours: 7, minutes: 30));
      expect(day.computedBreakDuration, const Duration(minutes: 30));
    });

    test('workDuration nutzt Start-Ende minus Pause wenn keine Segmente vorhanden sind', () {
      final day = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        startTime: DateTime(2026, 1, 5, 9, 0),
        endTime: DateTime(2026, 1, 5, 17, 30),
        breakDuration: const Duration(minutes: 30),
      );

      expect(day.workDuration, const Duration(hours: 8));
    });

    test('workDuration ist null fuer Feiertag und Nicht-Arbeitstag', () {
      final holiday = DayOverview(
        date: DateTime(2026, 1, 6),
        type: DayType.workday,
        isHoliday: true,
      );
      final sickDay = DayOverview(
        date: DateTime(2026, 1, 7),
        type: DayType.sick,
      );

      expect(holiday.workDuration, isNull);
      expect(sickDay.workDuration, isNull);
    });

    test('toMap und fromMap erhalten die relevanten Felder', () {
      final original = DayOverview(
        date: DateTime(2026, 1, 5),
        type: DayType.workday,
        startTime: DateTime(2026, 1, 5, 9, 0),
        endTime: DateTime(2026, 1, 5, 17, 0),
        breakDuration: const Duration(minutes: 30),
      );

      final map = original.toMap();
      final restored = DayOverview.fromMap(map);

      expect(restored.date, original.date);
      expect(restored.type, original.type);
      expect(restored.startTime, original.startTime);
      expect(restored.endTime, original.endTime);
      expect(restored.breakDuration, const Duration(minutes: 30));
    });
  });
}

