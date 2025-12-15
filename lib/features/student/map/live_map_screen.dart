import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/utils/eta_calculator.dart';
import '../../common/services/language_service.dart';
import '../../common/services/safety_service.dart'; // IMPORT SAFETY
import '../tracking/geofence_service.dart'; 

class LiveMapScreen extends StatefulWidget {
  final String busId;
  const LiveMapScreen({super.key, required this.busId});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final LanguageService _lang = LanguageService();
  final GeofenceService _geofence = GeofenceService();
  final SafetyService _safety = SafetyService(); // NEW
  
  final Completer<GoogleMapController> _controller = Completer();
  late DatabaseReference _busRef;
  
  static const CameraPosition _initialPosition = CameraPosition(target: LatLng(13.6288, 79.4192), zoom: 10);

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; 
  BitmapDescriptor? _busIcon;
  
  String _crowdStatus = "Unknown";
  bool _isBusActive = false;
  String _distanceText = "--";
  String _timeText = "--";
  int _minutes = 0;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _busRef = FirebaseDatabase.instance.ref('buses/${widget.busId}');
    _generateBusIcon();
    _getUserLocation(); 
    _listenToBusData();
  }

  // --- SOS TRIGGER ---
  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("TRIGGER SOS?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("This will alert the Admin immediately.\nOnly use in emergencies."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _safety.triggerSOS(busId: widget.busId, reason: "Student reported emergency");
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SOS ALERT SENT!"), backgroundColor: Colors.red));
            },
            child: const Text("SEND ALERT"),
          )
        ],
      ),
    );
  }
  // -------------------

  Future<void> _fetchSpecificRoute(String routeId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('routes').doc(routeId).get();
      if (doc.exists && doc.data() != null) _drawRouteOnMap(doc.data()!);
    } catch (e) { print(e); }
  }

  void _drawRouteOnMap(Map<String, dynamic> routeData) {
    List<dynamic> stops = routeData['stops'] ?? [];
    List<LatLng> points = stops.map((s) => LatLng(s['lat'], s['lng'])).toList();
    if (points.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(polylineId: const PolylineId('dynamic_route'), color: Colors.blueAccent, width: 5, points: points));
      for (int i = 0; i < points.length; i++) {
        _markers.add(Marker(markerId: MarkerId('stop_$i'), position: points[i], icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: InfoWindow(title: "Stop ${i+1}")));
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller.isCompleted) {
        _controller.future.then((c) => c.animateCamera(CameraUpdate.newLatLngBounds(_boundsFromLatLngList(points), 50)));
      }
    });
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0, x1, y0, y1;
    x0 = x1 = list.first.latitude;
    y0 = y1 = list.first.longitude;
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  Future<void> _getUserLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
    } catch (e) { print(e); }
  }

  Future<void> _generateBusIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(const Offset(50, 50), 50, paint);
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(text: String.fromCharCode(Icons.directions_bus.codePoint), style: TextStyle(fontSize: 60, fontFamily: Icons.directions_bus.fontFamily, color: Colors.white));
    painter.layout();
    painter.paint(canvas, const Offset(20, 20));
    final ui.Image img = await pictureRecorder.endRecording().toImage(100, 100);
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data != null) setState(() => _busIcon = BitmapDescriptor.fromBytes(data.buffer.asUint8List()));
  }

  void _listenToBusData() {
    _busRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      final routeId = data['routeId'];
      if (routeId != null && _polylines.isEmpty) _fetchSpecificRoute(routeId);
      final location = data['location'] as Map?;
      final isActive = data['isActive'] as bool? ?? false;
      final crowd = data['crowdDensity'] as String? ?? "Unknown";

      if (location != null) {
        final double lat = (location['latitude'] as num).toDouble();
        final double lng = (location['longitude'] as num).toDouble();
        final LatLng busPos = LatLng(lat, lng);
        _updateBusMarker(busPos, crowd);
        if (_myLocation != null) {
          double dist = ETACalculator.calculateDistance(_myLocation!, busPos);
          int time = ETACalculator.calculateTime(dist);
          _geofence.checkProximity(_myLocation!, busPos, widget.busId);
          if (mounted) setState(() { _distanceText = "${dist.toStringAsFixed(1)} ${_lang.get('km')}"; _timeText = "$time ${_lang.get('mins')}"; _minutes = time; });
        }
        if (mounted) setState(() { _isBusActive = isActive; _crowdStatus = crowd; });
      }
    });
  }

  void _updateBusMarker(LatLng pos, String crowd) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == widget.busId);
      _markers.add(Marker(markerId: MarkerId(widget.busId), position: pos, icon: _busIcon ?? BitmapDescriptor.defaultMarker, infoWindow: InfoWindow(title: widget.busId), zIndex: 2));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.busId), 
        backgroundColor: _isBusActive ? Colors.blue : Colors.grey,
        // SOS BUTTON IN APP BAR
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.red, size: 30),
            onPressed: _triggerSOS,
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines, 
            myLocationEnabled: true, 
            onMapCreated: (c) => _controller.complete(c),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Card(
              color: Colors.white, elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _isBusActive ? Colors.blue.shade50 : Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.directions_bus, color: _isBusActive ? Colors.blue : Colors.red, size: 35)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_lang.get(_isBusActive ? "Arriving in" : "Bus is Offline"), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _isBusActive ? Colors.grey : Colors.red)),
                          if (_isBusActive) Text("$_timeText ($_distanceText)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
                          Row(children: [const Icon(Icons.groups, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("${_lang.get('Crowd')}: ${_lang.get(_crowdStatus)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))]),
                        ],
                      ),
                    ),
                    if (_isBusActive) IconButton(icon: const Icon(Icons.volume_up, size: 30, color: Colors.blueAccent), onPressed: () => _lang.announceETA(widget.busId, _minutes)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}