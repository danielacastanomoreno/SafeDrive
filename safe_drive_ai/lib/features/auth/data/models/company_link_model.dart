import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/company_link_entity.dart';

class CompanyLinkModel extends CompanyLinkEntity {
  const CompanyLinkModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    required super.driverId,
    required super.cargo,
    required super.phone,
    required super.status,
    required super.linkedAt,
    super.unlinkedAt,
  });

  factory CompanyLinkModel.fromMap(
    String id,
    Map<String, dynamic> map,
    String companyName,
  ) {
    return CompanyLinkModel(
      id: id,
      companyId: map['companyId'] as String,
      companyName: companyName,
      driverId: map['driverId'] as String,
      cargo: map['cargo'] as String,
      phone: map['phone'] as String,
      status: (map['status'] as String) == 'active'
          ? LinkStatus.active
          : LinkStatus.inactive,
      linkedAt: (map['linkedAt'] as Timestamp).toDate(),
      unlinkedAt: map['unlinkedAt'] != null
          ? (map['unlinkedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'driverId': driverId,
      'cargo': cargo,
      'phone': phone,
      'status': status == LinkStatus.active ? 'active' : 'inactive',
      'linkedAt': FieldValue.serverTimestamp(),
      'unlinkedAt': unlinkedAt != null ? Timestamp.fromDate(unlinkedAt!) : null,
    };
  }
}
