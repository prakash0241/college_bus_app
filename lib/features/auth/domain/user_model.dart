import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student', 'driver', 'admin'
  final bool isApproved;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isApproved = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      isApproved: data['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isApproved': isApproved,
    };
  }

  @override
  List<Object?> get props => [uid, email, role, isApproved];
}