import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../common/services/notification_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final NotificationService _notifications = NotificationService();
  final int _loginTime = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    
    // ✅ PASS THE NAVIGATION FUNCTION HERE
    _notifications.init((response) {
      if (response.payload != null) {
        context.push(response.payload!); // Go to '/admin-notifications'
      }
    });

    _listenForAlerts();
  }

  void _listenForAlerts() {
    FirebaseDatabase.instance.ref('alerts').onChildAdded.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      final int timestamp = data['timestamp'] ?? 0;
      final String type = data['type'] ?? 'INFO';
      final String busId = data['busId'] ?? 'Unknown';
      final String msg = data['message'] ?? 'Check dashboard';

      if (timestamp > _loginTime) {
        if (type == 'SOS') {
          _notifications.showSOSNotification(busId, "EMERGENCY: $msg");
        } else if (type == 'SPEED') {
          _notifications.showSOSNotification(busId, "Speed Alert: $msg");
        }
      }
    });
  }

  // 🔒 UNIFIED LOGOUT LOGIC
  // This is now used by BOTH the Back Button and the Logout Icon
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Do you want to logout from Admin Console?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Stay
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Logout
            child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/role-selection'); // Go explicitly to role selection
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ POPSCOPE: Prevents App from closing on Back Press
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLogout(); // <--- Trigger Dialog on Back Press
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text("Admin Console", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, 
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active, color: Colors.redAccent),
              onPressed: () => context.push('/admin-notifications'),
              tooltip: "Safety Alerts",
            ),
            
            // ✅ LOGOUT ICON NOW ASKS FOR CONFIRMATION
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black54),
              onPressed: () {
                _confirmLogout(); // <--- Trigger Dialog on Icon Click
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard("Total Buses", "Active", Colors.blue),
              const SizedBox(height: 20),
              Text("Quick Actions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              _buildActionTile(
                context, 
                icon: Icons.directions_bus, 
                color: Colors.purple, 
                title: "Manage Fleet", 
                subtitle: "Add buses & auto-generate routes",
                path: '/admin-manage-buses'
              ),
              
              _buildActionTile(
                context, 
                icon: Icons.person_add, 
                color: Colors.orange, 
                title: "Approve Drivers", 
                subtitle: "Verify new registrations",
                path: '/admin-manage-drivers'
              ),

              _buildActionTile(
                context, 
                icon: Icons.warning_amber_rounded, 
                color: Colors.redAccent, 
                title: "Safety Alerts", 
                subtitle: "View SOS & Speed logs",
                path: '/admin-notifications'
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 5),
              Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(Icons.analytics, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required String path}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => context.push(path),
      ),
    );
  }
}