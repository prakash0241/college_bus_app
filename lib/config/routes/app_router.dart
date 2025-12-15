import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/common/presentation/role_selection_screen.dart';
import '../../features/common/presentation/splash_screen.dart'; // ✅ FIXED IMPORT
import '../../features/student/home/student_home_screen.dart';
import '../../features/driver/dashboard/driver_dashboard.dart';
import '../../features/admin/dashboard/admin_dashboard.dart';
import '../../features/admin/manage_drivers/driver_approval_screen.dart';
import '../../features/student/map/live_map_screen.dart';
import '../../features/admin/manage_fleet/manage_fleet_screen.dart';
import '../../features/student/support/ai_chat_screen.dart'; 
import '../../features/admin/notifications/admin_safety_screen.dart';

class AppRouter {
  static final AuthNotifier authNotifier = AuthNotifier();

  static final router = GoRouter(
    initialLocation: '/', // ✅ START AT SPLASH SCREEN
    refreshListenable: authNotifier,
    routes: [
      // 1. SPLASH SCREEN (ROOT)
      // Checks login status and redirects accordingly
      GoRoute(
        path: '/', 
        builder: (context, state) => const SplashScreen()
      ),

      // 2. ROLE SELECTION (Explicit Path)
      // Splash screen sends users here if they are NOT logged in
      GoRoute(
        path: '/role-selection', 
        builder: (context, state) => const RoleSelectionScreen()
      ),
      
      // --- EXISTING ROUTES (KEPT 100% SAME) ---
      
      GoRoute(path: '/login', builder: (c, s) => LoginScreen(role: s.uri.queryParameters['role'])),
      GoRoute(path: '/signup', builder: (c, s) => const SignUpScreen()),
      GoRoute(path: '/student-home', builder: (c, s) => const StudentHomeScreen()),
      GoRoute(path: '/ai-chat', builder: (c, s) => const AiChatScreen()),

      GoRoute(path: '/driver-dashboard', builder: (c, s) => const DriverDashboard()),
      GoRoute(path: '/admin-dashboard', builder: (c, s) => const AdminDashboard()),
      GoRoute(path: '/admin-manage-drivers', builder: (c, s) => const DriverApprovalScreen()),
      GoRoute(path: '/admin-manage-buses', builder: (c, s) => const ManageFleetScreen()),
      
      // SAFETY SCREEN
      GoRoute(path: '/admin-notifications', builder: (c, s) => const AdminSafetyScreen()),

      GoRoute(
        path: '/student-map/:busId',
        builder: (context, state) {
          final busId = state.pathParameters['busId'] ?? 'BUS_101';
          return LiveMapScreen(busId: busId);
        },
      ),
      
      GoRoute(path: '/admin-map', builder: (c, s) => const Scaffold(body: Center(child: Text("Live Map")))),
      GoRoute(path: '/admin-analytics', builder: (c, s) => const Scaffold(body: Center(child: Text("Analytics")))),
    ],
    
    // REDIRECT LOGIC
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final path = state.uri.path;
      
      // If user is trying to access protected Admin/Driver routes without login
      if ((path.startsWith('/driver') || path.startsWith('/admin')) && user == null) {
        return '/role-selection'; // ✅ Redirect to Role Selection (not Splash, to avoid loop)
      }
      return null;
    },
  );
}