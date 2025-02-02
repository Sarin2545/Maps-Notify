import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImportantDataScreen extends StatelessWidget {
  const ImportantDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: Colors.black, // AppBar สีดำ
        title: const Text(
          'กิจกรรมที่สำคัญ',
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
            .collection('important') // อ่านข้อมูลจาก 'important'
            .orderBy('timestamp', descending: false) // เรียงจากเก่าสุดไปใหม่สุด
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีข้อมูลกิจกรรมที่สำคัญ',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final importantTasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: importantTasks.length,
            itemBuilder: (context, index) {
              final taskDoc = importantTasks[index];
              final task = taskDoc.data() as Map<String, dynamic>;
              final String taskId = taskDoc.id;
              final String taskName = task['task'] ?? 'No name';
              final String description = task['time'] ?? 'No description';
              final String notification =
                  task['notification'] ?? 'No notification';
              final String repeat = task['repeat'] ?? 'No repeat';
              final String priority = task['priority'] ?? 'No priority';

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
                    'ทำซ้ำ : $repeat\nวันที่และเวลา : \n($description)\nล่วงหน้า : $notification\nสำคัญ : $priority',
                    style: const TextStyle(
                      color: Colors.white70, // สีข้อความรอง
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () =>
                            _moveToFinish(context, userId, taskId, task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
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

  // ฟังก์ชันย้ายข้อมูลไปยัง 'finish_tasks' และลบออกจาก 'important'
  Future<void> _moveToFinish(BuildContext context, String userId, String taskId,
      Map<String, dynamic> task) async {
    try {
      // ย้ายข้อมูลไปยัง collection 'finish_tasks'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('finish_tasks')
          .doc(taskId)
          .set(task);

      // ลบข้อมูลออกจาก collection 'important'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('important')
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

  // ฟังก์ชันลบข้อมูลออกจาก 'important'
  Future<void> _deleteTask(
      BuildContext context, String userId, String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('important')
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
