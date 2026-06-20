import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String note;
  final bool isActive;

  factory Supplier.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Supplier(
      id: doc.id,
      name: data['name']?.toString() ?? '-',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
      isActive: data['is_active'] is bool ? data['is_active'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_lower': name.trim().toLowerCase(),
      'phone': phone,
      'address': address,
      'note': note,
      'is_active': isActive,
    };
  }
}
