import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/system/edit_category.dart';

class CategoryDataScreen extends StatelessWidget {
  const CategoryDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor:
            const Color.fromARGB(255, 255, 255, 255), // AppBar สีดำ
        title: const Text(
          'หมวดหมู่ของฉัน',
          style:
              TextStyle(color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,), // ตัวอักษรสีขาว
        ),
        iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 0, 0, 0)), // ไอคอนสีขาว
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('category')
            .orderBy('timestamp', descending: false) // เรียงจากเก่าสุดไปใหม่สุด
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีข้อมูลหมวดหมู่',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              var category = categories[index].data() as Map<String, dynamic>;
              String name = category['name'] ?? 'Unnamed';
              int colorValue = category['color'] ?? Colors.black.value;
              int iconCodePoint = category['icon'] ?? Icons.category.codePoint;
              String categoryId = categories[index].id;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.black, // สีพื้นหลังเป็นสีดำ
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Icon(
                    IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Color(colorValue),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // ตัวอักษรเป็นสีขาว
                  ),
                  subtitle: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('category')
                        .doc(categoryId)
                        .collection('tasks')
                        .orderBy('timestamp', descending: false) // เรียงจากเก่าสุดไปใหม่สุด
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      if (taskSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (!taskSnapshot.hasData ||
                          taskSnapshot.data!.docs.isEmpty) {
                        return const Text('ไม่มีข้อมูลกิจกรรม',
                            style: TextStyle(color: Colors.white));
                      }

                      final tasks = taskSnapshot.data!.docs;
                      int finishedCount = 0;
                      int totalCount = tasks.length;

                      for (var task in tasks) {
                        var taskData = task.data() as Map<String, dynamic>;
                        if (taskData['status'] == 'finished') {
                          finishedCount++;
                        }
                      }

                      return Text(
                        '$finishedCount/$totalCount',
                        style: const TextStyle(
                            color: Colors.white), // ตัวอักษรเป็นสีขาว
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DataInCategory(
                          categoryId: categoryId,
                          categoryName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
        ],
      ),
    );
  }
}

class DataInCategory extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const DataInCategory({
    required this.categoryId,
    required this.categoryName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    Future<void> _moveToFinishData(BuildContext context, String taskId) async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('category')
          .doc(categoryId)
          .collection('tasks')
          .doc(taskId)
          .update({'status': 'finished'});
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(
          '$categoryName',
          style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,),
        ),
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('category')
            .doc(categoryId)
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
                'ไม่มีข้อมูลกิจกรรม',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index].data() as Map<String, dynamic>;
              String taskName = task['name'] ?? 'Unnamed';
              String taskId = tasks[index].id;

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
                      fontSize: 16,
                      color: Colors.white,
                fontWeight: FontWeight.bold, // ตัวอักษรเป็นสีขาว
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ตรวจสอบสถานะของกิจกรรม
                      if (task['status'] != 'finished')
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () => _moveToFinishData(context, taskId),
                        ),
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
                                      Navigator.of(context).pop();
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
                                  ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .collection('category')
                                          .doc(categoryId)
                                          .collection('tasks')
                                          .doc(taskId)
                                          .delete();
                                      Navigator.of(context).pop();
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'delete',
            backgroundColor: const Color.fromARGB(255, 255, 1, 1),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.white, // พื้นหลังสีขาว
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // มุมโค้งมนของ Dialog
                    ),
                    title: const Text(
                      'ยืนยันการลบหมวดหมู่',
                      style: TextStyle(
                        color: Colors.black, // สีข้อความหัวข้อ
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      'คุณต้องการลบหมวดหมู่นี้และกิจกรรมทั้งหมดหรือไม่?',
                      style: TextStyle(
                        color: Colors.black87, // สีข้อความเนื้อหา
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // ปิด Dialog
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black, // สีข้อความปุ่ม
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('category')
                              .doc(categoryId)
                              .delete(); // ลบหมวดหมู่
                          Navigator.of(context).pop(); // ปิด Dialog
                          Navigator.of(context).pop(); // กลับไปหน้าหมวดหมู่
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                              255, 0, 0, 0), // สีพื้นหลังปุ่ม
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8.0), // มุมโค้งมนของปุ่ม
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
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'setting',
            backgroundColor: const Color.fromARGB(255, 230, 96, 8),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditCategory(categoryId: categoryId), // ส่ง categoryId ไป
                ),
              );
            },
            child: const Icon(Icons.settings, color: Colors.white),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: const Color.fromARGB(255, 8, 137, 36),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTaskScreen(categoryId: categoryId),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  final String categoryId;

  const AddTaskScreen({required this.categoryId, super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskController = TextEditingController();

  Future<void> _addTask() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String taskName = _taskController.text.trim();

    if (taskName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('category')
          .doc(widget.categoryId)
          .collection('tasks')
          .add({
        'name': taskName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(), // เพิ่มเวลาปัจจุบันของเซิร์ฟเวอร์
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ตั้งค่าพื้นหลังเป็นสีขาว
      appBar: AppBar(
        backgroundColor: Colors.black, // ตั้งค่าพื้นหลังของ AppBar เป็นสีดำ
        title: const Text(
          'เพิ่มกิจกรรม',
          style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold,), // สีตัวอักษรใน AppBar
        ),
        iconTheme: const IconThemeData(color: Colors.white), // สีไอคอนใน AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // จัดข้อความชิดซ้าย
          children: [
            const Text(
              'ชื่อกิจกรรม',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black, // สีตัวอักษรหัวข้อ
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200], // สีพื้นหลังของ TextField
                labelText: 'ชื่อกิจกรรม',
                labelStyle:
                    const TextStyle(color: Colors.black54), // สีข้อความ Label
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // มุมโค้งมน
                  borderSide: BorderSide.none, // ไม่มีเส้นขอบ
                ),
              ),
              style: const TextStyle(
                  color: Colors.black), // สีข้อความที่ผู้ใช้กรอก
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, // ปุ่มให้เต็มความกว้าง
              child: ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // สีพื้นหลังปุ่ม
                  padding: const EdgeInsets.symmetric(
                      vertical: 16), // ขนาด Padding ในปุ่ม
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8.0), // มุมโค้งมนของปุ่ม
                  ),
                ),
                child: const Text(
                  'บันทึก',
                  style: TextStyle(
                    color: Colors.white, // สีข้อความในปุ่ม
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
