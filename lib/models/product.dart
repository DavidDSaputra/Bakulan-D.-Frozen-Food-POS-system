import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.namaBarang,
    required this.harga,
    required this.stok,
    required this.kategoriId,
    this.imageUrl = '',
  });

  final String id;
  final String namaBarang;
  final int harga;
  final int stok;
  final String kategoriId;
  final String imageUrl;

  bool get isOutOfStock => stok <= 0;
  bool get isLowStock => stok > 0 && stok <= 5;

  Product copyWith({
    String? id,
    String? namaBarang,
    int? harga,
    int? stok,
    String? kategoriId,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      namaBarang: namaBarang ?? this.namaBarang,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      kategoriId: kategoriId ?? this.kategoriId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      namaBarang: data['nama_barang']?.toString() ?? '-',
      harga: (data['harga'] as num?)?.toInt() ?? 0,
      stok: (data['stok'] as num?)?.toInt() ?? 0,
      kategoriId: data['kategori_id']?.toString() ?? '',
      imageUrl: data['image_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_barang': namaBarang,
      'harga': harga,
      'stok': stok,
      'kategori_id': kategoriId,
      'image_url': imageUrl,
    };
  }
}
