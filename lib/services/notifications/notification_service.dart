import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Singleton wrapper around flutter_local_notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _initialized = true;
    log('NotificationService: initialized');
  }

  Future<void> showWeatherAlert({
    required String title,
    required String body,
    int id = 1001,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'weather_alerts',
      'Weather Alerts',
      channelDescription: 'Bahaar marine weather warnings',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
    log('NotificationService: showed alert "$title"');
  }

  Future<void> showTideAlert({required String body}) async {
    await showWeatherAlert(
      title: 'Tide Alert',
      body: body,
      id: 1002,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
