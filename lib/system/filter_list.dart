import 'package:flutter/material.dart';
import 'package:test_db4/Filter/calendar.dart';
import 'package:test_db4/Filter/location.dart';
import 'package:test_db4/Filter/priority.dart';
import 'package:test_db4/Filter/repeat.dart';

class FilterList extends StatelessWidget {
  const FilterList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), // AppBar สีดำ
        title: const Text(
          'คัดกรองกิจกรรม',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // แสดง 2 การ์ดต่อแถว
                crossAxisSpacing: 16, // ระยะห่างระหว่างการ์ดในแนวนอน
                mainAxisSpacing: 16, // ระยะห่างระหว่างการ์ดในแนวตั้ง
                childAspectRatio: 3 / 2, // สัดส่วนของการ์ด
                children: [
                  // การ์ด: ทั้งหมด
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Calendar()),
                      );
                    },
                    child: _buildTaskCard(
                      'ปฏิทิน',
                      Icons.calendar_today,
                      0, // จำนวนตัวอย่าง
                      const Color.fromARGB(255, 255, 255, 255), // สีไอคอน
                    ),
                  ),
                  // การ์ด: ปักหมุด
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Priority()),
                      );
                    },
                    child: _buildTaskCard(
                      'ความสำคัญ',
                      Icons.push_pin,
                      0, // จำนวนตัวอย่าง
                      const Color.fromARGB(255, 255, 255, 255), // สีไอคอน
                    ),
                  ),
                  // การ์ด: เสร็จแล้ว
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LocationPage()),
                      );
                    },
                    child: _buildTaskCard(
                      'สถานที่แจ้งเตือน',
                      Icons.location_on,
                      0, // จำนวนตัวอย่าง
                      const Color.fromARGB(255, 255, 255, 255), // สีไอคอน
                    ),
                  ),
                  // การ์ด: ที่ต้องทำ
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Repeat()),
                      );
                    },
                    child: _buildTaskCard(
                      'กิจกรรมทำซ้ำ',
                      Icons.pending_actions,
                      0, // จำนวนตัวอย่าง
                      const Color.fromARGB(255, 253, 253, 253), // สีไอคอน
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างการ์ด
  Widget _buildTaskCard(String title, IconData icon, int count, Color iconColor) {
  return Card(
    color: Colors.black, // สีพื้นหลังของการ์ดเป็นสีดำ
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: iconColor), // ใช้สีที่ส่งเข้ามาสำหรับไอคอน
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
          child: count > 0 // แสดงเฉพาะถ้า count มากกว่า 0
              ? Text(
                  '$count',
                  style: TextStyle(color: iconColor, fontSize: 20), // ใช้สีที่ส่งเข้ามาสำหรับจำนวน
                )
              : const SizedBox.shrink(), // ถ้า count เป็น 0 จะไม่แสดงอะไร
        ),
      ],
    ),
  );
  }
}
