import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // ✅ MODIFIED: Accepts a function to run when clicked
  Future<void> init(Function(NotificationResponse) onNotificationClick) async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);

    // ✅ ADDED: onDidReceiveNotificationResponse handles the click
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationClick, 
    );
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Safety Alerts',
      description: 'This channel is used for important SOS notifications.',
      importance: Importance.max,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showSOSNotification(String busId, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Safety Alerts',
      channelDescription: 'SOS Alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF0000),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '🚨 SOS ALERT: $busId',
      message,
      details,
      payload: '/admin-notifications', // ✅ This path is passed when clicked
    );
  }
}