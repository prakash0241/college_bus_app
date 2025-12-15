import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // SAVE A NEW ROUTE
  Future<void> saveRoute({
    required String routeId,
    required String routeName,
    required List<LatLng> points,
  }) async {
    // Convert LatLng objects to simple Map list for Firestore
    List<Map<String, double>> coordinates = points.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude
    }).toList();

    await _db.collection('routes').doc(routeId).set({
      'name': routeName,
      'stops': coordinates,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // DELETE ROUTE
  Future<void> deleteRoute(String routeId) async {
    await _db.collection('routes').doc(routeId).delete();
  }
}