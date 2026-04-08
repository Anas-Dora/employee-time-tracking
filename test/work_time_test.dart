import 'package:employee_time_tracking/homePage/work_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkTime', () {
    test('formatted liefert immer HH:mm:ss', () {
      final workTime = WorkTime(hours: 3, minutes: 4, seconds: 5);

      expect(workTime.formatted, '03:04:05');
    });

    test('copyWith ersetzt nur gesetzte Felder', () {
      final original = WorkTime(hours: 1, minutes: 2, seconds: 3);
      final updated = original.copyWith(minutes: 45);

      expect(updated.hours, 1);
      expect(updated.minutes, 45);
      expect(updated.seconds, 3);
    });
  });
}

