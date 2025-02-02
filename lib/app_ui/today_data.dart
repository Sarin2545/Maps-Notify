import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test_db4/system/edit_activity.dart';

class TodayDataScreen extends StatelessWidget {
  const TodayDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: Colors.black, // AppBar สีดำ
        title: const Text(
          'กิจกรรมวันนี้',
          style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold,),
        ),
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .orderBy('timestamp', descending: false) // เรียงจากเก่าสุดไปใหม่สุด
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีข้อมูลกิจกรรมสำหรับวันนี้',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final tasks = snapshot.data!.docs.where((doc) {
            final taskData = doc.data() as Map<String, dynamic>;
            final taskDate = taskData['time'] ?? '';
            return taskDate.startsWith(today);
          }).toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีข้อมูลกิจกรรมสำหรับวันนี้',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskDoc = tasks[index];
              final task = taskDoc.data() as Map<String, dynamic>;
              final String taskId = taskDoc.id;
              final String taskName = task['task'] ?? 'Unnamed';
              final String time = task['time'] ?? 'No time';
              final String notification =
                  task['notification'] ?? 'No notification';
              final String repeat = task['repeat'] ?? 'no repeat';
              final String priority = task['priority'] ?? 'no priority';

              return ListTile(
                title: Text(
                  taskName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    'ทำซ้ำ : $repeat\nวันที่และเวลา : \n($time)\nล่วงหน้า : $notification\nสำคัญ : $priority'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ปุ่มเช็คถูก -> ย้ายไป finish_tasks
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () =>
                          _moveToFinishData(context, userId, taskId, task),
                    ),
                    // ปุ่มกากบาท -> ลบงาน
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.white, // พื้นหลังสีขาว
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12.0), // มุมโค้งมนของ Dialog
                              ),
                              title: const Text(
                                'ยืนยันการลบ',
                                style: TextStyle(
                                  color: Colors.black, // สีข้อความหัวข้อ
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'คุณต้องการลบกิจกรรมนี้หรือไม่?',
                                style: TextStyle(
                                  color: Colors.black87, // สีข้อความเนื้อหา
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // ปิด AlertDialog
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Colors.black, // สีข้อความปุ่ม
                                  ),
                                  child: const Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // ปิด AlertDialog
                                    _deleteTask(context, userId,
                                        taskId); // เรียกฟังก์ชันลบกิจกรรม
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.black, // สีพื้นหลังปุ่ม
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8.0), // มุมโค้งมนของปุ่ม
                                    ),
                                  ),
                                  child: const Text(
                                    'ตกลง',
                                    style: TextStyle(
                                      color: Colors.white,
                fontWeight: FontWeight.bold, // สีข้อความปุ่ม
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.push_pin, color: Colors.orange),
                      onPressed: () =>
                          _moveToImportant(context, userId, taskId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings,
                          color: Color.fromARGB(255, 52, 49, 47)),
                      onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditActivity(
                                  taskId: taskId,                                  
                                ),
                              ),
                            );
                          },
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
    );
  }

  Future<void> _moveToImportant(
      BuildContext context, String userId, String taskId) async {
    try {
      var taskSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .get();

      if (taskSnapshot.exists) {
        final taskData = taskSnapshot.data();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('important')
            .doc(taskId)
            .set(taskData!);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(taskId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ปักหมุดกิจกรรมเรียบร้อยแล้ว!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  // ฟังก์ชันย้ายข้อมูลไปยัง 'finish_tasks' และลบออกจาก 'tasks'
  Future<void> _moveToFinishData(BuildContext context, String userId,
      String taskId, Map<String, dynamic> task) async {
    try {
      // ย้ายไป finish_tasks
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('finish_tasks')
          .doc(taskId)
          .set(task);

      // ลบออกจาก tasks
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ย้ายไปยังงานเสร็จแล้วเรียบร้อย!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // ฟังก์ชันลบงานจาก tasks
  Future<void> _deleteTask(
      BuildContext context, String userId, String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบงานเรียบร้อยแล้ว!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }
}
