import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_db4/app_ui/main_ui.dart';

class IconColorPickerScreen extends StatefulWidget {
  const IconColorPickerScreen({super.key});

  @override
  _IconColorPickerScreenState createState() => _IconColorPickerScreenState();
}

class _IconColorPickerScreenState extends State<IconColorPickerScreen> {
  Color selectedColor = Colors.blue;
  IconData selectedIcon = Icons.shopping_cart;
  TextEditingController categoryController = TextEditingController();

  final List<Color> colors = [
    Colors.red, Colors.pink, Colors.orange, Colors.yellow, Colors.blue,
    Colors.purple, Colors.green, Colors.grey, Colors.cyan, Colors.amber,
    Colors.indigo, Colors.brown,
  ];

  final List<IconData> icons = [
    Icons.public, Icons.chat, Icons.help_outline, Icons.mail, Icons.location_on,
    Icons.favorite, Icons.card_giftcard, Icons.shopping_cart, Icons.home, Icons.credit_card,
    Icons.attach_money, Icons.person, Icons.arrow_forward, Icons.photo_camera,
    Icons.notifications, Icons.qr_code, Icons.delivery_dining, Icons.calendar_today,
    Icons.info, Icons.warning, Icons.filter_list, Icons.star, Icons.menu, 
    Icons.dashboard, Icons.swap_vert, Icons.refresh, Icons.settings, Icons.add,
  ];

  Future<void> _saveData() async {
    String categoryName = categoryController.text;
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหมวดหมู่')),
      );
      return;
    }

    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('category')
          .add({
        'name': categoryName,
        'color': selectedColor.value,
        'icon': selectedIcon.codePoint,
        'timestamp': FieldValue.serverTimestamp(), // เพิ่มเวลาปัจจุบันของเซิร์ฟเวอร์
      });

      // แสดง AlertDialog เมื่อบันทึกข้อมูลเสร็จ
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // มุมโค้งมนของ Dialog
        ),
        title: const Text(
          'บันทึกสำเร็จ',
          style: TextStyle(
            color: Colors.black, // สีข้อความหัวข้อ
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'สร้างหมวดหมู่สำเร็จ', 
          style: const TextStyle(
            color: Colors.black87, // สีข้อความเนื้อหา
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const TaskScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // สีพื้นหลังปุ่ม
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // มุมโค้งมนของปุ่ม
              ),
            ),
            child: const Text(
              'ตกลง',
              style: TextStyle(
                color: Colors.white, // สีข้อความปุ่ม
              ),
            ),
          ),
        ],
      );
    },
  );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
        'สร้างหมวดหมู่',
        style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold,), // ตัวอักษรสีขาว
      ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        actions: [
          IconButton(
            icon: Icon(selectedIcon, color: selectedColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: categoryController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: colors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final color = colors[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = color;
                });
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: selectedColor == color
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: icons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final icon = icons[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIcon = icon;
                });
              },
              child: Icon(
                icon,
                color: selectedIcon == icon ? selectedColor : Colors.black,
                size: 30,
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // สีพื้นหลังปุ่ม
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // มุมโค้งมน
            ),
          ),
          child: const Text(
            'สร้างหมวดหมู่',
            style: TextStyle(
              color: Colors.white, // สีข้อความปุ่ม
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
