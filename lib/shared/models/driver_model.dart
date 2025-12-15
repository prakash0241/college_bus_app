import 'package:equatable/equatable.dart';

class DriverModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String contactNumber;
  final String licenseNumber;
  final String busId;
  final bool isApproved;

  const DriverModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.licenseNumber,
    required this.busId,
    this.isApproved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'contactNumber': contactNumber,
      'licenseNumber': licenseNumber,
      'busId': busId,
      'isApproved': isApproved,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      busId: map['busId'] ?? '',
      isApproved: map['isApproved'] ?? false,
    );
  }

  @override
  List<Object?> get props => [uid, busId, isApproved];
}
