import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  // 1. Stream position for Driver (sending)
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // 2. Driver sends location
  Future<void> updateBusLocation(String busId, Position position, double heading) async {
    final ref = _db.ref('bus_locations/$busId');
    await ref.set({
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': position.speed,
      'heading': heading,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 3. Student listens to ONE bus
  Stream<DatabaseEvent> getBusLocationStream(String busId) {
    return _db.ref('bus_locations/$busId').onValue;
  }

  // 4. Student listens to ALL buses (NEW)
  Stream<DatabaseEvent> getAllBusLocationsStream() {
    return _db.ref('bus_locations').onValue;
  }
}
