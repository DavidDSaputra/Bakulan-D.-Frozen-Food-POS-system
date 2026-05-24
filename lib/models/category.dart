import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  const ProductCategory({required this.id, required this.namaKategori});

  final String id;
  final String namaKategori;

  factory ProductCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProductCategory(
      id: doc.id,
      namaKategori: data['nama_kategori']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toMap() => {'nama_kategori': namaKategori};
}
