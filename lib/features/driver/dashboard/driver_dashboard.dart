import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ADDED FOR PERSISTENCE
import '../../auth/domain/auth_service.dart';
import '../tracking/gps_background_service.dart';
import '../tracking/realtime_database_service.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final GpsBackgroundService _gpsService = GpsBackgroundService();
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  
  bool _isTripActive = false;
  bool _isLoading = true;
  String? _assignedBusId;
  String _driverName = "";
  double _currentSpeed = 0.0;
  bool _isOverspeeding = false;
  bool _isPlayingSiren = false;

  @override
  void initState() {
    super.initState();
    _fetchDriverProfile();
    _loadTripState(); // ✅ RESTORE TRIP STATE ON APP START
    _sirenPlayer.setReleaseMode(ReleaseMode.loop);

    _gpsService.onSpeedUpdate = (speed) {
      if (!mounted) return;
      setState(() {
        _currentSpeed = speed;
        if (speed > 60.0 && !_isPlayingSiren) {
          _startSiren();
        } else if (speed <= 60.0 && _isPlayingSiren) {
          _stopSiren();
        }
        _isOverspeeding = speed > 60.0;
      });
    };
  }

  // ✅ LOGIC: LOAD SAVED STATE
  Future<void> _loadTripState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isTripActive = prefs.getBool('is_trip_active') ?? false;
      });
      
      // If trip was active, ensure tracking resumes (optional, depending on your background service)
      if (_isTripActive && _assignedBusId != null) {
         _gpsService.startTracking(_assignedBusId!);
      }
    }
  }

  @override
  void dispose() {
    _sirenPlayer.stop();
    _sirenPlayer.dispose();
    super.dispose();
  }

  Future<void> _startSiren() async {
    setState(() => _isPlayingSiren = true);
    await _sirenPlayer.play(UrlSource('https://www.soundjay.com/mechanical/sounds/smoke-detector-1.mp3'));
  }

  Future<void> _stopSiren() async {
    setState(() => _isPlayingSiren = false);
    await _sirenPlayer.stop();
  }

  Future<void> _fetchDriverProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _driverName = data['name'] ?? "Driver";
          _assignedBusId = data['busId']; 
          _isLoading = false;
        });
        // Re-check tracking if bus ID loaded late
        if (_isTripActive && _assignedBusId != null) {
           _gpsService.startTracking(_assignedBusId!);
        }
      }
    }
  }

  void _toggleTrip() async {
    if (_assignedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No Bus Assigned!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isTripActive = !_isTripActive);

    // ✅ LOGIC: SAVE STATE TO MEMORY
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_trip_active', _isTripActive);

    if (_isTripActive) {
      await _gpsService.startTracking(_assignedBusId!);
    } else {
      await _gpsService.stopTracking();
      _dbService.updateBusLocation(_assignedBusId!, 0, 0, false);
      _stopSiren(); 
      setState(() { _currentSpeed = 0; _isOverspeeding = false; });
    }
  }

  // ✅ LOGIC: SECURE LOGOUT & BACK BUTTON
  Future<void> _handleLogout() async {
    // 1. Prevent logout if trip is running (Safety First)
    if (_isTripActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please END the trip before logging out!"), 
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Show Confirmation Dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Are you sure you want to end your shift?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // 3. Clear Trip State
      if (_isTripActive) _gpsService.stopTracking();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_trip_active', false);

      // 4. Sign Out and Go Home
      await AuthService().signOut(); 
      if (mounted) context.go('/role-selection');
    }
  }

  void _updateCrowd(String level) {
    if (!_isTripActive || _assignedBusId == null) return;
    _dbService.updateCrowdDensity(_assignedBusId!, level);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Crowd set to $level"), duration: 500.ms));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_assignedBusId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              Text("Account Pending", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Admin has not assigned a bus to you yet."),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => AuthService().signOut(), child: const Text("Logout"))
            ],
          ),
        ),
      );
    }

    // ✅ POPSCOPE: INTERCEPT BACK BUTTON
    return PopScope(
      canPop: false, // Don't close app automatically
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLogout(); // Show logout dialog instead
      },
      child: Scaffold(
        backgroundColor: _isOverspeeding ? Colors.red : Colors.white,
        appBar: AppBar(
          title: Column(
            children: [
              Text('$_driverName', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Bus: $_assignedBusId', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
            ],
          ),
          centerTitle: true,
          backgroundColor: _isOverspeeding ? Colors.red[900] : const Color(0xFF00BFA6),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // ✅ Hide default back button
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout, // ✅ Use new secure logout logic
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // FIXED BANNER (Using FittedBox to prevent pixel overflow)
              if (_isOverspeeding)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: FittedBox( 
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 40),
                        const SizedBox(width: 10),
                        Text("DANGER! SLOW DOWN!", style: GoogleFonts.blackOpsOne(color: Colors.red, fontSize: 24)),
                      ],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shake(),

              // SPEEDOMETER
              Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isOverspeeding ? Colors.white : const Color(0xFF00BFA6),
                    width: 10,
                  ),
                  color: _isOverspeeding ? Colors.redAccent : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 5)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentSpeed.toStringAsFixed(0),
                      style: GoogleFonts.oswald(
                        fontSize: 70, 
                        fontWeight: FontWeight.bold, 
                        color: _isOverspeeding ? Colors.white : Colors.black87
                      ),
                    ),
                    Text("km/h", style: GoogleFonts.poppins(fontSize: 18, color: _isOverspeeding ? Colors.white70 : Colors.grey)),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // START/STOP BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _toggleTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTripActive ? Colors.red[800] : const Color(0xFF00BFA6),
                    elevation: 10,
                  ),
                  child: Text(
                    _isTripActive ? "END TRIP" : "START TRIP",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              Text("Update Crowd Status", style: TextStyle(fontWeight: FontWeight.bold, color: _isOverspeeding ? Colors.white : Colors.grey)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _crowdBtn("LOW", Colors.green),
                  const SizedBox(width: 8),
                  _crowdBtn("MEDIUM", Colors.orange),
                  const SizedBox(width: 8),
                  _crowdBtn("HIGH", Colors.red[800]!),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _crowdBtn("STANDING ONLY", Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crowdBtn(String label, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _updateCrowd(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ),
    );
  }
}