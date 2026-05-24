import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, kasir }

class AppUser {
  const AppUser({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
  });

  final String id;
  final String nama;
  final String username;
  final UserRole role;

  bool get isOwner => role == UserRole.owner;
  bool get isKasir => role == UserRole.kasir;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      nama: data['nama']?.toString() ?? '-',
      username: data['username']?.toString() ?? '-',
      role: _roleFromText(data['role']?.toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {'nama': nama, 'username': username, 'role': role.name};
  }

  static UserRole _roleFromText(String? role) {
    return role?.toLowerCase() == 'owner' ? UserRole.owner : UserRole.kasir;
  }
}
