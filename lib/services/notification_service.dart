import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _reminderId = 1;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder({String? childName}) async {
    await cancelAll();

    final scheduledDate =
        tz.TZDateTime.now(tz.UTC).add(const Duration(days: 1));

    final body = childName != null && childName.isNotEmpty
        ? 'Hey $childName! Your robot misses you. Are you ready for a new mission?'
        : 'Your robot misses completing challenges with you! Are you ready for a new mission?';

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: '🤖 Don\'t stop learning!',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'robolearn_reminder',
          'Learning Reminders',
          channelDescription: 'Reminders to continue learning with RoboLearn',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
