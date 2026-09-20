import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Schedules the OS-level notification that fires when a Cook Mode timer
/// completes. This is deliberately separate from the in-screen countdown
/// (a plain dart:async Timer) — the notification is the source of truth
/// for "did the timer finish," independent of whether Cook Mode is still
/// on screen or the app process is even alive, so it is only cancelled by
/// an explicit user action, never by the screen being disposed.
class TimerNotificationService {
  TimerNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Sets up notification channels/handlers. Call once from main(),
  /// before runApp. Does NOT prompt for permission — that happens
  /// contextually the first time the user starts a timer.
  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  /// Requests notification permission. Call this the first time the user
  /// starts a timer, not at app launch.
  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a notification to fire after [remaining]. [stepLabel] is
  /// shown in the notification body (e.g. "Step 3: Simmer sauce").
  static Future<void> scheduleTimerComplete({
    required int id,
    required String stepLabel,
    required Duration remaining,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cook_mode_timer',
      'Cook Mode Timer',
      channelDescription: 'Alerts when a Cook Mode timer finishes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: 'Timer done!',
      body: stepLabel,
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(remaining),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('TimerNotificationService.cancel failed: $e');
    }
  }
}
