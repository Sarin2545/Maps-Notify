import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as location;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_db4/system/notification_test.dart';

import '../main.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _MapsPageState();
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
        // ถ้าเข้าใกล้ แสดงการแจ้งเตือน พร้อมชื่อกิจกรรม
        notificationService.showNotification(
          'คุณอยู่ในรัศมี : $name',
          'มีกิจกรรมที่ต้องทำ!!!',
        );
        break; // ออกจากลูปเมื่อพบว่าหมุดสีฟ้าอยู่ในรัศมี
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////
class _MapsPageState extends State<LocationPage> {
  LatLng? _userLocation;
  location.Location _location = location.Location();
  late MapController _mapController;
  LatLng? _markerPosition;
  String? categoryId;
  //double _zoomLevel = 13.0; // ระดับซูมเริ่มต้น

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    notificationService.initialize();

    _startLocationTracking(); // เริ่มการติดตามตำแหน่งผู้ใช้
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

  double _calculatePixelRadius(double radiusInMeters, double zoomLevel) {
    const double equatorLength =
        40075016.686; // ความยาวเส้นศูนย์สูตรในหน่วยเมตร
    double metersPerPixel = equatorLength / (256 * math.pow(2, zoomLevel));
    return radiusInMeters / metersPerPixel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'สถานที่แจ้งเตือน', // ใช้ชื่อหมวดหมู่หรือข้อความเริ่มต้น
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
                              //_showRadiusSelectionDialog(point);
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
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('category') // ดึง category
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return const Center(
                                      child: Text('Error fetching categories'));
                                }

                                List<Marker> redMarkers = [];
                                if (snapshot.hasData) {
                                  var categories = snapshot.data!.docs;
                                  for (var categoryDoc in categories) {
                                    String categoryId = categoryDoc.id;

                                    // แปลง categoryDoc.data() เป็น Map<String, dynamic> แล้วดึง 'name'
                                    Map<String, dynamic> categoryData =
                                        categoryDoc.data()
                                            as Map<String, dynamic>;

                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                            .instance.currentUser!.uid)
                                        .collection('category')
                                        .doc(categoryId)
                                        .collection('location')
                                        .get()
                                        .then((locationSnapshot) {
                                      for (var locationDoc
                                          in locationSnapshot.docs) {
                                        Map<String, dynamic> locationData =
                                            locationDoc.data();

                                        double latitude =
                                            locationData['latitude'];
                                        double longitude =
                                            locationData['longitude'];

                                        int iconCode = categoryData[
                                            'icon']; // ดึง icon จาก categoryData

                                        // แปลง icon code เป็น IconData
                                        IconData markerIcon = IconData(iconCode,
                                            fontFamily: 'MaterialIcons');

                                        LatLng redMarkerPosition =
                                            LatLng(latitude, longitude);

                                        // สร้าง Marker สำหรับหมุดสีแดง
                                        redMarkers.add(Marker(
                                          point: redMarkerPosition,
                                          width: 40.0,
                                          height: 40.0,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                markerIcon, // ใช้ไอคอนที่ได้จากข้อมูล
                                                color: Colors
                                                    .black, // ใช้สีที่ได้จากข้อมูล
                                                size: 40.0,
                                              ),
                                            ],
                                          ),
                                        ));
                                      }
                                    });
                                  }
                                }

                                return MarkerLayer(markers: redMarkers);
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
