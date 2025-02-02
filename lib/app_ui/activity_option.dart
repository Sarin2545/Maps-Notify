import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_db4/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityOptionScreen extends StatelessWidget {
  const ActivityOptionScreen({super.key});

  static Future<void> fetchAllTasksAndNotify() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user signed in');
      return;
    }

    final userID = user.uid;

    // ดึงข้อมูลจาก Firestore
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('tasks')
        .get();

    print('Total tasks fetched: ${querySnapshot.docs.length}');

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final task = data['task'];
      final timeString = data['time'];
      final notificationOption = data['notification']; // ดึงตัวเลือกการแจ้งเตือนล่วงหน้า

      if (task != null && timeString != null && notificationOption != null) {
        final DateTime taskTime = DateTime.parse(timeString); // แปลงเวลาเป็น DateTime
        
        // ตรวจสอบว่าเวลา taskTime เป็นในอนาคตเท่านั้น
        final now = DateTime.now();
        if (taskTime.isBefore(now)) {
          print('Task "$task" is in the past. Skipping notification.');
          continue; // ข้ามการแจ้งเตือนถ้าเวลาเป็นอดีต
        }

        // คำนวณเวลาของการแจ้งเตือนจากการลบเวลาล่วงหน้าที่ผู้ใช้เลือก
        int notificationMinutes = 0;
        if (notificationOption == '15 นาที') {
          notificationMinutes = 15;
        } else if (notificationOption == '30 นาที') {
          notificationMinutes = 30;
        } else if (notificationOption == '45 นาที') {
          notificationMinutes = 45;
        } else if (notificationOption == '60 นาที') {
          notificationMinutes = 60;
        }

        // ลดเวลาล่วงหน้าจากเวลาของกิจกรรม
        final notificationTime = taskTime.subtract(Duration(minutes: notificationMinutes));

        final duration = notificationTime.isBefore(now)
            ? notificationTime.add(Duration(days: 1)).difference(now) // ถ้าเวลาแจ้งเตือนผ่านมาแล้ว ให้เพิ่มวัน
            : notificationTime.difference(now);

        // ใช้ ID ของเอกสาร Firestore เพื่อเป็น Unique Notification ID
        final uniqueId = doc.id.hashCode;

        print('Scheduling notification for task "$task" in $duration');

        // ยกเลิกการแจ้งเตือนเก่าที่ใช้ ID เดียวกัน
        await flutterLocalNotificationsPlugin.cancel(uniqueId);

        // ตั้งการแจ้งเตือนใหม่
        Future(() async {
          await Future.delayed(duration); // รอจนถึงเวลาแจ้งเตือน
          await _showLocalNotification(task, timeString, uniqueId); // เรียกฟังก์ชันเพื่อแสดงการแจ้งเตือน
        });
      }
    }
  } catch (e) {
    print('Error fetching tasks: $e');
  }
}

  static Future<void> _showLocalNotification(String task, String time, int notificationId) async {
    print('Showing notification for task "$task" at $time with ID $notificationId');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      task,
      'วันที่และเวลา : $time',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
    appBar: AppBar(
      backgroundColor: Colors.black, // AppBar สีดำ
      title: const Text(
        'แจ้งเตือนกิจกรรม',
        style: TextStyle(color: Colors.white), // ตัวอักษรสีขาว
      ),
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)), // ไอคอนสีขาว
    ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }

}