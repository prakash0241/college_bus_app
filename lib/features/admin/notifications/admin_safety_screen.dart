import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For time formatting
import '../../common/services/safety_service.dart';

class AdminSafetyScreen extends StatefulWidget {
  const AdminSafetyScreen({super.key});

  @override
  State<AdminSafetyScreen> createState() => _AdminSafetyScreenState();
}

class _AdminSafetyScreenState extends State<AdminSafetyScreen> {
  final SafetyService _service = SafetyService();

  String _formatTime(int timestamp) {
    return DateFormat('hh:mm a, dd MMM').format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Safety Command Center", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('alerts').orderByChild('timestamp').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No Active Alerts. All Safe."));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> alerts = [];

          data.forEach((key, value) {
            alerts.add({
              'id': key,
              'type': value['type'] ?? 'UNKNOWN',
              'busId': value['busId'] ?? 'Unknown Bus',
              'message': value['message'] ?? '',
              'time': value['timestamp'] ?? 0,
              'resolved': value['isResolved'] ?? false,
            });
          });

          // Sort newest first
          alerts.sort((a, b) => b['time'].compareTo(a['time']));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (ctx, i) {
              final alert = alerts[i];
              final isSOS = alert['type'] == 'SOS';
              final isResolved = alert['resolved'];

              return Card(
                color: isResolved ? Colors.grey[200] : (isSOS ? Colors.red[50] : Colors.orange[50]),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isResolved ? Colors.grey : (isSOS ? Colors.red : Colors.orange),
                    child: Icon(isSOS ? Icons.warning : Icons.speed, color: Colors.white),
                  ),
                  title: Text(
                    "${alert['type']}: ${alert['busId']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert['message']),
                      Text(_formatTime(alert['time']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: isResolved 
                    ? IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _service.deleteAlert(alert['id']))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _service.resolveAlert(alert['id']),
                        child: const Text("Resolve"),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}