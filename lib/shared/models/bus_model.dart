import 'package:equatable/equatable.dart';

class BusModel extends Equatable {
  final String busId;
  final String busNumber; // e.g., "AP 16 Z 1234"
  final String routeId;
  final String routeName;
  final String driverId; // Link to Driver
  final int capacity;
  final bool isActive;

  const BusModel({
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.driverId,
    required this.capacity,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'busNumber': busNumber,
      'routeId': routeId,
      'routeName': routeName,
      'driverId': driverId,
      'capacity': capacity,
      'isActive': isActive,
    };
  }

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      busId: map['busId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      driverId: map['driverId'] ?? '',
      capacity: map['capacity'] ?? 0,
      isActive: map['isActive'] ?? false,
    );
  }

  @override
  List<Object?> get props => [busId, busNumber, driverId, isActive];
}
