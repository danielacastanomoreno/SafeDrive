import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/company_entity.dart';
import '../../domain/entities/user_entity.dart';

class CompanyModel extends CompanyEntity {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.nit,
    required super.email,
    required super.representativeName,
    required super.role,
    required super.createdAt,
  });

  factory CompanyModel.fromMap(String id, Map<String, dynamic> map) {
    return CompanyModel(
      id: id,
      name: map['name'] as String,
      nit: map['nit'] as String,
      email: map['email'] as String,
      representativeName: map['representativeName'] as String,
      role: (map['role'] as String) == 'driver'
          ? UserRole.driver
          : UserRole.company,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nit': nit,
      'email': email,
      'representativeName': representativeName,
      'role': role == UserRole.driver ? 'driver' : 'company',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
