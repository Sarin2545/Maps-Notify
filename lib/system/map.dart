import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as location;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_db4/system/notification_test.dart';

import '../main.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

/////////////////////////////////////////////////////////////////////////
// เริ่มต้นการตั้งค่าการแจ้งเตือน
Future<void> initialize() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon'); // ใส่ไอคอนของแอป

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// ฟังก์ชันที่ใช้แสดงการแจ้งเตือน
Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    channelDescription: 'your_channel_description',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformDetails,
    payload: 'item x',
  );
}

final notificationService = NotificationService();

Future<void> checkProximity(LatLng userPosition, String userId) async {
  // ดึงข้อมูลตำแหน่งหมุดสีแดงจาก Firebase
  QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('category')
      .get();

  for (var categoryDoc in snapshot.docs) {
    String categoryId = categoryDoc.id;

    // ดึงข้อมูลชื่อจาก category
    String name = categoryDoc.data()['name'] ??
        'กิจกรรม'; // หากไม่มี name ให้ใช้ค่า default 'กิจกรรม'

    QuerySnapshot<Map<String, dynamic>> locationSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('category')
            .doc(categoryId)
            .collection('location')
            .get();

    for (var locationDoc in locationSnapshot.docs) {
      Map<String, dynamic> locationData = locationDoc.data();

      // ข้อมูลหมุดสีแดง
      double latitude = locationData['latitude'];
      double longitude = locationData['longitude'];
      double radius = locationData['radius'];

      LatLng redMarkerPosition = LatLng(latitude, longitude);

      // ใช้ geolocator คำนวณระยะห่าง
      double distanceInMeters = await Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        redMarkerPosition.latitude,
        redMarkerPosition.longitude,
      );

      // ตรวจสอบว่าหมุดสีฟ้าเข้าใกล้รัศมีหมุดสีแดงหรือไม่
      if (distanceInMeters <= radius) {
        notificationService.showNotification(
          'คุณอยู่ในรัศมี : $name',
          'มีกิจกรรมที่ต้องทำ!!!',
        );
        break; 
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////
class _MapsPageState extends State<MapsPage> {
  LatLng? _userLocation;
  location.Location _location = location.Location();
  late MapController _mapController;
  TextEditingController _searchController = TextEditingController();
  LatLng? _markerPosition;
  String? categoryId;
  double _radius = 100; // รัศมีเริ่มต้นในหน่วยเมตร
  double _zoomLevel = 13.0; // ระดับซูมเริ่มต้น

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    notificationService.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCategorySelectionDialog();
    });
  }

  void _startLocationTracking() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.LocationData currentLocation = await _location.getLocation();
    setState(() {
      _userLocation =
          LatLng(currentLocation.latitude!, currentLocation.longitude!);
    });

    String userId = FirebaseAuth.instance.currentUser!.uid;

    // ตรวจสอบระยะห่างจากหมุดสีแดง
    if (_userLocation != null) {
      checkProximity(_userLocation!, userId);
    }

    _location.onLocationChanged.listen((location.LocationData currentLocation) {
      setState(() {
        _userLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });

      // ตรวจสอบระยะห่างจากหมุดสีแดงทุกครั้งที่ตำแหน่งเปลี่ยน
      if (_userLocation != null) {
        checkProximity(_userLocation!, userId);
      }
    });
  }

  String? categoryName; // ชื่อหมวดหมู่ที่เลือก

  void _showCategorySelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text(
            'เลือกหมวดหมู่',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('category')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('ไม่มีหมวดหมู่ที่สามารถเลือกได้'),
                );
              }

              final categories = snapshot.data!.docs;
              return ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  var category =
                      categories[index].data() as Map<String, dynamic>;
                  String categoryNameLocal = category['name'] ?? 'Unnamed';
                  return ListTile(
                    title: Text(categoryNameLocal),
                    onTap: () {
                      setState(() {
                        categoryId = categories[index].id;
                        categoryName = categoryNameLocal; // อัปเดตชื่อหมวดหมู่
                      });
                      Navigator.of(context).pop();
                      _startLocationTracking();
                    },
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // ย้อนกลับไปยังหน้าก่อนหน้า
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLocationToFirebase(LatLng position) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    if (categoryId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('category')
          .doc(categoryId)
          .collection('location')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'radius': _radius, // บันทึกรัศมีที่ผู้ใช้เลือก
        'createdAt': Timestamp.now(),
      });
    }
  }

  void _showRadiusSelectionDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text(
            'ระยะรัศมีที่แจ้งเตือน',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('100 เมตร'),
                onTap: () {
                  setState(() {
                    _radius = 100;
                  });
                  Navigator.of(context).pop();
                  _showMarkerDialog(point);
                },
              ),
              const Divider(), // เส้นแบ่งระหว่างตัวเลือก
              ListTile(
                title: const Text('500 เมตร'),
                onTap: () {
                  setState(() {
                    _radius = 500;
                  });
                  Navigator.of(context).pop();
                  _showMarkerDialog(point);
                },
              ),
              const Divider(), // เส้นแบ่งระหว่างตัวเลือก
              ListTile(
                title: const Text('1000 เมตร'),
                onTap: () {
                  setState(() {
                    _radius = 1000;
                  });
                  Navigator.of(context).pop();
                  _showMarkerDialog(point);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMarkerDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text(
            'ยืนยันการปักหมุด',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'คุณต้องการบันทึกตำแหน่งนี้หรือไม่?',
            style: TextStyle(
              color: Colors.black87,
            ),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _markerPosition = point;
                });
                _saveLocationToFirebase(point); // บันทึกตำแหน่งและรัศมี
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
  }

  double _calculatePixelRadius(double radiusInMeters, double zoomLevel) {
    const double equatorLength =
        40075016.686; // ความยาวเส้นศูนย์สูตรในหน่วยเมตร
    double metersPerPixel = equatorLength / (256 * math.pow(2, zoomLevel));
    return radiusInMeters / metersPerPixel;
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);

        if (results.isEmpty) {
          _showNoResultsDialog();
          return;
        }

        _showSearchResultsDialog(results);
      } else {
        _showErrorDialog('Error searching for places.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while searching.');
    }
  }

  void _showNoResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          'ขออภัยไม่พบสถานที่',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'ลองใช้คีย์เวิร์ดอื่น',
          style: TextStyle(
            color: Colors.black87, // สีข้อความเนื้อหา
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ตกลง',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          'Error',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.black87, // สีข้อความเนื้อหา
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

////////////////////////////////////////////////////////////////////////
  // ฟังก์ชันแสดง Dialog เพื่อยืนยันการลบหมุดสีแดง
  void _showDeleteConfirmationDialog(String locationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          'ลบหมุดนี้?',
          style: TextStyle(
            color: Colors.black, // สีข้อความหัวข้อ
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'คุณต้องการลบหมุดนี้หรือไม่?',
          style: TextStyle(
            color: Colors.black87, // สีข้อความเนื้อหา
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ปิด dialog
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
              // ลบหมุดจาก Firebase
              await _deleteLocationFromFirebase(locationId);
              Navigator.of(context).pop(); // ปิด dialog หลังจากลบ
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
                color: Colors.white,
                fontWeight: FontWeight.bold, // สีข้อความปุ่ม
              ),
            ),
          ),
        ],
      ),
    );
  }

// ฟังก์ชันสำหรับลบหมุดจาก Firebase
  Future<void> _deleteLocationFromFirebase(String locationId) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    if (categoryId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('category')
          .doc(categoryId)
          .collection('location')
          .doc(locationId)
          .delete();
    }
  }

// ฟังก์ชันเพื่อให้การคลิกที่หมุดสีแดงแสดง dialog ยืนยันการลบ
  void _onMarkerTapped(String locationId) {
    _showDeleteConfirmationDialog(locationId);
  }
//////////////////////////////////////////////////////////////////////////

  void _showSearchResultsDialog(List results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'คลิกเพื่อเลือกสถานที่',
          style: TextStyle(
            color: Colors.black, // สีข้อความหัวข้อ
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final place = results[index];
              final name = place['display_name'] ?? 'Unnamed';
              final lat = double.tryParse(place['lat'] ?? '0');
              final lon = double.tryParse(place['lon'] ?? '0');

              return ListTile(
                title: Text(name),
                onTap: () {
                  if (lat != null && lon != null) {
                    final position = LatLng(lat, lon);
                    setState(() {
                      _markerPosition = position;
                      _mapController.move(position, _zoomLevel);
                    });
                    Navigator.of(context).pop();
                  }
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          categoryName ??
              'ปักหมุดกิจกรรมบนแผนที่', // ใช้ชื่อหมวดหมู่หรือข้อความเริ่มต้น
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      hintText: 'ค้นหาสถานที่...',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: _searchPlace,
                ),
              ],
            ),
          ),
          Expanded(
            child: _userLocation == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCameraFit: CameraFit.bounds(
                              bounds: LatLngBounds(
                                _userLocation!,
                                _userLocation!,
                              ),
                              padding: const EdgeInsets.all(50),
                            ),
                            minZoom: 3.0,
                            maxZoom: 18.0,
                            onTap: (tapPosition, point) {
                              _showRadiusSelectionDialog(point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _userLocation!,
                                  width: 40.0,
                                  height: 40.0,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                    size: 40.0,
                                  ),
                                ),
                                if (_markerPosition != null)
                                  Marker(
                                    point: _markerPosition!,
                                    width: 40.0,
                                    height: 40.0,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color.fromARGB(255, 175, 76, 76),
                                      size: 40.0,
                                    ),
                                  ),
                              ],
                            ),
                            if (categoryId != null)
                              if (categoryId != null)
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      .collection('category')
                                      .doc(categoryId)
                                      .collection('location')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return const Center(
                                          child:
                                              Text('Error fetching locations'));
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const SizedBox();
                                    }

                                    final locations = snapshot.data!.docs;
                                    List<Marker> savedMarkers = [];

                                    for (var doc in locations) {
                                      var data =
                                          doc.data() as Map<String, dynamic>;
                                      LatLng position = LatLng(
                                          data['latitude'], data['longitude']);
                                      double radius = data['radius'] ??
                                          100; // ดึงค่า radius จาก Firebase
                                      String locationId = doc
                                          .id; // ใช้ ID ของ document เป็นรหัสหมุด

                                      // สร้าง Marker และจับการคลิกด้วย GestureDetector
                                      savedMarkers.add(
                                        Marker(
                                          point: position,
                                          width: 40.0,
                                          height: 40.0,
                                          child: GestureDetector(
                                            onTap: () => _onMarkerTapped(
                                                locationId), // เรียกใช้ฟังก์ชันเมื่อคลิกที่หมุด
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // ไอคอนหมุด
                                                const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 40.0,
                                                ),
                                                // ข้อความ radius
                                                Positioned(
                                                  bottom:
                                                      7, // เลื่อนข้อความลงมาจากไอคอน
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 20,
                                                      vertical: 3,
                                                    ),
                                                    child: Text(
                                                      radius >= 1000
                                                          ? '${(radius / 1000).toStringAsFixed(radius % 1000 == 0 ? 0 : 1)} km' // ไม่แสดงทศนิยมถ้าค่าเป็นจำนวนเต็ม
                                                          : '${radius.toInt()} m', // แสดงเป็น m ถ้า radius < 1000
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0),
                                                        fontWeight:
                                                            FontWeight.bold,
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

                                    return MarkerLayer(markers: savedMarkers);
                                  },
                                )
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
