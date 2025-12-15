import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'realtime_database_service.dart';

class OfflineBufferService {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  static const String _bufferKey = 'gps_buffer';

  // 1. Save Point Locally (When Offline)
  Future<void> bufferLocation(String busId, double lat, double lng, double speed) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> buffer = prefs.getStringList(_bufferKey) ?? [];
    
    final point = jsonEncode({
      'busId': busId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    
    buffer.add(point);
    await prefs.setStringList(_bufferKey, buffer);
    print("⚠️ Offline: Buffered point. Total: ${buffer.length}");
  }

  // 2. Sync Buffered Points (When Online)
  Future<void> syncBuffer() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> buffer = prefs.getStringList(_bufferKey) ?? [];
    
    if (buffer.isEmpty) return;

    print("🔄 Syncing ${buffer.length} offline points...");

    for (String pointJson in buffer) {
      final data = jsonDecode(pointJson);
      // Upload old points
      await _dbService.updateBusLocation(
        data['busId'], 
        data['lat'], 
        data['lng'], 
        true, // assuming active during trip
      );
      // Wait slightly to prevent flooding
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Clear buffer after sync
    await prefs.remove(_bufferKey);
    print("✅ Sync Complete.");
  }
}