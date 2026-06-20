import 'package:cloud_firestore/cloud_firestore.dart';

class SalesInvoice {
  const SalesInvoice({
    required this.id,
    required this.invoiceCode,
    required this.tanggal,
    required this.totalQty,
    required this.totalHarga,
    required this.metodePembayaran,
    required this.idUser,
    required this.namaUser,
    this.status = 'completed',
    this.shiftId = '',
    this.paymentProofUrl,
    this.paymentAccountName,
    this.paymentAccountNumber,
    this.paymentStatus,
    this.returnedQty = 0,
    this.returnedAmount = 0,
  });

  final String id;
  final String invoiceCode;
  final DateTime tanggal;
  final int totalQty;
  final int totalHarga;
  final String metodePembayaran;
  final String idUser;
  final String namaUser;
  final String status;
  final String shiftId;
  final String? paymentProofUrl;
  final String? paymentAccountName;
  final String? paymentAccountNumber;
  final String? paymentStatus;
  final int returnedQty;
  final int returnedAmount;

  bool get isCancelled => status == 'cancelled';
  bool get isReturned => status == 'returned';
  bool get isPartiallyReturned => status == 'partial_return';

  factory SalesInvoice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDate = data['tanggal'];
    return SalesInvoice(
      id: doc.id,
      invoiceCode: data['invoice_code']?.toString() ?? doc.id,
      tanggal: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      totalQty: (data['total_qty'] as num?)?.toInt() ?? 0,
      totalHarga: (data['total_harga'] as num?)?.toInt() ?? 0,
      metodePembayaran: data['metode_pembayaran']?.toString() ?? '-',
      idUser: data['id_kasir']?.toString() ?? data['id_user']?.toString() ?? '-',
      namaUser:
          data['nama_kasir']?.toString() ?? data['nama_user']?.toString() ?? '-',
      status: data['status']?.toString() ?? 'completed',
      shiftId: data['shift_id']?.toString() ?? '',
      paymentProofUrl: data['payment_proof_url']?.toString(),
      paymentAccountName: data['payment_account_name']?.toString(),
      paymentAccountNumber: data['payment_account_number']?.toString(),
      paymentStatus: data['payment_status']?.toString(),
      returnedQty: (data['returned_qty'] as num?)?.toInt() ?? 0,
      returnedAmount: (data['returned_amount'] as num?)?.toInt() ?? 0,
    );
  }
}
