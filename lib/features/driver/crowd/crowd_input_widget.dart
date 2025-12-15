import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CrowdStatus { low, medium, high, standing }

class CrowdInputWidget extends ConsumerWidget {
  final String busId = 'bus_001'; // Will be dynamic after login integration

  const CrowdInputWidget({super.key});

  Color _getStatusColor(CrowdStatus status) {
    switch (status) {
      case CrowdStatus.low:
        return Colors.green;
      case CrowdStatus.medium:
        return Colors.amber;
      case CrowdStatus.high:
        return Colors.red;
      case CrowdStatus.standing:
        return Colors.purple;
    }
  }

  Future<void> _updateCrowdStatus(CrowdStatus status) async {
    final ref = FirebaseDatabase.instance.ref('active_trips/$busId/crowd_status');
    await ref.set({
      'status': status.name,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Crowd Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: CrowdStatus.values.length,
              itemBuilder: (context, index) {
                final status = CrowdStatus.values[index];
                return InkWell(
                  onTap: () => _updateCrowdStatus(status),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == CrowdStatus.standing ? Icons.people_alt : Icons.person,
                          color: _getStatusColor(status),
                          size: 30,
                        ),
                        Text(
                          status.name.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: _getStatusColor(status)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
