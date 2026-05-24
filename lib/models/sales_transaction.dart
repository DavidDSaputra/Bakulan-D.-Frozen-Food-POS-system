import 'package:cloud_firestore/cloud_firestore.dart';

class SalesTransaction {
  const SalesTransaction({
    required this.id,
    required this.tanggal,
    required this.namaBarang,
    required this.qty,
    required this.totalHarga,
    required this.metodePembayaran,
    required this.idUser,
  });

  final String id;
  final DateTime tanggal;
  final String namaBarang;
  final int qty;
  final int totalHarga;
  final String metodePembayaran;
  final String idUser;

  factory SalesTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDate = data['tanggal'];
    return SalesTransaction(
      id: doc.id,
      tanggal: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      namaBarang: data['nama_barang']?.toString() ?? '-',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      totalHarga: (data['total_harga'] as num?)?.toInt() ?? 0,
      metodePembayaran: data['metode_pembayaran']?.toString() ?? '-',
      idUser: data['id_user']?.toString() ?? '-',
    );
  }
}
