enum MonthlyNotificationType { missingEntry, incompleteEntry, overtimeGoal, negativeOvertime, none }

class MonthlyNotification {
  final MonthlyNotificationType type;
  final String message;

  const MonthlyNotification({
    required this.type,
    required this.message,
  });
}
