import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.cedula,
    required super.email,
    required super.role,
    required super.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] as String,
      cedula: map['cedula'] as String,
      email: map['email'] as String,
      role: (map['role'] as String) == 'driver'
          ? UserRole.driver
          : UserRole.company,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cedula': cedula,
      'email': email,
      'role': role == UserRole.driver ? 'driver' : 'company',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
