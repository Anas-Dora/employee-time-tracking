
enum DayType { workday, sick, vacation, none }

class WorkSegment {
  final DateTime startTime;
  final DateTime endTime;

  WorkSegment({required this.startTime, required this.endTime});

  Duration get duration => endTime.difference(startTime);

  Map<String, String> toDbMap() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }

  factory WorkSegment.fromMap(Map<String, dynamic> map) {
    return WorkSegment(
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
    );
  }
}

class DayOverview {
  final DateTime date;
  final DayType type;
  final bool isHoliday;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? breakDuration;
  final List<WorkSegment> segments;

  DayOverview({
    required this.date,
    required this.type,
    this.isHoliday = false,
    this.startTime,
    this.endTime,
    this.breakDuration,
    this.segments = const [],
  });

  DayOverview copyWith({
    DateTime? date,
    DayType? type,
    bool? isHoliday,
    DateTime? startTime,
    DateTime? endTime,
    Duration? breakDuration,
    List<WorkSegment>? segments,
    bool clearSegments = false,
  }) {
    return DayOverview(
      date: date ?? this.date,
      type: type ?? this.type,
      isHoliday: isHoliday ?? this.isHoliday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakDuration: breakDuration ?? this.breakDuration,
      segments: clearSegments ? const [] : (segments ?? this.segments),
    );
  }

  List<WorkSegment> get orderedSegments {
    if (segments.isEmpty) return const [];
    final copy = List<WorkSegment>.from(segments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return copy;
  }

  DateTime? get effectiveStartTime {
    if (orderedSegments.isNotEmpty) return orderedSegments.first.startTime;
    return startTime;
  }

  DateTime? get effectiveEndTime {
    if (orderedSegments.isNotEmpty) return orderedSegments.last.endTime;
    return endTime;
  }

  Duration get computedBreakDuration {
    final ordered = orderedSegments;
    if (ordered.length <= 1) {
      return breakDuration ?? Duration.zero;
    }

    Duration total = Duration.zero;
    for (int i = 1; i < ordered.length; i++) {
      final gap = ordered[i].startTime.difference(ordered[i - 1].endTime);
      if (!gap.isNegative) {
        total += gap;
      }
    }
    final explicitBreak = breakDuration ?? Duration.zero;
    return explicitBreak > total ? explicitBreak : total;
  }

  Duration? get workDuration {
    if (isHoliday) return null;
    if (type != DayType.workday) return null;

    if (orderedSegments.isNotEmpty) {
      final segmentDuration = orderedSegments.fold<Duration>(
        Duration.zero,
        (sum, segment) => sum + segment.duration,
      );

      Duration gapBreak = Duration.zero;
      for (int i = 1; i < orderedSegments.length; i++) {
        final gap = orderedSegments[i].startTime
            .difference(orderedSegments[i - 1].endTime);
        if (!gap.isNegative) {
          gapBreak += gap;
        }
      }
      final explicitBreak = breakDuration ?? Duration.zero;
      final additionalBreak = explicitBreak - gapBreak;
      if (additionalBreak <= Duration.zero) {
        return segmentDuration;
      }

      final net = segmentDuration - additionalBreak;
      return net.isNegative ? Duration.zero : net;
    }

    if (startTime == null || endTime == null) return null;

    final pause = breakDuration ?? Duration.zero;
    return endTime!.difference(startTime!) - pause;
  }

  /// Konvertierung für SQLite
  Map<String, dynamic> toMap() {
    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'type': type.name,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'break_minutes': breakDuration?.inMinutes ?? 0,
    };
  }

  factory DayOverview.fromMap(Map<String, dynamic> map) {
    return DayOverview(
      date: DateTime.parse(map['date'] as String),
      type: DayType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => DayType.none,
      ),
      isHoliday: (map['is_holiday'] as int?) == 1,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      breakDuration: map['break_minutes'] != null
          ? Duration(minutes: map['break_minutes'] as int)
          : null,
    );
  }
}