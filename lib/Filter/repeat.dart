import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Repeat extends StatefulWidget {
  const Repeat({super.key});

  @override
  State<Repeat> createState() => _RepeatState();
}

class _RepeatState extends State<Repeat> {
  String _selectedRepeat = ''; // ตัวแปรเก็บจำนวนวันที่เลือก
  List<Map<String, dynamic>> _tasks = []; // รายการกิจกรรมจาก Firestore
  List<Map<String, dynamic>> _importantTasks = []; // รายการกิจกรรมสำคัญจาก Firestore

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  // ดึงข้อมูลจาก Firestore
  Future<void> _fetchTasks() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    // ดึงข้อมูลจาก Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('time', descending: false) // เรียงข้อมูลจากเก่าสุดไปใหม่สุด
        .get();

    // ดึงข้อมูลจากคอลเล็กชัน important
    final importantSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('important')
        .orderBy('time', descending: false)
        .get();

    setState(() {
      // รวมข้อมูลจาก tasks และ important
      _tasks = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _importantTasks = importantSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // ฟังก์ชั่นในการกรองข้อมูลตามการทำซ้ำ
  List<Map<String, dynamic>> _getFilteredTasks() {
    List<Map<String, dynamic>> allTasks = []..addAll(_tasks)..addAll(_importantTasks);

    if (_selectedRepeat.isEmpty) {
      return allTasks;
    }

    // กรองตามค่าของ repeat
    return allTasks.where((task) {
      return task['repeat'] != null &&
          task['repeat'].toString().trim() == _selectedRepeat.trim();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0), // AppBar สีดำ
        title: const Text(
          'กิจกรรมทำซ้ำ',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ปุ่ม 4 ปุ่มในแนวนอน
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRepeat = '1 วัน';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // สีปุ่ม
                  ),
                  child: const Text(
                    '1 วัน',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRepeat = '7 วัน';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // สีปุ่ม
                  ),
                  child: const Text(
                    '7 วัน',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRepeat = '30 วัน';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // สีปุ่ม
                  ),
                  child: const Text(
                    '30 วัน',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRepeat = '365 วัน';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // สีปุ่ม
                  ),
                  child: const Text(
                    '365 วัน',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(), // เส้นคั่น
          Expanded(
            child: _selectedRepeat.isEmpty
                ? const Center(
                    child: Text(
                      'กรุณาเลือกรูปแบบการทำซ้ำ',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _getFilteredTasks().length,
                    itemBuilder: (context, index) {
                      final task = _getFilteredTasks()[index];
                      final String taskName = task['task'] ?? 'Unnamed';
                      final String time = task['time'] ?? 'No time';
                      final String repeat = task['repeat'] ?? 'No repeat';
                      final bool isImportant = _importantTasks.contains(task); // ตรวจสอบว่าเป็นข้อมูลจาก important หรือไม่

                      return Container(
                        decoration: BoxDecoration(
                          color: isImportant ? Colors.orange : Colors.black, // กำหนดสีพื้นหลังตามประเภท
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(
                            taskName,
                            style: TextStyle(
                              color: isImportant ? Colors.black : Colors.white, // กำหนดสีตัวอักษรตามประเภท
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'วันที่และเวลา : $time\nทำซ้ำ: $repeat',
                            style: TextStyle(
                              color: isImportant ? Colors.black87 : Colors.white70, // กำหนดสีตัวอักษรตามประเภท
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

