import 'package:cloud_firestore/cloud_firestore.dart';

class CashierShift {
  const CashierShift({
    required this.id,
    required this.userId,
    required this.userName,
    required this.openedAt,
    required this.openingCash,
    this.status = 'open',
    this.closedAt,
    this.closingCash,
    this.totalSales = 0,
    this.cashSales = 0,
    this.transferSales = 0,
    this.qrisSales = 0,
    this.invoiceCount = 0,
  });

  final String id;
  final String userId;
  final String userName;
  final DateTime openedAt;
  final int openingCash;
  final String status;
  final DateTime? closedAt;
  final int? closingCash;
  final int totalSales;
  final int cashSales;
  final int transferSales;
  final int qrisSales;
  final int invoiceCount;

  bool get isOpen => status == 'open';

  factory CashierShift.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawOpenedAt = data['opened_at'];
    final rawClosedAt = data['closed_at'];
    return CashierShift(
      id: doc.id,
      userId: data['user_id']?.toString() ?? '-',
      userName: data['user_name']?.toString() ?? '-',
      openedAt: rawOpenedAt is Timestamp ? rawOpenedAt.toDate() : DateTime.now(),
      openingCash: (data['opening_cash'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? 'open',
      closedAt: rawClosedAt is Timestamp ? rawClosedAt.toDate() : null,
      closingCash: (data['closing_cash'] as num?)?.toInt(),
      totalSales: (data['total_sales'] as num?)?.toInt() ?? 0,
      cashSales: (data['cash_sales'] as num?)?.toInt() ?? 0,
      transferSales: (data['transfer_sales'] as num?)?.toInt() ?? 0,
      qrisSales: (data['qris_sales'] as num?)?.toInt() ?? 0,
      invoiceCount: (data['invoice_count'] as num?)?.toInt() ?? 0,
    );
  }
}
