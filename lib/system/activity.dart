import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:test_db4/app_ui/main_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/app_ui/activity_option.dart';

class MyFormPage extends StatefulWidget {
  const MyFormPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyFormPageState createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _notificationOption;
  String? _repeatOption; // ตัวแปรสำหรับเก็บค่าการทำซ้ำ
  String? _priorityLevel; // ตัวแปรสำหรับเก็บค่าระดับความสำคัญ

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

  // ฟังก์ชันสำหรับบันทึกข้อมูลไปยัง Firebase Firestore
  Future<void> _saveData() async {
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
              title: const Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'ไม่สามารถเลือกเวลาที่เป็นอดีต',
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
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
      String task = _taskController.text;
      String notification = _notificationOption ?? "ไม่เลือก";
      String repeat = _repeatOption ?? "ไม่เลือก";
      String priority = _priorityLevel ?? "ไม่เลือก";

      // แปลงค่าเวลาที่เลือกแจ้งเตือนเป็นนาที
      int notificationMinutes = 0;
      if (_notificationOption != null) {
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
      }

      // คำนวณเวลาแจ้งเตือน
      DateTime notificationTime =
          _selectedDateTime!.subtract(Duration(minutes: notificationMinutes));

      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .add({
          'task': task,
          'time': DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!),
          'notification': notification,
          'notificationTime':
              DateFormat('yyyy-MM-dd HH:mm').format(notificationTime),
          'repeat': repeat, // บันทึกค่าการทำซ้ำ
          'priority': priority, // บันทึกค่าระดับความสำคัญ
          'timestamp':
              FieldValue.serverTimestamp(), // เพิ่มเวลาปัจจุบันของเซิร์ฟเวอร์
        });

        // เรียกใช้ฟังก์ชันแจ้งเตือน
        await ActivityOptionScreen.fetchAllTasksAndNotify();

        // โชว์ dialog ว่าบันทึกข้อมูลสำเร็จ
        showDialog(
          context: context,
          builder: (context) {
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
                'กิจกรรม : $task\nวันที่และเวลา : ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!)}\nแจ้งเตือนล่วงหน้า : $notification\nทำซ้ำ : $repeat\nระดับความสำคัญ : $priority',
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const TaskScreen()),
                      (Route<dynamic> route) => false,
                    );
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // แสดงข้อความ error ถ้าเกิดข้อผิดพลาด
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              title: const Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'ไม่สามารถบันทึกข้อมูลได้: $e',
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
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
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
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
          'เพิ่มกิจกรรมใหม่',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  if (_selectedDateTime != null &&
                      _selectedDateTime!.isBefore(DateTime.now())) {
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
                  onPressed: _saveData,
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
