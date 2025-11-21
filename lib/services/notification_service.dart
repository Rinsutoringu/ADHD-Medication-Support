import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // 请求权限
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedulePeakNotification(
    String medicationName,
    Duration delay,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'peak_alert',
        '峰值提醒',
        channelDescription: '药物浓度达到峰值时的提醒',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
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

      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

      await _notifications.zonedSchedule(
        1, // 峰值通知ID
        '🎯 药效峰值到达',
        '$medicationName 已达到血药浓度峰值，注意力最佳时刻！',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('定时通知在当前平台不支持: $e');
    }
  }

  Future<void> showPeakAlert(
    String medicationName,
    double concentration,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'peak_alert',
        '峰值提醒',
        channelDescription: '药物浓度达到峰值时的提醒',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
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

      await _notifications.show(
        1,
        '🎯 峰值已到达',
        '$medicationName 当前血药浓度：${concentration.toStringAsFixed(2)} mg/L',
        details,
      );
    } catch (e) {
      debugPrint('显示通知失败（当前平台可能不支持）: $e');
    }
  }

  Future<void> showSleepReminder(DateTime suggestedTime) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'sleep_reminder',
        '睡眠提醒',
        channelDescription: '药效结束后的睡眠建议',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
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

      final timeStr =
          '${suggestedTime.hour.toString().padLeft(2, '0')}:'
          '${suggestedTime.minute.toString().padLeft(2, '0')}';

      await _notifications.show(
        2,
        '😴 药效已结束',
        '建议睡眠时间：$timeStr，让大脑好好休息吧！',
        details,
      );
    } catch (e) {
      debugPrint('显示睡眠提醒失败（当前平台可能不支持）: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
