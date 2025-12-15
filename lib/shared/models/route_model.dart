import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel extends Equatable {
  final String routeId;
  final String name; // e.g., "Gajuwaka to College"
  final String startPoint;
  final String endPoint;
  final String polyline; // Encoded Google Maps polyline
  final List<String> stopNames;
  final List<LatLng> stopCoordinates;

  const RouteModel({
    required this.routeId,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.polyline,
    required this.stopNames,
    required this.stopCoordinates,
  });

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'name': name,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'polyline': polyline,
      'stopNames': stopNames,
      'stopCoordinates': stopCoordinates.map((c) => '${c.latitude},${c.longitude}').toList(),
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      routeId: map['routeId'] ?? '',
      name: map['name'] ?? '',
      startPoint: map['startPoint'] ?? '',
      endPoint: map['endPoint'] ?? '',
      polyline: map['polyline'] ?? '',
      stopNames: List<String>.from(map['stopNames'] ?? []),
      stopCoordinates: (map['stopCoordinates'] as List<dynamic>? ?? [])
          .map((s) {
            final parts = s.toString().split(',');
            return (parts.length == 2) 
              ? LatLng(double.parse(parts[0]), double.parse(parts[1])) 
              : const LatLng(0, 0);
          })
          .toList(),
    );
  }

  @override
  List<Object?> get props => [routeId, name];
}
