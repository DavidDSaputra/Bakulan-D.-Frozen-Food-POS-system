import 'package:cloud_firestore/cloud_firestore.dart';

enum StockMovementType { masuk, keluar }

enum StockMovementSource { restock, sale, opname }

class StockMovement {
  const StockMovement({
    required this.id,
    required this.tanggal,
    required this.namaBarang,
    required this.qty,
    required this.type,
    required this.userId,
    this.note = '',
    this.source = StockMovementSource.sale,
    this.proofUrl = '',
  });

  final String id;
  final DateTime tanggal;
  final String namaBarang;
  final int qty;
  final StockMovementType type;
  final String userId;
  final String note;
  final StockMovementSource source;
  final String proofUrl;

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
      note: data['keterangan']?.toString() ?? '',
      source: StockMovementSource.restock,
      proofUrl: data['proof_url']?.toString() ?? '',
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
      note: data['keterangan']?.toString() ?? '',
      source: StockMovementSource.sale,
      proofUrl: data['proof_url']?.toString() ?? '',
    );
  }

  factory StockMovement.fromOpnameDoc(
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
      note: data['keterangan']?.toString() ?? '',
      source: StockMovementSource.opname,
      proofUrl: data['proof_url']?.toString() ?? '',
    );
  }
}
