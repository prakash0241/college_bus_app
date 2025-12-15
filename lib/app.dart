import 'package:flutter/material.dart';
import 'config/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class CollegeBusApp extends StatelessWidget {
  const CollegeBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "College Transport",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
