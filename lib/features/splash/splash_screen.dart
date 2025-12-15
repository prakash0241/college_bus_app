import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../shared/animations/bus_loader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading time (3 seconds) then navigate to role selection
    Future.delayed(3.seconds, () {
      if (mounted) {
        context.go('/'); // FIX: Navigating to the stable root path '/'
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00BFA6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BusLoaderAnimation()
             .animate()
             .scale(duration: 800.ms, curve: Curves.elasticOut)
             .fadeIn(duration: 500.ms),
            
            const SizedBox(height: 30),

            Text(
              'CAMPUS GO', 
              style: GoogleFonts.blackOpsOne(
                fontSize: 32, 
                color: Colors.white, 
                letterSpacing: 2
              ),
            )
            .animate()
            .slideY(begin: 0.5, end: 0, duration: 800.ms)
            .fadeIn(),

            const SizedBox(height: 10),
            
            Text(
              'Live Tracker',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 50),
            
            const CircularProgressIndicator(color: Colors.white).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}