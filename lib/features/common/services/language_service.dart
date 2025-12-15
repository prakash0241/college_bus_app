import 'package:flutter_tts/flutter_tts.dart';

class LanguageService {
  final FlutterTts _flutterTts = FlutterTts();
  bool isTelugu = false;

  LanguageService() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setPitch(1.0);
  }

  void toggleLanguage() {
    isTelugu = !isTelugu;
    _flutterTts.setLanguage(isTelugu ? "te-IN" : "en-US");
  }

  String get(String key) {
    if (!isTelugu) return key; 
    
    // Simple Dictionary
    final Map<String, String> teluguDict = {
      "Select Your Bus": "మీ బస్సును ఎంచుకోండి",
      "Search by Bus or Route": "బస్సు లేదా రూట్ ద్వారా శోధించండి",
      "Arriving in": "వచ్చే సమయం",
      "Bus is Offline": "బస్సు ఆఫ్‌లైన్‌లో ఉంది",
      "mins": "నిమిషాలు",
      "km": "కి.మీ",
      "Crowd": "రద్దీ",
      "Low": "తక్కువ",
      "Medium": "మధ్యస్థ",
      "High": "ఎక్కువ",
      "Active": "యాక్టివ్",
      "Offline": "ఆఫ్‌లైన్",
      "No buses found": "బస్సులు కనపడలేదు"
    };
    return teluguDict[key] ?? key;
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // ✅ NEW: STOP FUNCTION
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> announceETA(String busId, int minutes) async {
    if (isTelugu) {
      await speak("గమనించండి. బస్సు $busId $minutes నిమిషాల్లో వస్తుంది.");
    } else {
      await speak("Attention please. Bus $busId is arriving in $minutes minutes.");
    }
  }
}