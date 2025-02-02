import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/system/edit_activity.dart';

class FinishDataScreen extends StatelessWidget {
  const FinishDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: Colors.black, // AppBar สีดำ
        title: const Text(
          'กิจกรรมที่เสร็จแล้ว',
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
            .collection('finish_tasks')
            .orderBy('timestamp', descending: false) // เรียงจากเก่าสุดไปใหม่สุด
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีข้อมูลกิจกรรมที่เสร็จแล้ว',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskDoc = tasks[index];
              final task = taskDoc.data() as Map<String, dynamic>;
              final String taskId = taskDoc.id;
              final String taskName = task['task'] ?? 'Unnamed';
              final String time = task['time'] ?? 'No time';
              final String notification =
                  task['notification'] ?? 'No notification';
              //final String repeat = task['repeat'] ?? 'ไม่ได้ตั้งค่า';
              //final String priority = task['priority'] ?? 'ไม่ได้ตั้งค่า';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.black, // พื้นหลังสีดำ
                  borderRadius: BorderRadius.circular(10), // มุมโค้งมน
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(
                    taskName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // ตัวอักษรสีขาว
                    ),
                  ),
                  subtitle: Text(
                    'วันที่และเวลา : \n($time)\nล่วงหน้า : $notification',
                    style: const TextStyle(
                      color: Colors.white70, // สีข้อความรอง
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor:
                                    Colors.white, // พื้นหลังของ Dialog
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                title: const Text(
                                  'ยืนยันการลบ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: const Text(
                                  'คุณต้องการลบกิจกรรมนี้หรือไม่?',
                                  style: TextStyle(color: Colors.black87),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text(
                                      'ยกเลิก',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteTask(context, userId, taskId);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'ตกลง',
                                      style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold,),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.green),
                        onPressed: () async {
                          await _moveToAllData(context, userId, taskId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditActivity(taskId: taskId),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ฟังก์ชันย้ายกิจกรรมไปยัง all data
  Future<void> _moveToAllData(
      BuildContext context, String userId, String taskId) async {
    try {
      var taskSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('finish_tasks')
          .doc(taskId)
          .get();

      if (taskSnapshot.exists) {
        final taskData = taskSnapshot.data();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(taskId)
            .set(taskData!);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('finish_tasks')
            .doc(taskId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('โปรดกำหนดวันที่และเวลา!')),
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

  // ฟังก์ชันลบข้อมูลออกจาก 'finish_tasks'
  Future<void> _deleteTask(
      BuildContext context, String userId, String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('finish_tasks')
          .doc(taskId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบกิจกรรมเรียบร้อยแล้ว!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
        );
      }
    }
  }
}
