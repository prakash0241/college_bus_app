import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Update Bus Location
  Future<void> updateBusLocation(String busId, double lat, double lng, bool isActive) async {
    try {
      await _db.child('buses/$busId').update({
        'location': {
          'latitude': lat,
          'longitude': lng,
        },
        'isActive': isActive,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  // Update Crowd Density
  Future<void> updateCrowdDensity(String busId, String level) async {
    try {
      await _db.child('buses/$busId').update({
        'crowdDensity': level, // 'LOW', 'MEDIUM', 'HIGH'
      });
    } catch (e) {
      print("Error updating crowd: $e");
    }
  }
}