import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/app_ui/all_data.dart';
import 'package:test_db4/app_ui/today_data.dart';
import 'package:test_db4/app_ui/finish_data.dart';
import 'package:test_db4/app_ui/important_data.dart';
import 'package:test_db4/app_ui/category_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:test_db4/system/filter_list.dart';
import 'package:test_db4/system/notification_service.dart'; 
import 'package:test_db4/system/activity.dart';
import 'package:test_db4/app_ui/category_ui.dart';

import '../system/map.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("Notification permission granted.");
    } else if (status.isDenied) {
      print("Notification permission denied.");
    } else if (status.isPermanentlyDenied) {
      print("Notification permission permanently denied.");
      await openAppSettings();
    }

    await NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // การ์ด: ทั้งหมด
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllDataPage()),
                    );
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('tasks')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int taskCount = 0;
                      if (snapshot.hasData) {
                        taskCount = snapshot.data!.size;
                      }
                      return _buildTaskCard(
                          'ทั้งหมด', Icons.list, taskCount, Colors.white);
                    },
                  ),
                ),

                // การ์ด: วันนี้
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TodayDataScreen()),
                    );
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('tasks')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int todayTaskCount = 0;
                      if (snapshot.hasData) {
                        final String today =
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                        todayTaskCount = snapshot.data!.docs.where((doc) {
                          final taskData = doc.data() as Map<String, dynamic>;
                          final taskDate = taskData['time'] ?? '';
                          return taskDate.startsWith(today);
                        }).length;
                      }
                      return _buildTaskCard('วันนี้', Icons.wb_sunny,
                          todayTaskCount, Colors.white);
                    },
                  ),
                ),

                // การ์ด: เสร็จแล้ว
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FinishDataScreen()),
                    );
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('finish_tasks')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int finishTaskCount = 0;
                      if (snapshot.hasData) {
                        finishTaskCount = snapshot.data!.size;
                      }
                      return _buildTaskCard('เสร็จแล้ว', Icons.check_circle,
                          finishTaskCount, Colors.white);
                    },
                  ),
                ),

                // การ์ด: ปักหมุด
// การ์ด: ปักหมุด
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ImportantDataScreen()),
                    );
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection(
                            'important') // ดึงข้อมูลจาก collection 'important'
                        .snapshots(),
                    builder: (context, snapshot) {
                      int importantCount = 0;
                      if (snapshot.hasData) {
                        importantCount = snapshot.data!.size;
                      }

                      // ส่งสีส้มเป็นพารามิเตอร์
                      return _buildTaskCard('ปักหมุด', Icons.push_pin,
                          importantCount, Colors.orange);
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'หมวดหมู่ของฉัน',
              style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('category')
                  .snapshots(),
              builder: (context, snapshot) {
                int categoryCount = 0;
                if (snapshot.hasData) {
                  categoryCount = snapshot.data!.size;
                }

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CategoryDataScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.note, color: Colors.white),
                                SizedBox(width: 15),
                                Text(
                                  'หมวดหมู่',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ],
                            ),
                            Text(
                              '$categoryCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15), // ระยะห่างระหว่างการ์ด
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MapsPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.location_on,
                                    color:
                                        Colors.white), // เปลี่ยนไอคอนให้แตกต่าง
                                SizedBox(width: 15),
                                Text(
                                  'แจ้งเตือนโดยแผนที่', // เปลี่ยนข้อความให้แตกต่าง
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15), // ระยะห่างระหว่างการ์ด
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FilterList()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.filter_list,
                                    color:
                                        Colors.white), // เปลี่ยนไอคอนให้แตกต่าง
                                SizedBox(width: 15),
                                Text(
                                  'คัดกรองกิจกรรม', // เปลี่ยนข้อความให้แตกต่าง
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 31.0, bottom: 16.0),
              child: FloatingActionButton.extended(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyFormPage()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('เพิ่มกิจกรรม',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight, // ตำแหน่งของปุ่มที่สอง
            child: Padding(
              padding: const EdgeInsets.only(right: 0, bottom: 16.0),
              child: FloatingActionButton.extended(
                backgroundColor:
                    const Color.fromARGB(255, 0, 0, 0), // สีพื้นหลังของปุ่มใหม่
                onPressed: () {
                  // ฟังก์ชันการทำงานของปุ่มใหม่
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const IconColorPickerScreen()),
                  );
                },
                icon: const Icon(Icons.add,
                    color: Colors.white), // ตัวไอคอนของปุ่มใหม่
                label: const Text('สร้างหมวดหมู่',
                    style: TextStyle(color: Colors.white)), // ข้อความหลังไอคอน
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างการ์ด
  Widget _buildTaskCard(
      String title, IconData icon, int count, Color iconColor) {
    return Card(
      color: Colors.black, // สีพื้นหลังของการ์ดเป็นสีดำ
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 40, color: iconColor), // ใช้สีที่ส่งเข้ามาสำหรับไอคอน
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 10,
            child: Text(
              '$count',
              style: TextStyle(
                  color: iconColor,
                  fontSize: 20), // ใช้สีที่ส่งเข้ามาสำหรับจำนวน
            ),
          ),
        ],
      ),
    );
  }
}
