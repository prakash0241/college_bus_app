import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../common/services/language_service.dart';

class GeofenceService {
  final LanguageService _lang = LanguageService();
  bool _alerted2km = false;
  bool _alerted500m = false;

  void checkProximity(LatLng userPos, LatLng busPos, String busId) {
    double distanceInMeters = Geolocator.distanceBetween(
      userPos.latitude, userPos.longitude,
      busPos.latitude, busPos.longitude,
    );

    // ZONE 1: 2 KM AWAY (Warning)
    if (distanceInMeters < 2000 && distanceInMeters > 500 && !_alerted2km) {
      _triggerAlert(busId, "approaching_2km");
      _alerted2km = true; 
    }

    // ZONE 2: 500 M AWAY (Arrival)
    if (distanceInMeters < 500 && !_alerted500m) {
      _triggerAlert(busId, "arriving_now");
      _alerted500m = true;
    }

    // RESET if bus moves far away (e.g., next trip)
    if (distanceInMeters > 5000) {
      _alerted2km = false;
      _alerted500m = false;
    }
  }

  Future<void> _triggerAlert(String busId, String type) async {
    if (type == "approaching_2km") {
      if (_lang.isTelugu) {
        await _lang.speak("గమనించండి. బస్సు $busId రెండు కిలోమీటర్ల దూరంలో ఉంది.");
      } else {
        await _lang.speak("Attention. Bus $busId is within 2 kilometers.");
      }
    } else if (type == "arriving_now") {
      if (_lang.isTelugu) {
        await _lang.speak("బస్సు వస్తోంది. దయచేసి సిద్ధంగా ఉండండి.");
      } else {
        await _lang.speak("Bus is arriving now. Please get ready.");
      }
    }
  }
}