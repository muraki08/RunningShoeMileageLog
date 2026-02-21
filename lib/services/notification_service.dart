import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'notif_enabled';
  static const String _hourKey = 'notif_hour';
  static const String _minuteKey = 'notif_minute';
  static const int _notificationId = 0;

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // 保存済み設定があればスケジュールを復元
    final enabled = await isEnabled();
    if (enabled) {
      final hour = await getHour();
      final minute = await getMinute();
      await scheduleDailyReminder(hour, minute);
    }
  }

  static Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'リマインド通知',
      channelDescription: '走行記録のリマインド通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _notificationId,
      'ランニングシューズ記録',
      '今日の走行記録をつけましょう！',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancel(_notificationId);
  }

  // 設定の保存・読み込み
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<int> getHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hourKey) ?? 21;
  }

  static Future<int> getMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minuteKey) ?? 0;
  }

  static Future<void> saveSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);

    if (enabled) {
      await scheduleDailyReminder(hour, minute);
    } else {
      await cancelReminder();
    }
  }
}
