import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'fleet_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageFleetScreen extends StatefulWidget {
  const ManageFleetScreen({super.key});

  @override
  State<ManageFleetScreen> createState() => _ManageFleetScreenState();
}

class _ManageFleetScreenState extends State<ManageFleetScreen> {
  final FleetService _service = FleetService();
  bool _isGenerating = false;

  void _showAddDialog() {
    final busController = TextEditingController();
    final routeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Bus & Route"),
            scrollable: true, // <--- 1. ALLOW SCROLLING
            content: SingleChildScrollView( // <--- 2. WRAP CONTENT
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("The app will auto-generate the map path based on the cities you enter."),
                  const SizedBox(height: 15),
                  TextField(
                    controller: busController,
                    decoration: const InputDecoration(
                      labelText: "Bus Number",
                      hintText: "e.g., BUS_505",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_bus),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: routeController,
                    decoration: const InputDecoration(
                      labelText: "Route Path (Cities)",
                      hintText: "e.g., Puttur - Tirupati - Renigunta",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                  if (_isGenerating) 
                    const Padding(
                      padding: EdgeInsets.only(top: 15.0),
                      child: LinearProgressIndicator(),
                    ),
                  if (_isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text("Generating Route Map... Please wait.", style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            actions: [
              if (!_isGenerating)
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              if (!_isGenerating)
                ElevatedButton(
                  onPressed: () async {
                    if (busController.text.isEmpty || routeController.text.isEmpty) return;
                    
                    setDialogState(() => _isGenerating = true);

                    // Close keyboard to prevent glitches
                    FocusScope.of(context).unfocus(); 

                    String result = await _service.addBusWithRoute(
                      busNumber: busController.text.trim(),
                      routeString: routeController.text.trim(),
                    );

                    setDialogState(() => _isGenerating = false);
                    Navigator.pop(ctx);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result == "Success" ? "Bus & Route Created!" : result),
                        backgroundColor: result == "Success" ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  child: const Text("Auto-Generate & Save"),
                )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fleet Manager", style: GoogleFonts.poppins())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("Add Bus"),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('buses').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No buses found. Add one to start!"));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> busList = [];

          data.forEach((key, value) {
            busList.add({
              'id': key,
              'route': value['routeName'] ?? 'Unknown Route',
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
                  leading: CircleAvatar(
                    backgroundColor: bus['status'] ? Colors.green : Colors.grey,
                    child: const Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  title: Text(bus['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(bus['route']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _service.deleteBus(bus['id']),
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