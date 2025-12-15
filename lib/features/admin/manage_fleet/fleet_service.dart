import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FleetService {
  final DatabaseReference _busRef = FirebaseDatabase.instance.ref('buses');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FREE COORDINATE FINDER (OSM) ---
  Future<LatLng?> _getCoordinates(String cityName) async {
    try {
      final query = Uri.encodeComponent(cityName);
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1");
      final response = await http.get(url, headers: {"User-Agent": "CollegeBusApp/1.0"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        }
      }
    } catch (e) {
      print("OSM Error: $e");
    }
    return null;
  }

  // --- MAIN FUNCTION: ADD BUS & GENERATE ROUTE ---
  Future<String> addBusWithRoute({
    required String busNumber,
    required String routeString, // e.g. "Puttur - Tirupati"
  }) async {
    try {
      // 1. GENERATE ROUTE POINTS
      List<String> stops = routeString.split(RegExp(r'[-–,>]')).map((s) => s.trim()).toList();
      List<Map<String, double>> routePoints = [];

      for (String stop in stops) {
        if (stop.isEmpty) continue;
        LatLng? pos = await _getCoordinates(stop);
        if (pos != null) {
          routePoints.add({'lat': pos.latitude, 'lng': pos.longitude});
        }
      }

      if (routePoints.length < 2) {
        return "Error: Could not find enough valid locations. Check spelling.";
      }

      // 2. SAVE ROUTE TO FIRESTORE
      // We use the Bus Number to ID the route (e.g., ROUTE_BUS_505)
      String routeId = "ROUTE_$busNumber";
      await _firestore.collection('routes').doc(routeId).set({
        'name': routeString,
        'stops': routePoints,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 3. SAVE BUS TO REALTIME DB
      await _busRef.child(busNumber).set({
        'routeId': routeId, // Link to the route we just made
        'routeName': routeString,
        'isActive': false,
        'crowdDensity': 'Unknown',
        'location': {'latitude': 0.0, 'longitude': 0.0},
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      return "Success";
    } catch (e) {
      return "Error: $e";
    }
  }

  // DELETE BUS & ROUTE
  Future<void> deleteBus(String busNumber) async {
    await _busRef.child(busNumber).remove(); // Delete Bus
    await _firestore.collection('routes').doc("ROUTE_$busNumber").delete(); // Delete Route
  }
}