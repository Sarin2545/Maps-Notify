import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as location;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:location/location.dart';

class MapsCategory extends StatefulWidget {
  const MapsCategory({super.key});

  @override
  State<MapsCategory> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsCategory> {
  LatLng? _userLocation;
  location.Location _location = location.Location();
  late MapController _mapController;
  
  LatLng? _markerPosition;
  String? categoryId;
  double _radius = 100; // รัศมีเริ่มต้นในหน่วยเมตร
  double _zoomLevel = 13.0; // ระดับซูมเริ่มต้น

  @override
  void initState() {
    super.initState();
    _mapController = MapController(); // สร้าง MapController ใน initState
    _startLocationTracking();
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

    _location.onLocationChanged.listen((location.LocationData currentLocation) {
      setState(() {
        _userLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
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
        title: const Text(
          'แผนที่กิจกรรม',
          style: TextStyle(color: Colors.white),
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
                                      color: Colors.red,
                                      size: 40.0,
                                    ),
                                  ),
                              ],
                            ),
                            if (categoryId != null)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
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
                                  List<Marker> savedMarkers =
                                      locations.map((doc) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    LatLng position = LatLng(
                                        data['latitude'], data['longitude']);
                                    return Marker(
                                      point: position,
                                      width: 40.0,
                                      height: 40.0,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40.0,
                                      ),
                                    );
                                  }).toList();

                                  return MarkerLayer(markers: savedMarkers);
                                },
                              ),
                            if (_markerPosition != null)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _markerPosition!,
                                    radius: _calculatePixelRadius(
                                        _radius, _zoomLevel),
                                    color: Colors.red.withOpacity(0.5),
                                    borderStrokeWidth: 2,
                                    borderColor: Colors.red,
                                  ),
                                ],
                              ),
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