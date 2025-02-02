import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Priority extends StatefulWidget {
  const Priority({super.key});

  @override
  State<Priority> createState() => _PriorityState();
}

class _PriorityState extends State<Priority> {
  String _selectedPriority = ''; // ตัวแปรเก็บระดับความสำคัญที่เลือก

  // ตัวแปรเก็บรายการที่ดึงจาก Firestore
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _importantTasks =
      []; // ตัวแปรเก็บข้อมูลจาก important

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
      _tasks = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      _importantTasks = importantSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  // ฟังก์ชั่นในการกำหนดสีตามระดับความสำคัญ
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'มาก':
        return Colors.red; // สีแดงสำหรับความสำคัญสูง
      case 'ปานกลาง':
        return Colors.orange; // สีส้มสำหรับความสำคัญปานกลาง
      case 'น้อย':
        return Colors.yellow; // สีเหลืองสำหรับความสำคัญต่ำ
      default:
        return Colors.white; // สีขาวถ้าไม่มีการกำหนด
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0), // AppBar สีดำ
        title: const Text(
          'ระดับความสำคัญ',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ปุ่ม 3 ปุ่มในแนวนอน
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPriority = 'มาก';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // สีปุ่ม
                  ),
                  child: const Text(
                    'มาก',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPriority = 'ปานกลาง';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // สีปุ่ม
                  ),
                  child: const Text(
                    'ปานกลาง',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPriority = 'น้อย';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow, // สีปุ่ม
                  ),
                  child: const Text(
                    'น้อย',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(), // เส้นคั่น
          Expanded(
            child: _selectedPriority.isEmpty
                ? const Center(
                    child: Text(
                      'กรุณาเลือกระดับความสำคัญ',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: (_tasks + _importantTasks)
                        .where((task) => task['priority'] == _selectedPriority)
                        .length,
                    itemBuilder: (context, index) {
                      final task = (_tasks + _importantTasks)
                          .where(
                              (task) => task['priority'] == _selectedPriority)
                          .toList()[index];

                      final String taskName = task['task'] ?? 'Unnamed';
                      final String time = task['time'] ?? 'No time';
                      final String priority = task['priority'] ?? 'no priority';

                      // ใช้ฟังก์ชั่น _getPriorityColor เพื่อกำหนดสี
                      Color priorityColor = _getPriorityColor(priority);

                      final bool isImportant = _importantTasks.contains(task);

                      return Container(
                        decoration: BoxDecoration(
                          color: priorityColor, // ใช้สีตามระดับความสำคัญ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(
                            taskName,
                            style: TextStyle(
                              color: isImportant
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : Colors.black, // ใช้สีตัวอักษรตามประเภท
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'วันที่และเวลา : $time\nสำคัญ : $priority',
                            style: TextStyle(
                              color: isImportant
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 0, 0, 0), // ใช้สีตัวอักษรตามประเภท
                              fontSize: 16
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
