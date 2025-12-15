import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BACKGROUND: Pure White (Apple Style Cleanliness)
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      
                      // HEADER: High Contrast Black on White
                      Text(
                        "Welcome to\nCampus Ride",
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.black, // Maximum Contrast
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                      
                      const SizedBox(height: 10),
                      
                      Text(
                        "Select your portal to continue",
                        style: GoogleFonts.poppins(
                          fontSize: 17, 
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 50),

                      // 1. STUDENT CARD (Multi-Color: Ocean Blue Gradient)
                      _AppleGradientCard(
                        title: "Student",
                        subtitle: "No Login Required",
                        icon: Icons.school_rounded,
                        // Apple Style Gradient: Blue to Light Blue
                        gradientColors: const [Color(0xFF007AFF), Color(0xFF00C6FF)],
                        shadowColor: const Color(0xFF007AFF),
                        delay: 400,
                        onTap: () => context.push('/student-home'),
                      ),

                      const SizedBox(height: 24),

                      // 2. DRIVER CARD (Multi-Color: Sunset Gradient)
                      _AppleGradientCard(
                        title: "Driver",
                        subtitle: "Login to Start Trip",
                        icon: Icons.directions_bus_filled_rounded,
                        // Apple Style Gradient: Orange to Red
                        gradientColors: const [Color(0xFFFF9500), Color(0xFFFF3B30)],
                        shadowColor: const Color(0xFFFF9500),
                        delay: 600,
                        onTap: () => context.push('/login?role=driver'),
                      ),

                      const SizedBox(height: 24),

                      // 3. ADMIN CARD (Multi-Color: Royal Gradient)
                      _AppleGradientCard(
                        title: "Admin",
                        subtitle: "Full Control Panel",
                        icon: Icons.admin_panel_settings_rounded,
                        // Apple Style Gradient: Purple to Violet
                        gradientColors: const [Color(0xFFAF52DE), Color(0xFF5856D6)],
                        shadowColor: const Color(0xFFAF52DE),
                        delay: 800,
                        onTap: () => context.push('/login?role=admin'),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}

class _AppleGradientCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color shadowColor;
  final int delay;
  final VoidCallback onTap;

  const _AppleGradientCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.shadowColor,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_AppleGradientCard> createState() => _AppleGradientCardState();
}

class _AppleGradientCardState extends State<_AppleGradientCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () async {
        // Quick visual feedback before navigation
        await Future.delayed(const Duration(milliseconds: 100));
        widget.onTap();
      },
      child: AnimatedScale(
        // THE ANIMATION: Scale down (Spring Effect) when pressed
        scale: _isPressed ? 0.96 : 1.0, 
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 115,
          decoration: BoxDecoration(
            // MULTI-COLOR GRADIENT
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            // GLOWING SHADOW (Attractive)
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              // Inner light reflection for "Glassy" feel top-left
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                offset: const Offset(-1, -1),
                blurRadius: 0,
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    // ICON CONTAINER
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 30),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // TEXT
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title, 
                            style: GoogleFonts.poppins(
                              fontSize: 21, 
                              fontWeight: FontWeight.w700, 
                              color: Colors.white,
                              letterSpacing: 0.3
                            )
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle, 
                            style: GoogleFonts.poppins(
                              fontSize: 13, 
                              color: Colors.white.withOpacity(0.9), 
                              fontWeight: FontWeight.w500
                            )
                          ),
                        ],
                      ),
                    ),
                    
                    // ARROW
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded, 
                        color: Colors.white, 
                        size: 16
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(delay: widget.delay.ms)
    .slideX(begin: 0.1, end: 0, curve: Curves.easeOutBack);
  }
}