import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart'; 
import 'route_service.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final RouteService _service = RouteService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _magicRouteController = TextEditingController();
  
  static const CameraPosition _initialPos = CameraPosition(target: LatLng(13.6288, 79.4192), zoom: 10);
  
  GoogleMapController? _mapController;
  final List<LatLng> _points = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;

  Future<void> _generateRouteFromText() async {
    final input = _magicRouteController.text; 
    if (input.isEmpty) return;
    
    Navigator.pop(context); 
    setState(() => _isLoading = true);
    
    List<String> stopNames = input.split(RegExp(r'[-–,>]')).map((s) => s.trim()).toList();
    List<LatLng> newPoints = [];
    
    for (String name in stopNames) {
      if (name.isEmpty) continue;
      try {
        print("🔍 Searching for: $name"); // Debug Print
        List<Location> locations = await locationFromAddress(name);
        
        if (locations.isNotEmpty) {
          print("✅ Found: ${locations.first.latitude}, ${locations.first.longitude}");
          newPoints.add(LatLng(locations.first.latitude, locations.first.longitude));
        } else {
          print("❌ No location found for $name");
        }
      } catch (e) {
        print("⚠️ Geocoding Error for $name: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text("Error finding '$name'. Check API Key or Internet."),
             backgroundColor: Colors.red,
           ));
        }
      }
    }

    if (newPoints.isEmpty) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No valid locations found.")));
      return;
    }

    setState(() {
      _points.clear();
      _points.addAll(newPoints);
      _updateMapVisuals();
      _isLoading = false;
    });

    if (_points.isNotEmpty && _mapController != null) {
      LatLngBounds bounds = _boundsFromLatLngList(_points);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void _showMagicDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Auto-Route Generator"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter stops separated by '-'"),
            const SizedBox(height: 10),
            TextField(
              controller: _magicRouteController,
              decoration: const InputDecoration(
                hintText: "Puttur - Tirupati - Tirumala",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton.icon(
            onPressed: _generateRouteFromText,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Generate"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() => _points.add(pos));
    _updateMapVisuals();
  }

  void _undoLast() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
        _updateMapVisuals();
      });
    }
  }

  void _updateMapVisuals() {
    _markers.clear();
    _polylines.clear();

    for (int i = 0; i < _points.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId("stop_$i"),
        position: _points[i],
        draggable: true,
        onDragEnd: (newPos) {
          setState(() {
            _points[i] = newPos;
            _updateMapVisuals(); 
          });
        },
        infoWindow: InfoWindow(title: "Stop ${i + 1}"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    if (_points.length > 1) {
      _polylines.add(Polyline(
        polylineId: const PolylineId("route_line"),
        points: _points,
        color: Colors.blueAccent,
        width: 5,
      ));
    }
  }

  Future<void> _saveRoute() async {
    if (_nameController.text.isEmpty || _points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter name and at least 2 stops.")));
      return;
    }
    String id = "ROUTE_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    await _service.saveRoute(routeId: id, routeName: _nameController.text.trim(), points: _points);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Route Saved Successfully!")));
      context.pop(); 
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Draw New Route"), actions: [
        IconButton(icon: const Icon(Icons.undo), onPressed: _undoLast),
        IconButton(icon: const Icon(Icons.save), onPressed: _saveRoute),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Route Name", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _showMagicDialog,
                  icon: const Icon(Icons.auto_awesome),
                  style: IconButton.styleFrom(backgroundColor: Colors.purple),
                  tooltip: "Auto-Generate from Text",
                )
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),

          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPos,
              onMapCreated: (c) => _mapController = c,
              onTap: _onMapTap,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}