import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Wait a bit for the animation to play (Premium feel)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        // --- USER IS LOGGED IN ---
        // Fetch their role from Firestore to know where to send them
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            final role = doc.data()?['role'];
            
            if (role == 'admin') {
              context.go('/admin-dashboard');
            } else if (role == 'driver') {
              context.go('/driver-dashboard');
            } else {
              // Fallback for students or unknown roles
              context.go('/student-home');
            }
          } else {
            // User exists in Auth but not in DB? Go to selection
            context.go('/role-selection');
          }
        } catch (e) {
          // If error (offline/etc), go to selection safely
          context.go('/role-selection');
        }
      } else {
        // --- NO USER ---
        // Go to the Role Selection Screen
        context.go('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO ANIMATION
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_bus_filled_rounded, size: 80, color: Color(0xFF2962FF)),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 20),
            
            Text(
              "Campus Ride",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 10),
            
            const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2962FF))
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}