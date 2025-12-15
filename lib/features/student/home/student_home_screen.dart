import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/services/language_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final LanguageService _lang = LanguageService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  
  // Placeholder data for Route & Time (Static info)
  final Map<String, Map<String, String>> _busDetails = {
    "BUS_101": {"route": "Gajuwaka - College", "time": "07:30 AM"},
    "BUS_202": {"route": "NAD - Complex - College", "time": "07:45 AM"},
    "BUS_303": {"route": "MVP Colony - Beach Road", "time": "08:00 AM"},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_lang.get("Select Your Bus"), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // LANGUAGE TOGGLE
          TextButton.icon(
            onPressed: () => setState(() => _lang.toggleLanguage()),
            icon: const Icon(Icons.translate, color: Colors.blueAccent),
            label: Text(_lang.isTelugu ? "తెలుగు" : "ENG", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ),
          // LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              context.go('/role-selection');
            },
          ),
        ],
      ),
      
      // AI CHAT BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ai-chat'),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: _lang.get("Search by Bus or Route"),
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // LIVE LIST
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('buses').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If no data, show empty message
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text(_lang.get("No buses found")));
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final List<Map<String, dynamic>> busList = [];

                data.forEach((key, value) {
                  // 1. MERGE STATIC DETAILS (Route/Time)
                  final details = _busDetails[key] ?? {"route": "Unknown Route", "time": "--:--"};
                  
                  // 2. GET DYNAMIC STATUS (From Driver)
                  // My Driver code sends "status": "ACTIVE".
                  final String status = value['status'] ?? 'INACTIVE';
                  final bool isActive = status == 'ACTIVE';

                  final searchContent = "$key ${details['route']}".toLowerCase();

                  // 3. FILTER & ADD
                  if (_searchText.isEmpty || searchContent.contains(_searchText)) {
                    busList.add({
                      'id': key,
                      'isActive': isActive, // ✅ Correct Boolean Logic
                      'crowd': value['crowdDensity'] ?? 'Normal',
                      'route': details['route'],
                      'time': details['time'],
                    });
                  }
                });

                if (busList.isEmpty) return Center(child: Text(_lang.get("No buses found")));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: busList.length,
                  itemBuilder: (context, index) => _buildBusCard(busList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    final bool isActive = bus['isActive'];
    // Green if Active, Grey if Offline
    final Color statusColor = isActive ? Colors.green : Colors.grey;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        // Only allow clicking if Bus is Active (Optional, or allow always to see offline map)
        onTap: isActive ? () => context.push('/student-map/${bus['id']}') : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ICON
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle), 
                child: Icon(Icons.directions_bus, color: statusColor, size: 32)
              ),
              const SizedBox(width: 16),
              
              // INFO COLUMN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus['id'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(bus['route'], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(bus['time'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(width: 10),
                        
                        // STATUS BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)), 
                          child: Text(
                            _lang.get(isActive ? "Active" : "Offline"), 
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ARROW (Only if active)
              if (isActive)
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}