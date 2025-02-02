/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/system/notification_service.dart';

class TaskManager {
  static Future<void> loadTasksAndScheduleNotifications() async {
  try {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    for (var doc in taskSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('time') && data['time'] is String) {
        DateTime? taskTime = _parseDateTime(data['time']);
        if (taskTime != null && taskTime.isAfter(DateTime.now())) {
          DateTime notificationTime = taskTime.subtract(const Duration(minutes: 30)); // แจ้งเตือนล่วงหน้า
          print("Scheduling notification for task: ${data['task']} at: $notificationTime");  // เพิ่มการดีบักที่นี่
          await NotificationService.scheduleNotification(
            id: doc.id.hashCode,
            title: 'กิจกรรมที่ต้องทำ',
            body: 'ถึงเวลากิจกรรม: ${data['task']}',
            scheduledTime: notificationTime,
          );
        }
      }
    }
  } catch (e) {
    print("Error loading tasks or scheduling notifications: $e");
  }
}

  static DateTime? _parseDateTime(String dateTimeStr) {
  try {
    print("Parsing time: $dateTimeStr"); // ตรวจสอบค่าที่ได้
    return DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);
  } catch (e) {
    print("Error parsing date time: $e");
    return null;
  }
}
}*/