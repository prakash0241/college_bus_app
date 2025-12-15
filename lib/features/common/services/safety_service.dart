import 'package:firebase_database/firebase_database.dart';

class SafetyService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('alerts');

  // 1. SEND SOS (Student)
  Future<void> triggerSOS({required String busId, required String reason}) async {
    final newAlert = _db.push();
    await newAlert.set({
      'type': 'SOS',
      'busId': busId,
      'message': reason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isResolved': false,
    });
  }

  // 2. LOG OVERSPEEDING (Driver)
  Future<void> logOverspeed({required String busId, required double speed}) async {
    final newAlert = _db.push();
    await newAlert.set({
      'type': 'SPEED',
      'busId': busId,
      'message': 'Overspeeding: ${speed.toStringAsFixed(1)} km/h',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isResolved': false,
    });
  }

  // 3. RESOLVE ALERT (Admin)
  Future<void> resolveAlert(String alertId) async {
    await _db.child(alertId).update({'isResolved': true});
  }
  
  // 4. DELETE ALERT
  Future<void> deleteAlert(String alertId) async {
    await _db.child(alertId).remove();
  }
}