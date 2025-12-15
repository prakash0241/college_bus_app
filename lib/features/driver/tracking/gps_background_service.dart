import 'dart:async';
import 'dart:ui'; // Required for DartPluginRegistrant
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart'; // ✅ ADDED for Database updates
import 'realtime_database_service.dart';
import 'offline_buffer_service.dart';

class GpsBackgroundService {
  // Singleton Pattern
  static final GpsBackgroundService _instance = GpsBackgroundService._internal();
  factory GpsBackgroundService() => _instance;
  GpsBackgroundService._internal();

  // Callback for UI to show speed warning
  Function(double speed)? onSpeedUpdate;

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // 1. Setup Notification Channel (Required for Foreground Service)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bus_tracking_channel', 
      'Bus Tracking Service',
      description: 'Used to track bus location in background',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Configure Service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, // The Background Function
        autoStart: false,
        isForegroundMode: true, // KEEPS APP ALIVE
        notificationChannelId: 'bus_tracking_channel',
        initialNotificationTitle: 'Campus Ride',
        initialNotificationContent: 'GPS Tracking Active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  Future<void> startTracking(String busId) async {
    final service = FlutterBackgroundService();
    
    // Check Permissions first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (!(await service.isRunning())) {
      await service.startService();
    }

    // Send the BusID to the background worker
    service.invoke("set_bus_id", {"busId": busId});

    // Listen for speed updates FROM background TO UI
    FlutterBackgroundService().on('speed_update').listen((event) {
      if (event != null && onSpeedUpdate != null) {
        onSpeedUpdate!(event['speed']);
      }
    });
  }

  Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("stop_service");
    }
  }
}

// ---------------------------------------------------------------------------
// 🔒 BACKGROUND WORKER (Runs separately from the App)
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. Initialize Firebase & Services in Background
  DartPluginRegistrant.ensureInitialized(); // ✅ Essential for background services
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Re-create instances for the background thread
  final RealtimeDatabaseService dbService = RealtimeDatabaseService();
  final OfflineBufferService bufferService = OfflineBufferService();
  
  // We don't need localNotificationsPlugin here anymore because 
  // we use service.setForegroundNotificationInfo for the main notification.

  String currentBusId = "BUS_UNKNOWN";
  StreamSubscription<Position>? positionStream;

  // 2. Listen for "Start" command
  service.on('set_bus_id').listen((event) {
    if (event != null) {
      currentBusId = event['busId'];
      
      // ✅ UPDATE NOTIFICATION (Make it Clickable)
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Trip Active",
          content: "Tracking Bus: $currentBusId (Tap to Open)",
        );
      }
    }
  });

  // 3. Listen for "Stop" command
  service.on('stop_service').listen((event) async {
    // A. Stop GPS Stream
    await positionStream?.cancel();
    positionStream = null;

    // B. Update Firebase to INACTIVE (So Student App stops searching)
    if (currentBusId != "BUS_UNKNOWN") {
       try {
         final ref = FirebaseDatabase.instance.ref('buses/$currentBusId');
         await ref.update({
           'status': 'INACTIVE',
           'isActive': false,
           'speed': 0,
         });
       } catch (e) {
         print("Error updating DB on stop: $e");
       }
    }

    // C. Kill Service & Notification
    service.stopSelf();
  });

  // 4. START GEOLOCATOR STREAM (Your Original Settings)
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10, 
  );

  positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) async {
        
    if (currentBusId == "BUS_UNKNOWN") return;

    double speedKmph = (position.speed * 3.6); 
    if (speedKmph < 0) speedKmph = 0;

    // Send Speed back to Main UI
    service.invoke('speed_update', {'speed': speedKmph});

    // --- YOUR EXACT LOGIC BELOW ---

    // Check Connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = false;
    if (connectivityResult is List<ConnectivityResult>) {
      isOnline = !connectivityResult.contains(ConnectivityResult.none);
    } else {
      isOnline = connectivityResult != ConnectivityResult.none;
    }

    if (isOnline) {
      // First, sync any old data
      await bufferService.syncBuffer();
      
      // Send current data
      dbService.updateBusLocation(currentBusId, position.latitude, position.longitude, true);
      
      // Log Overspeed Event
      if (speedKmph > 60) {
          print("🚨 OVERSPEED DETECTED: ${speedKmph.toStringAsFixed(1)} km/h");
      }
    } else {
      // Buffer data locally
      bufferService.bufferLocation(currentBusId, position.latitude, position.longitude, speedKmph);
    }
  });
}