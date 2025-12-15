import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'bus_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({super.key});

  @override
  State<ManageBusesScreen> createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  final BusService _busService = BusService();

  void _showAddDialog() {
    final busNumController = TextEditingController();
    final routeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Bus"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: busNumController, decoration: const InputDecoration(labelText: "Bus ID (e.g., BUS_55)")),
            TextField(controller: routeController, decoration: const InputDecoration(labelText: "Route Name (e.g., Beach Road)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (busNumController.text.isNotEmpty) {
                _busService.addBus(busNumController.text.trim(), routeController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add Bus"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fleet Management", style: GoogleFonts.poppins())),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('buses').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No buses in fleet. Add one!"));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> busList = [];

          data.forEach((key, value) {
            busList.add({
              'id': key,
              'route': value['route'] ?? 'Unknown Route',
              'status': value['isActive'] ?? false,
            });
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: busList.length,
            itemBuilder: (ctx, i) {
              final bus = busList[i];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.directions_bus, color: Colors.white)),
                  title: Text(bus['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(bus['route']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _busService.deleteBus(bus['id']),
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