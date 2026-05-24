import 'package:cloud_firestore/cloud_firestore.dart';

enum StockMovementType { masuk, keluar }

class StockMovement {
  const StockMovement({
    required this.id,
    required this.tanggal,
    required this.namaBarang,
    required this.qty,
    required this.type,
    required this.userId,
  });

  final String id;
  final DateTime tanggal;
  final String namaBarang;
  final int qty;
  final StockMovementType type;
  final String userId;

  factory StockMovement.fromRestockDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawDate = data['tanggal'];
    return StockMovement(
      id: doc.id,
      tanggal: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      namaBarang: data['nama_barang']?.toString() ?? '-',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      type: StockMovementType.masuk,
      userId: data['id_user']?.toString() ?? '-',
    );
  }

  factory StockMovement.fromSalesDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawDate = data['tanggal'];
    return StockMovement(
      id: doc.id,
      tanggal: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      namaBarang: data['nama_barang']?.toString() ?? '-',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      type: StockMovementType.keluar,
      userId: data['id_user']?.toString() ?? '-',
    );
  }
}
