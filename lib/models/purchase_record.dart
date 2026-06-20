import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.timestamp,
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.qty,
    required this.unitCost,
    required this.totalCost,
    required this.userId,
    required this.userName,
  });

  final String id;
  final DateTime timestamp;
  final String productId;
  final String productName;
  final String supplierId;
  final String supplierName;
  final int qty;
  final int unitCost;
  final int totalCost;
  final String userId;
  final String userName;

  factory PurchaseRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawTimestamp = data['timestamp'];
    return PurchaseRecord(
      id: doc.id,
      timestamp: rawTimestamp is Timestamp ? rawTimestamp.toDate() : DateTime.now(),
      productId: data['product_id']?.toString() ?? '',
      productName: data['product_name']?.toString() ?? '-',
      supplierId: data['supplier_id']?.toString() ?? '',
      supplierName: data['supplier_name']?.toString() ?? '-',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      unitCost: (data['unit_cost'] as num?)?.toInt() ?? 0,
      totalCost: (data['total_cost'] as num?)?.toInt() ?? 0,
      userId: data['user_id']?.toString() ?? '-',
      userName: data['user_name']?.toString() ?? '-',
    );
  }
}
