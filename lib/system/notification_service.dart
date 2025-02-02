import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ฟังก์ชันขอสิทธิ์
  static Future<void> requestPermissions() async {
    // ขอสิทธิ์แจ้งเตือน
    final notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted) {
      print("Notification permission not granted.");
      return;
    }

    // ขอสิทธิ์ตำแหน่ง
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      print("Location permission not granted.");
      return;
    }
  }

  // ฟังก์ชัน initialize
  static Future<void> initialize() async {
    await requestPermissions(); // เรียกใช้การขอสิทธิ์

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  

  // ฟังก์ชัน scheduleNotification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'task_channel', // Channel ID
      'Task Notifications', // ชื่อ Channel
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exact, // ใช้โหมด Exact
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
