import 'package:employee_time_tracking/dayOverview/day_overview.dart';
import 'package:employee_time_tracking/dayOverview/week_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeekOverview', () {
    test('totalWork summiert nur vorhandene Arbeitsdauer', () {
      final week = WeekOverview(
        startDate: DateTime(2026, 3, 2),
        endDate: DateTime(2026, 3, 6),
        days: <DayOverview>[
          DayOverview(
            date: DateTime(2026, 3, 2),
            type: DayType.workday,
            startTime: DateTime(2026, 3, 2, 9, 0),
            endTime: DateTime(2026, 3, 2, 17, 0),
          ),
          DayOverview(
            date: DateTime(2026, 3, 3),
            type: DayType.sick,
          ),
          DayOverview(
            date: DateTime(2026, 3, 4),
            type: DayType.workday,
            segments: <WorkSegment>[
              WorkSegment(
                startTime: DateTime(2026, 3, 4, 8, 0),
                endTime: DateTime(2026, 3, 4, 12, 0),
              ),
              WorkSegment(
                startTime: DateTime(2026, 3, 4, 13, 0),
                endTime: DateTime(2026, 3, 4, 17, 0),
              ),
            ],
          ),
        ],
      );

      expect(week.totalWork, const Duration(hours: 16));
    });

    test('averageBreak bildet den Durchschnitt der Arbeitstage', () {
      final week = WeekOverview(
        startDate: DateTime(2026, 3, 2),
        endDate: DateTime(2026, 3, 6),
        days: <DayOverview>[
          DayOverview(
            date: DateTime(2026, 3, 2),
            type: DayType.workday,
            segments: <WorkSegment>[
              WorkSegment(
                startTime: DateTime(2026, 3, 2, 8, 0),
                endTime: DateTime(2026, 3, 2, 12, 0),
              ),
              WorkSegment(
                startTime: DateTime(2026, 3, 2, 12, 30),
                endTime: DateTime(2026, 3, 2, 16, 0),
              ),
            ],
          ),
          DayOverview(
            date: DateTime(2026, 3, 3),
            type: DayType.workday,
            breakDuration: const Duration(minutes: 45),
          ),
          DayOverview(
            date: DateTime(2026, 3, 4),
            type: DayType.vacation,
          ),
        ],
      );

      expect(week.averageBreak, const Duration(minutes: 37));
    });

    test('averageBreak ist nullfrei und bei keinen Arbeitstagen gleich null', () {
      final week = WeekOverview(
        startDate: DateTime(2026, 3, 2),
        endDate: DateTime(2026, 3, 6),
        days: <DayOverview>[
          DayOverview(date: DateTime(2026, 3, 2), type: DayType.none),
          DayOverview(date: DateTime(2026, 3, 3), type: DayType.vacation),
        ],
      );

      expect(week.averageBreak, Duration.zero);
    });
  });
}

