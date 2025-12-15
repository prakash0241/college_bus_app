import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class OverspeedMonitor {
  static const double speedLimitKmph = 60.0;
  static const double speedLimitMps = speedLimitKmph / 3.6; // 60 km/h = 16.67 m/s

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final String busId;

  OverspeedMonitor({required this.busId});

  bool checkSpeed(Position position) {
    // position.speed is in meters per second (m/s)
    if (position.speed > speedLimitMps) {
      _logOverspeedEvent(position);
      return true;
    }
    return false;
  }

  void _logOverspeedEvent(Position position) {
    final ref = _db.ref('overspeed_logs/$busId/${DateTime.now().millisecondsSinceEpoch}');
    ref.set({
      'speed_mps': position.speed,
      'speed_kmph': position.speed * 3.6,
      'limit_kmph': speedLimitKmph,
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': ServerValue.timestamp,
    });
    // Admin notification trigger would be added here via Cloud Functions later
  }
}
