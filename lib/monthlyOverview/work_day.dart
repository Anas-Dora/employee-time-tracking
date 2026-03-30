class WorkDay {
  final DateTime date;
  final String start;
  final String end;
  final String pause;
  final String total;
  final String diff;

  WorkDay({
    required this.date,
    this.start = '-',
    this.end = '-',
    this.pause = '-',
    this.total = '-',
    this.diff = '-',
  });
}