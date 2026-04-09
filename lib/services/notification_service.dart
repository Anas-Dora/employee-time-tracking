import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  // Benachrichtigungs-IDs
  static const int _idBreak30 = 1001;
  static const int _idBreak45 = 1002;
  static const int _idExceeded8h = 1003;
  static const int _idExceeded10h = 1004;
  static const int _idBreak29 = 1005;

  // IDs fuer geplante Benachrichtigungen (funktionieren auch bei geschlossener App)
  static const int _scheduledBreak30 = 2001;
  static const int _scheduledBreak45 = 2002;
  static const int _scheduledExceeded8h = 2003;
  static const int _scheduledExceeded10h = 2004;

  // Globaler Schalter – wird vom Profil-Setting gesteuert
  bool enabled = false;
  bool _isInitialized = false;
  bool _timeZonesInitialized = false;
  Future<void>? _initializationFuture;

  // Flags: welche Benachrichtigungen wurden heute bereits ausgelöst?
  bool _break30Sent = false;
  bool _break45Sent = false;
  bool _exceeded8hSent = false;
  bool _exceeded10hSent = false;
  bool _break29Sent = false;


  Future<void> init() async {
    if (_isInitialized) return;
    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }

    _initializationFuture = _initInternal();
    try {
      await _initializationFuture;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initInternal() async {
    if (!_timeZonesInitialized) {
      tz.initializeTimeZones();
      _timeZonesInitialized = true;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await plugin.initialize(
      settings: initSettings,
      // Callback wenn Benachrichtigung im Vordergrund angezeigt wird
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      // Callback für Background-Notifications
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    _isInitialized = true;
  }

  Future<bool> initAndRequestPermission() async {
    await init();

    final androidGranted = await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final macOsGranted = await plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return androidGranted ?? iosGranted ?? macOsGranted ?? true;
  }

  Future<void> disableReminders() async {
    enabled = false;
    if (!_isInitialized) return;
    await _cancelScheduledThresholds();
  }

  /// Callback für Benachrichtigungen im Vordergrund
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      markNotificationSent(int.tryParse(response.payload ?? '') ?? 0);
    }
  }

  /// Callback für Benachrichtigungen im Hintergrund
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      NotificationService.instance.markNotificationSent(int.tryParse(response.payload ?? '') ?? 0);
    }
  }



  /// Muss beim Start eines neuen Arbeitstages aufgerufen werden,
  /// damit die Flags zurückgesetzt werden.
  void resetDailyFlags() {
    _break30Sent = false;
    _break45Sent = false;
    _exceeded8hSent = false;
    _exceeded10hSent = false;
    _break29Sent = false;
  }

  /// Markiere eine Benachrichtigung als gesendet (für Background-Callbacks)
  void markNotificationSent(int notificationId) {
    if (notificationId == _scheduledBreak30 || notificationId == _idBreak30) {
      _break30Sent = true;
    } else if (notificationId == _scheduledBreak45 || notificationId == _idBreak45) {
      _break45Sent = true;
    } else if (notificationId == _scheduledExceeded8h || notificationId == _idExceeded8h) {
      _exceeded8hSent = true;
    } else if (notificationId == _scheduledExceeded10h || notificationId == _idExceeded10h) {
      _exceeded10hSent = true;
    } else if (notificationId == _idBreak29) {
      _break29Sent = true;
    }
  }

  /// Wird jede Sekunde aus dem ViewModel aufgerufen.
  /// [workSeconds]  – bisherige Netto-Arbeitszeit in Sekunden
  /// [breakSeconds] – bisherige Gesamtpausenzeit in Sekunden
  Future<void> checkAndNotify({
    required int workSeconds,
    required int breakSeconds,
  }) async {
    if (!enabled || !_isInitialized) return;

    final workMinutes = workSeconds ~/ 60;
    final breakMinutes = breakSeconds ~/ 60;

    if (!_break29Sent && workMinutes >= 360 && breakSeconds >= 29 * 60 && breakSeconds < 30 * 60) {
      await _send(
        id: _idBreak29,
        title: '⏱ Fast geschafft',
        body: 'Du hast 29 Minuten Pause erreicht. Noch 1 Minute bis zur 30-Minuten-Pause.',
      );
      _break29Sent = true;
    }

    // Pausenpflicht nach 6 Stunden Arbeit (mind. 30 min Pause)
    if (!_break30Sent && workMinutes >= 360) {
      if (breakMinutes < 30) {
        await _send(
          id: _idBreak30,
          title: '⏸ Pause erforderlich',
          body: 'Du arbeitest seit über 6 Stunden. '
              'Bitte leg eine Pause von mindestens 30 Minuten ein.',
        );
        _break30Sent = true;
      }
    }

    // Pausenpflicht nach 9 Stunden Arbeit (mind. 45 min Pause)
    if (!_break45Sent && workMinutes >= 540) {
      if (breakMinutes < 45) {
        await _send(
          id: _idBreak45,
          title: '⏸ Zusätzliche Pause erforderlich',
          body: 'Du arbeitest seit über 9 Stunden. '
              'Insgesamt müssen mindestens 45 Minuten Pause eingehalten werden.',
        );
        _break45Sent = true;
      }
    }

    // Hinweis: reguläre Tageshöchstarbeitszeit (8 Stunden)
    if (!_exceeded8hSent && workMinutes >= 480) {
      await _send(
        id: _idExceeded8h,
        title: '🕗 Tageshöchstarbeitszeit erreicht',
        body: 'Du hast die reguläre tägliche Höchstarbeitszeit von '
            '8 Stunden überschritten.',
      );
      _exceeded8hSent = true;
    }

    // Warnung: gesetzliche Grenze (10 Stunden) überschritten
    if (!_exceeded10hSent && workMinutes >= 600) {
      await _send(
        id: _idExceeded10h,
        title: '⚠️ Gesetzliche Arbeitszeit überschritten!',
        body: 'Achtung: Du hast die gesetzliche Höchstarbeitszeit '
            'von 10 Stunden überschritten!',
        highPriority: true,
      );
      _exceeded10hSent = true;
    }
  }

  Future<void> syncBackgroundSchedules({
    required bool isRunning,
    required int workSeconds,
    required int breakSeconds,
  }) async {
    if (!_isInitialized) return;

    // Wenn Erinnerungen deaktiviert sind, alle geplanten Hinweise entfernen.
    if (!enabled) {
      await _cancelScheduledThresholds();
      return;
    }

    // Bei gestoppter Arbeit geplante Hinweise ebenfalls entfernen.
    if (!isRunning) {
      await _cancelScheduledThresholds();
      return;
    }

    // Berechne die Zeit, die bis zu den Schwellwerten verbleibt
    final workMinutes = workSeconds ~/ 60;
    final breakMinutes = breakSeconds ~/ 60;

    // ── Geplante Benachrichtigungen mit korrekten Verzögerungen ─────────────────
    // Diese werden gesendet, auch wenn die App im Hintergrund ist (scheduled notifications)

    // Break nach 6h (wenn noch nicht erforderlich)
    if (!_break30Sent && breakMinutes < 30 && workMinutes < 360) {
      final delaySeconds = (360 * 60) - workSeconds;
      if (delaySeconds > 0) {
        await _scheduleIn(
          id: _scheduledBreak30,
          delay: Duration(seconds: delaySeconds),
          title: '⏸ Pause erforderlich',
          body: 'Du arbeitest seit über 6 Stunden. '
              'Bitte leg eine Pause von mindestens 30 Minuten ein.',
        );
      }
    }

    // Break nach 9 Stunden (wenn noch nicht erforderlich)
    if (!_break45Sent && breakMinutes < 45 && workMinutes < 540) {
      final delaySeconds = (540 * 60) - workSeconds;
      if (delaySeconds > 0) {
        await _scheduleIn(
          id: _scheduledBreak45,
          delay: Duration(seconds: delaySeconds),
          title: '⏸ Zusätzliche Pause erforderlich',
          body: 'Du arbeitest seit über 9 Stunden. '
              'Insgesamt müssen mindestens 45 Minuten Pause eingehalten werden.',
        );
      }
    }

    // Warnung nach 8 Stunden
    if (!_exceeded8hSent && workMinutes < 480) {
      final delaySeconds = (480 * 60) - workSeconds;
      if (delaySeconds > 0) {
        await _scheduleIn(
          id: _scheduledExceeded8h,
          delay: Duration(seconds: delaySeconds),
          title: '🕗 Tageshöchstarbeitszeit erreicht',
          body: 'Du hast die reguläre tägliche Höchstarbeitszeit von '
              '8 Stunden überschritten.',
        );
      }
    }

    // Warnung nach 10 Stunden
    if (!_exceeded10hSent && workMinutes < 600) {
      final delaySeconds = (600 * 60) - workSeconds;
      if (delaySeconds > 0) {
        await _scheduleIn(
          id: _scheduledExceeded10h,
          delay: Duration(seconds: delaySeconds),
          title: '⚠️ Gesetzliche Arbeitszeit überschritten!',
          body: 'Achtung: Du hast die gesetzliche Höchstarbeitszeit '
              'von 10 Stunden überschritten!',
          highPriority: true,
        );
      }
    }
  }

  Future<void> _send({
    required int id,
    required String title,
    required String body,
    bool highPriority = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'work_time_channel',
      'Arbeitszeitbenachrichtigungen',
      channelDescription:
          'Hinweise und Warnungen zur gesetzlichen Arbeitszeit',
      importance: highPriority ? Importance.max : Importance.high,
      priority: highPriority ? Priority.high : Priority.defaultPriority,
      ticker: title,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    await plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _scheduleIn({
    required int id,
    required Duration delay,
    required String title,
    required String body,
    bool highPriority = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'work_time_channel',
      'Arbeitszeitbenachrichtigungen',
      channelDescription:
          'Hinweise und Warnungen zur gesetzlichen Arbeitszeit',
      importance: highPriority ? Importance.max : Importance.high,
      priority: highPriority ? Priority.high : Priority.defaultPriority,
      ticker: title,
      tag: 'work_time_$id',
      groupKey: 'work_time_notifications',
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final scheduledAt = tz.TZDateTime.now(tz.local).add(delay);
    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: id.toString(), // Payload mit ID für den Callback
    );
  }

  Future<void> _cancelScheduledThresholds() async {
    await plugin.cancel(id: _scheduledBreak30);
    await plugin.cancel(id: _scheduledBreak45);
    await plugin.cancel(id: _scheduledExceeded8h);
    await plugin.cancel(id: _scheduledExceeded10h);
  }
}
