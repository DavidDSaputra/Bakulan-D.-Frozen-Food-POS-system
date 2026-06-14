import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.namaBarang,
    required this.harga,
    required this.stok,
    required this.kategoriId,
    this.hargaBeli = 0,
    this.imageUrl = '',
    this.isActive = true,
    this.barcode = '',
    this.description = '',
    this.expirationDate,
  });

  final String id;
  final String namaBarang;
  final int hargaBeli;
  final int harga;
  final int stok;
  final String kategoriId;
  final String imageUrl;
  final bool isActive;
  final String barcode;
  final String description;
  final DateTime? expirationDate;

  int get hargaJual => harga;
  int get margin => hargaJual - hargaBeli;
  bool get isOutOfStock => stok <= 0;
  bool get isLowStock => stok > 0 && stok <= 5;

  Product copyWith({
    String? id,
    String? namaBarang,
    int? hargaBeli,
    int? harga,
    int? hargaJual,
    int? stok,
    String? kategoriId,
    String? imageUrl,
    bool? isActive,
    String? barcode,
    String? description,
    DateTime? expirationDate,
  }) {
    return Product(
      id: id ?? this.id,
      namaBarang: namaBarang ?? this.namaBarang,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      harga: hargaJual ?? harga ?? this.harga,
      stok: stok ?? this.stok,
      kategoriId: kategoriId ?? this.kategoriId,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final legacyHarga = (data['harga'] as num?)?.toInt() ?? 0;
    final hargaJual =
        (data['harga_jual'] as num?)?.toInt() ??
        (data['harga'] as num?)?.toInt() ??
        0;
    final rawExpirationDate =
        data['expired_date'] ??
        data['expiration_date'] ??
        data['tanggal_expired'];
    return Product(
      id: doc.id,
      namaBarang: data['nama_barang']?.toString() ?? '-',
      hargaBeli: (data['harga_beli'] as num?)?.toInt() ?? legacyHarga,
      harga: hargaJual,
      stok: (data['stok'] as num?)?.toInt() ?? 0,
      kategoriId: data['kategori_id']?.toString() ?? '',
      imageUrl: data['image_url']?.toString() ?? '',
      isActive: data['is_active'] is bool ? data['is_active'] as bool : true,
      barcode: data['barcode']?.toString() ?? '',
      description: data['deskripsi']?.toString() ?? '',
      expirationDate: _readDate(rawExpirationDate),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_barang': namaBarang,
      'harga': hargaJual,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'stok': stok,
      'kategori_id': kategoriId,
      'image_url': imageUrl,
      'is_active': isActive,
      'barcode': barcode,
      'deskripsi': description,
      'expired_date': expirationDate == null
          ? null
          : Timestamp.fromDate(expirationDate!),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
