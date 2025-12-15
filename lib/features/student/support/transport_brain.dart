import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_database/firebase_database.dart';

class TransportBrain {
  static const String _apiKey = "AIzaSyCO0eGIP0KL5Lo9vceI85Jb7ncjvNOe8xk"; 
  
  late final GenerativeModel _model;
  final DatabaseReference _db = FirebaseDatabase.instance.ref('buses');

  TransportBrain() {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  Future<Map<dynamic, dynamic>> _getRawData() async {
    try {
      final snapshot = await _db.get();
      if (!snapshot.exists) return {};
      return snapshot.value as Map<dynamic, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<String> askAI(String userQuestion) async {
    final rawData = await _getRawData();
    
    // BUILD ADVANCED CONTEXT
    String contextString = "REAL-TIME FLEET STATUS:\n";
    if (rawData.isEmpty) {
      contextString += "System Alert: All buses are currently offline or parked.\n";
    } else {
      rawData.forEach((key, value) {
        final route = value['routeName'] ?? 'Unknown Route';
        final status = value['isActive'] == true ? "ACTIVE (Moving)" : "OFFLINE (Parked)";
        final crowd = value['crowdDensity'] ?? "Unknown";
        // We add "Lat/Lng" so the AI knows where they are roughly
        final loc = value['location']; 
        String locationHint = "";
        if (loc != null) locationHint = "at GPS coordinates ${loc['latitude']},${loc['longitude']}";

        contextString += "- Bus ID: $key | Route: $route | Status: $status | Crowd: $crowd | Location: $locationHint.\n";
      });
    }

    try {
      // ADVANCED PROMPT
      final prompt = '''
      You are "CampusBot", the advanced AI Transport Manager for the University.
      
      Here is the LIVE DATA from the GPS tracking system:
      $contextString

      USER QUESTION: "$userQuestion"

      YOUR MISSION:
      1. Answer like a helpful human assistant. Be friendly but professional.
      2. USE THE LIVE DATA. If a bus is "ACTIVE", tell the student it is running.
      3. If the user asks about a location, check the Route Name or GPS hint.
      4. If the user asks about "Safety" or "Drivers", assure them the system is monitored by Admin.
      5. Keep answers short (under 2 sentences) so they can be spoken out loud easily.
      ''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }
      throw Exception("No response");

    } catch (e) {
      // Fallback
      return _localSmartResponse(userQuestion, rawData);
    }
  }

  String _localSmartResponse(String question, Map<dynamic, dynamic> data) {
    final lowerQ = question.toLowerCase();
    for (var key in data.keys) {
      String busName = key.toString();
      if (lowerQ.contains(busName.toLowerCase()) || lowerQ.contains(busName.split('_').last)) {
        final bus = data[key];
        final route = bus['routeName'] ?? "Unknown";
        final status = bus['isActive'] == true ? "RUNNING" : "STOPPED";
        return "$busName is currently $status on the $route route.";
      }
    }
    return "I am tracking ${data.length} buses. Please ask specifically about a bus number.";
  }
}