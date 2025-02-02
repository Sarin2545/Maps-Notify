import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<dynamic>> _events = {}; // เก็บข้อมูลกิจกรรม

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    // ดึงข้อมูลจากคอลเล็กชัน tasks
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('time', descending: false)
        .get();

    // ดึงข้อมูลจากคอลเล็กชัน important
    final importantSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('important')
        .orderBy('time', descending: false)
        .get();

    // รวมข้อมูลจากทั้งสองคอลเล็กชัน
    final allDocs = [...tasksSnapshot.docs, ...importantSnapshot.docs];

    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var doc in allDocs) {
      final data = doc.data();
      if (data['time'] != null) {
        // แปลง `time` ให้เป็น DateTime
        DateTime fullDateTime;
        if (data['time'] is Timestamp) {
          fullDateTime = (data['time'] as Timestamp).toDate();
        } else {
          fullDateTime = DateTime.parse(data['time']);
        }

        // ตัดเวลาส่วนชั่วโมง/นาทีให้เหลือแค่วันที่
        DateTime taskDate =
            DateTime(fullDateTime.year, fullDateTime.month, fullDateTime.day);

        // เก็บข้อมูลกิจกรรมใน Map
        events[taskDate] = events[taskDate] ?? [];
        events[taskDate]!.add({
          'task': data['task'] ?? 'Unnamed Task',
          'time': fullDateTime, // เก็บเวลาเต็มรูปแบบ
          'type': doc.reference.path.contains('important')
              ? 'important'
              : 'task', // ระบุประเภท
        });
      }
    }

    // อัปเดตสถานะ
    setState(() {
      _events = events;
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      if (_events.containsKey(todayWithoutTime)) {
        _selectedDay = todayWithoutTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: const Text(
          'ปฏิทิน',
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
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(
                    selectedDay.year, selectedDay.month, selectedDay.day);
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              DateTime dateWithoutTime = DateTime(day.year, day.month, day.day);
              return _events[dateWithoutTime] ?? [];
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: (_events[_selectedDay]?.isEmpty ?? true)
                ? const Center(
                    child: Text('ไม่มีข้อมูลกิจกรรมในวันนี้'),
                  )
                : ListView.builder(
                    itemCount: _events[_selectedDay]!.length,
                    itemBuilder: (context, index) {
                      // เรียงลำดับกิจกรรมตามเวลา
                      _events[_selectedDay]!.sort((a, b) =>
                          (a['time'] as DateTime)
                              .compareTo(b['time'] as DateTime));

                      final event = _events[_selectedDay]![index];
                      final time = event['time'] as DateTime;

                      return Container(
                        decoration: BoxDecoration(
                          color: event['type'] == 'important'
                              ? Colors.orange
                              : Colors.black, // สีพื้นหลังต่างกันตามประเภท
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(
                            event['task'],
                            style: TextStyle(
                              color: event['type'] == 'important'
                                  ? Colors.black
                                  : Colors.white, // สีข้อความเปลี่ยนตามประเภท
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'วันที่ : ${time.day}/${time.month}/${time.year} \nเวลา : ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: event['type'] == 'important'
                                  ? Colors.black87
                                  : Colors.white70, // สีข้อความเปลี่ยนตามประเภท
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
