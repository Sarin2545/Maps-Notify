import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/app_ui/activity_option.dart';

class EditActivity extends StatefulWidget {
  final String taskId; // รับ ID ของกิจกรรม
  // รับข้อมูลกิจกรรมเดิม

  const EditActivity({Key? key, required this.taskId}) : super(key: key);

  @override
  _MyFormPageState createState() => _MyFormPageState();
}

class _MyFormPageState extends State<EditActivity> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _notificationOption;
  String? _repeatOption;
  String? _priorityLevel;

  @override
  void initState() {
    super.initState();
    _fetchTaskData();
    // กำหนดค่าเริ่มต้นจาก taskData
  }

  Future<void> _fetchTaskData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // ดึงข้อมูลจาก Firestore ตาม taskId
      DocumentSnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (taskSnapshot.exists) {
        // ดึงข้อมูลจาก Firestore และตั้งค่าให้กับตัวแปรในฟอร์ม
        var taskData = taskSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _taskController.text = taskData['task'] ?? '';
          _selectedDateTime =
              DateFormat('yyyy-MM-dd HH:mm').parse(taskData['time']);
          //_notificationOption = taskData['notification'];
          //_repeatOption = taskData['repeat'];
          //_priorityLevel = taskData['priority'];
        });
      }
    } catch (e) {
      print('Error fetching task data: $e');
    }
  }

  // ฟังก์ชันสำหรับอัปเดตข้อมูลใน Firestore
  Future<void> _updateData() async {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
    // ตรวจสอบว่าเวลาไม่เป็นอดีต
    if (_selectedDateTime!.isBefore(DateTime.now())) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            title: const Text('เกิดข้อผิดพลาด',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),),
            content: const Text('ไม่สามารถเลือกเวลาที่เป็นอดีต',style: const TextStyle(
                  color: Colors.black87,
                ),),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง',
                    style: TextStyle(
                      color: Colors.white,
                  fontWeight: FontWeight.bold,
                    ),),style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
              ),
              
            ],
          );
        },
      );
      return; // หยุดการทำงานหากเวลาเป็นอดีต
    }
    //if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      String task = _taskController.text;
      String notification = _notificationOption ?? "ไม่เลือก";
      String repeat = _repeatOption ?? "ไม่เลือก";
      String priority = _priorityLevel ?? "ไม่เลือก";

      int notificationMinutes = 0;
      switch (_notificationOption) {
        case '15 นาที':
          notificationMinutes = 15;
          break;
        case '30 นาที':
          notificationMinutes = 30;
          break;
        case '45 นาที':
          notificationMinutes = 45;
          break;
        case '60 นาที':
          notificationMinutes = 60;
          break;
        default:
          notificationMinutes = 0;
          break;
      }

      DateTime notificationTime =
          _selectedDateTime!.subtract(Duration(minutes: notificationMinutes));

      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // อัปเดตเอกสารใน Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(widget.taskId)
            .update({
          'task': task,
          'time': DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!),
          'notification': notification,
          'notificationTime':
              DateFormat('yyyy-MM-dd HH:mm').format(notificationTime),
          'repeat': repeat,
          'priority': priority,
          //'timestamp': FieldValue.serverTimestamp(), // เพิ่มเวลาปัจจุบันของเซิร์ฟเวอร์
        });

        await ActivityOptionScreen.fetchAllTasksAndNotify();

        // แสดง Dialog บันทึกสำเร็จ
        showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            title: const Text(
              'บันทึกสำเร็จ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'ข้อมูลกิจกรรมถูกแก้ไข',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
      } catch (e) {
        // แสดงข้อความ Error
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text('ไม่สามารถอัปเดตข้อมูลได้: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // ฟังก์ชันสำหรับเลือกวันที่และเวลา
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'แก้ไขกิจกรรม',
          style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold,),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _taskController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  labelText: 'กิจกรรมที่ต้องทำ',
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                validator: (value) {
  if (value == null || value.isEmpty) {
    return 'กรุณากรอกข้อมูลกิจกรรม';
  }
  if (_selectedDateTime == null) {
    return 'กรุณาเลือกวันที่และเวลา';
  }
  // ตรวจสอบว่าเวลาไม่เป็นอดีต
  if (_selectedDateTime != null && _selectedDateTime!.isBefore(DateTime.now())) {
    return 'ไม่สามารถเลือกเวลาที่เป็นอดีต';
  }
  return null;
},
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'เลือกวันที่และเวลา : ',
                    style: TextStyle(color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => _selectDateTime(context),
                    icon: const Icon(Icons.calendar_today),
                    color: Colors.black,
                  ),
                  if (_selectedDateTime != null)
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!),
                      style: const TextStyle(color: Colors.black),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'แจ้งเตือนล่วงหน้า (ไม่บังคับ)',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              ...['15 นาที', '30 นาที', '45 นาที', '60 นาที'].map(
                (option) => RadioListTile<String>(
                  title: Text(
                    '$option',
                    style: const TextStyle(color: Colors.black),
                  ),
                  value: option,
                  groupValue: _notificationOption,
                  onChanged: (value) {
                    setState(() {
                      _notificationOption = value;
                    });
                  },
                  activeColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'ทำซ้ำ',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _repeatOption,
                          hint: const Text(
                            'ไม่บังคับ',
                            style: TextStyle(color: Colors.black54),
                            textAlign: TextAlign
                                .center, // จัดข้อความ 'ไม่บังคับ' ให้อยู่ตรงกลาง
                          ),
                          items: ['1 วัน', '7 วัน', '30 วัน', '365 วัน']
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option,
                                  child: Center(
                                      // ใช้ Center เพื่อจัดข้อความให้ตรงกลาง
                                      child: Text(
                                    option,
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0)),
                                  )),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _repeatOption = value;
                            });
                          },
                          dropdownColor: const Color.fromARGB(
                              255, 247, 240, 240), // สีพื้นหลังของลิสต์
                          style: const TextStyle(
                            color: Color.fromARGB(255, 60, 59,
                                59), // สีข้อความของตัวเลือกที่เลือกแล้ว
                          ),
                          iconEnabledColor: Colors.black, // สีของไอคอนลูกศร
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 247, 240,
                                240), // สีพื้นหลังของกรอบ Dropdown
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: Colors.black, // สีกรอบเริ่มต้น
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: Colors.black, // สีกรอบเมื่อโฟกัส
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // ระยะห่างระหว่างสองคอลัมน์
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'ระดับความสำคัญ',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _priorityLevel,
                          hint: const Text(
                            'ไม่บังคับ',
                            style: TextStyle(color: Colors.black54),
                            textAlign: TextAlign
                                .center, // จัดข้อความ 'ไม่บังคับ' ให้อยู่ตรงกลาง
                          ),
                          items: ['น้อย', 'ปานกลาง', 'มาก']
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option,
                                  child: Center(
                                    // ใช้ Center เพื่อจัดข้อความให้ตรงกลาง
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                          color: Color.fromARGB(255, 0, 0,
                                              0)), // สีข้อความในลิสต์
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _priorityLevel = value;
                            });
                          },
                          dropdownColor: Color.fromARGB(
                              255, 247, 240, 240), // สีพื้นหลังของลิสต์
                          style: const TextStyle(
                            color: Color.fromARGB(255, 60, 59,
                                59), // สีข้อความของตัวเลือกที่เลือกแล้ว
                          ),
                          iconEnabledColor: Colors.black, // สีของไอคอนลูกศร
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 247, 240,
                                240), // สีพื้นหลังของกรอบ Dropdown
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: Colors.black, // สีกรอบเริ่มต้น
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: Colors.black, // สีกรอบเมื่อโฟกัส
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'บันทึกกิจกรรม',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
