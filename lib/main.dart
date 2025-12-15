import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart'; 
import 'features/driver/tracking/gps_background_service.dart'; // ✅ NEW IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ INITIALIZE BACKGROUND SERVICE HERE
  await GpsBackgroundService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Ride',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: AppTheme.lightTheme, // APPLY NEW THEME
    );
  }
}