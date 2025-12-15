import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ETACalculator {
  // 1. Calculate Distance (in Kilometers)
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radius of Earth in km
    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLon = _toRadians(point2.longitude - point1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(point1.latitude)) *
            cos(_toRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // 2. Calculate Time (Minutes)
  // We assume an average bus speed of 30 km/h in city traffic
  static int calculateTime(double distanceKm) {
    const double speedKmH = 30.0; 
    final double hours = distanceKm / speedKmH;
    return (hours * 60).round(); // Convert to minutes
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}