/*import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print("WorkManager task executed: $taskName"); // เพิ่มการ log
    if (taskName == "countdownTask") {
      print("Countdown task is starting...");

      // แสดงแจ้งเตือนเมื่อครบเวลา
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'This channel is used for countdown notifications.',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await notificationsPlugin.show(
        0,
        "แจ้งเตือน",
        "การนับถอยหลังเสร็จสิ้น!",
        notificationDetails,
      );
    }
    return Future.value(true);
  });
}


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ตั้งค่าแจ้งเตือนครั้งแรก
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  notificationsPlugin.initialize(initializationSettings);

  // สร้าง Notification Channel สำหรับ Android 8.0 ขึ้นไป
  _createNotificationChannel();

  // ตั้งค่า WorkManager
  Workmanager().initialize(callbackDispatcher);

  runApp(const CountdownApp());
}

// สร้าง Notification Channel สำหรับ Android 8.0 ขึ้นไป
void _createNotificationChannel() {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'countdown_channel',
    'Countdown Notifications',
    channelDescription: 'This channel is used for countdown notifications.',
    importance: Importance.max,
    priority: Priority.high,
  );
  final NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  notificationsPlugin.show(
    0,
    "กำลังเริ่มการนับถอยหลัง",
    "โปรดรอ...",
    notificationDetails,
  );
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CountdownPage(),
    );
  }
}

class CountdownPage extends StatefulWidget {
  const CountdownPage({Key? key}) : super(key: key);

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  int countdown = 0; // ตัวแปรสำหรับนับเวลาถอยหลัง
  bool isCounting = false; // สถานะนับถอยหลัง

  void startCountdown() async {
    setState(() {
      countdown = 5; // ตั้งค่าเริ่มต้นถอยหลัง 5 วินาที
      isCounting = true; // เริ่มการนับถอยหลัง
    });

    // นับถอยหลัง 5 วินาทีบน UI
    for (int i = countdown; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        countdown = i - 1;
      });
    }

    // เมื่อนับถอยหลังเสร็จสิ้น ให้ตั้งค่า WorkManager
    if (countdown == 0) {
      print("Starting WorkManager Task"); // เพิ่มการ log เมื่อเริ่มต้นการทำงานของ WorkManager
      // ตั้งค่าให้ WorkManager ทำงานในพื้นหลังหลังจาก 5 วินาที
      Workmanager().registerOneOffTask(
        "countdownTask", // task name
        "countdownTask", // task tag
        initialDelay: const Duration(seconds: 5), // ตั้งเวลาให้เริ่มหลังจาก 5 วินาที
        inputData: <String, dynamic>{'key': 'value'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Countdown Notification"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCounting)
              Text(
                "กำลังนับถอยหลัง: $countdown วินาที",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                "กดปุ่มเพื่อเริ่มนับถอยหลัง",
                style: TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isCounting ? null : startCountdown,
              child: const Text("Run Task"),
            ),
          ],
        ),
      ),
    );
  }
}*/
