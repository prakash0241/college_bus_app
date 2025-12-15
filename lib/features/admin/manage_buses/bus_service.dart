import 'package:firebase_database/firebase_database.dart';

class BusService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('buses');

  Future<void> addBus(String busNumber, String routeName) async {
    await _db.child(busNumber).set({
      'route': routeName,
      'isActive': false,
      'crowdDensity': 'Unknown',
      'location': {'latitude': 0.0, 'longitude': 0.0},
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteBus(String busNumber) async {
    await _db.child(busNumber).remove();
  }
}