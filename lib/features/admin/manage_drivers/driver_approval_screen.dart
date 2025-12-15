import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/domain/user_model.dart'; // Ensure this path is correct for your structure

class DriverApprovalScreen extends StatefulWidget {
  const DriverApprovalScreen({super.key});

  @override
  State<DriverApprovalScreen> createState() => _DriverApprovalScreenState();
}

class _DriverApprovalScreenState extends State<DriverApprovalScreen> {
  // Show a dialog to assign a Bus ID before approving
  void _showApproveDialog(String uid, String currentName) {
    final TextEditingController busIdController = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text("Approve $currentName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Assign a Bus ID to this driver:"),
            const SizedBox(height: 10),
            TextField(
              controller: busIdController,
              decoration: const InputDecoration(
                labelText: "Bus ID (e.g., BUS_101)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () {
              if (busIdController.text.isNotEmpty) {
                _approveDriver(uid, busIdController.text.trim());
                Navigator.pop(context);
              }
            }, 
            child: const Text("Approve & Assign")
          ),
        ],
      )
    );
  }

  Future<void> _approveDriver(String uid, String busId) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isApproved': true,
      'busId': busId, // SAVE THE ASSIGNED BUS ID
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Driver approved for $busId"))
    );
  }

  Future<void> _rejectDriver(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Approvals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No pending approvals."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final uid = docs[i].id;
              final name = data['name'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Text(data['email'] ?? 'No Email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _showApproveDialog(uid, name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectDriver(uid),
                      ),
                    ],
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