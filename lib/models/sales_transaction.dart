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
    this.namaUser = '-',
    this.barangId = '',
    this.invoiceId = '',
    this.invoiceCode = '',
    this.hargaBeli = 0,
    this.hargaJual = 0,
    this.laba = 0,
    this.returnedQty = 0,
    this.itemStatus = 'completed',
    this.paymentProofUrl,
    this.paymentAccountName,
    this.paymentAccountNumber,
    this.paymentStatus,
  });

  final String id;
  final DateTime tanggal;
  final String barangId;
  final String invoiceId;
  final String invoiceCode;
  final String namaBarang;
  final int qty;
  final int hargaBeli;
  final int hargaJual;
  final int totalHarga;
  final int laba;
  final int returnedQty;
  final String itemStatus;
  final String metodePembayaran;
  final String idUser;
  final String namaUser;
  final String? paymentProofUrl;
  final String? paymentAccountName;
  final String? paymentAccountNumber;
  final String? paymentStatus;

  int get effectiveLaba {
    if (laba != 0) return laba;
    if (hargaBeli <= 0 || hargaJual <= 0 || qty <= 0) return 0;
    return (hargaJual - hargaBeli) * qty;
  }

  int get remainingQty => qty - returnedQty;
  bool get isFullyReturned => remainingQty <= 0;

  factory SalesTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDate = data['tanggal'];
    final qty = (data['qty'] as num?)?.toInt() ?? 0;
    final hargaBeli = (data['harga_beli'] as num?)?.toInt() ?? 0;
    final hargaJual =
        (data['harga_jual'] as num?)?.toInt() ??
        _safeUnitPrice(data['total_harga'], data['qty']);
    final storedLaba = (data['laba'] as num?)?.toInt();
    return SalesTransaction(
      id: doc.id,
      tanggal: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      barangId: data['barang_id']?.toString() ?? '',
      invoiceId: data['invoice_id']?.toString() ?? '',
      invoiceCode: data['invoice_code']?.toString() ?? '',
      namaBarang: data['nama_barang']?.toString() ?? '-',
      qty: qty,
      hargaBeli: hargaBeli,
      hargaJual: hargaJual,
      totalHarga: (data['total_harga'] as num?)?.toInt() ?? 0,
      laba:
          storedLaba ??
          ((hargaJual > 0 && hargaBeli > 0 && qty > 0)
              ? (hargaJual - hargaBeli) * qty
              : 0),
      metodePembayaran: data['metode_pembayaran']?.toString() ?? '-',
      returnedQty: (data['returned_qty'] as num?)?.toInt() ?? 0,
      itemStatus: data['item_status']?.toString() ?? 'completed',
      idUser:
          data['id_kasir']?.toString() ?? data['id_user']?.toString() ?? '-',
      namaUser:
          data['nama_kasir']?.toString() ??
          data['nama_user']?.toString() ??
          '-',
      paymentProofUrl: data['payment_proof_url']?.toString(),
      paymentAccountName: data['payment_account_name']?.toString(),
      paymentAccountNumber: data['payment_account_number']?.toString(),
      paymentStatus: data['payment_status']?.toString(),
    );
  }

  static int _safeUnitPrice(Object? total, Object? qty) {
    final totalHarga = (total as num?)?.toInt() ?? 0;
    final quantity = (qty as num?)?.toInt() ?? 0;
    if (quantity <= 0) return 0;
    return totalHarga ~/ quantity;
  }
}
