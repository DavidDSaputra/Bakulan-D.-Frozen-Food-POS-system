import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/activity_log.dart';
import '../models/app_user.dart';
import '../models/cashier_shift.dart';
import '../models/category.dart';
import '../models/purchase_record.dart';
import '../models/product.dart';
import '../models/sale_item.dart';
import '../models/sales_invoice.dart';
import '../models/sales_transaction.dart';
import '../models/stock_movement.dart';
import '../models/supplier.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Product>> watchProducts() {
    return _db
        .collection('barang')
        .orderBy('nama_barang')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromDoc).toList());
  }

  Stream<List<Product>> watchActiveProducts() {
    return watchProducts().map(
      (products) => products.where((product) => product.isActive).toList(),
    );
  }

  Stream<List<ProductCategory>> watchCategories() {
    return _db
        .collection('kategori')
        .orderBy('nama_kategori')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ProductCategory.fromDoc).toList());
  }

  Stream<List<SalesTransaction>> watchTransactions({int? limit}) {
    Query<Map<String, dynamic>> query = _db
        .collection('transaksi')
        .orderBy('tanggal', descending: true);
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(SalesTransaction.fromDoc).toList(),
    );
  }

  Stream<List<SalesInvoice>> watchInvoices({int? limit}) {
    Query<Map<String, dynamic>> query = _db
        .collection('sales_invoices')
        .orderBy('tanggal', descending: true);
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(SalesInvoice.fromDoc).toList(),
    );
  }

  Stream<List<SalesTransaction>> watchInvoiceItems(String invoiceId) {
    return _db
        .collection('transaksi')
        .where('invoice_id', isEqualTo: invoiceId)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .timeout(const Duration(seconds: 8))
        .map(
          (snapshot) => snapshot.docs.map(SalesTransaction.fromDoc).toList(),
        );
  }

  Stream<List<CashierShift>> watchShiftHistory({int? limit}) {
    Query<Map<String, dynamic>> query = _db
        .collection('cashier_shifts')
        .orderBy('opened_at', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(CashierShift.fromDoc).toList(),
    );
  }

  Stream<CashierShift?> watchActiveShift(String userId) {
    return _db
        .collection('cashier_shifts')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isEmpty
              ? null
              : CashierShift.fromDoc(snapshot.docs.first),
        );
  }

  Stream<List<Supplier>> watchSuppliers() {
    return _db
        .collection('suppliers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Supplier.fromDoc).toList());
  }

  Stream<List<PurchaseRecord>> watchPurchaseRecords({int? limit}) {
    Query<Map<String, dynamic>> query = _db
        .collection('purchase_records')
        .orderBy('timestamp', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(PurchaseRecord.fromDoc).toList(),
    );
  }

  Stream<List<AppUser>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('nama')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppUser.fromDoc).toList());
  }

  Stream<List<ActivityLog>> watchActivityLogs({int? limit}) {
    Query<Map<String, dynamic>> query = _db
        .collection('activity_logs')
        .orderBy('timestamp', descending: true);
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(ActivityLog.fromDoc).toList(),
    );
  }

  Stream<List<StockMovement>> watchRestockMovements() {
    return _db
        .collection('barang_masuk')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(StockMovement.fromRestockDoc).toList(),
        );
  }

  Stream<List<StockMovement>> watchSalesMovements() {
    return _db
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(StockMovement.fromSalesDoc).toList(),
        );
  }

  Stream<List<StockMovement>> watchOpnameMovements() {
    return _db
        .collection('stok_opname_keluar')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(StockMovement.fromOpnameDoc).toList(),
        );
  }

  Future<void> addProduct({
    required Product product,
    required AppUser actor,
  }) async {
    await _assertNoDuplicateProduct(product);
    final docRef = await _db.collection('barang').add(product.toMap());
    await logActivity(
      actor: actor,
      action: 'product_create',
      targetType: 'barang',
      targetId: docRef.id,
      title: 'Menambahkan barang',
      description: '${actor.nama} menambahkan barang ${product.namaBarang}',
      metadata: {
        'nama_barang': product.namaBarang,
        'stok': product.stok,
        'harga_jual': product.hargaJual,
      },
    );
  }

  Future<void> updateProduct({
    required Product product,
    required AppUser actor,
  }) async {
    await _assertNoDuplicateProduct(product, ignoreId: product.id);
    await _db.collection('barang').doc(product.id).update(product.toMap());
    await logActivity(
      actor: actor,
      action: 'product_update',
      targetType: 'barang',
      targetId: product.id,
      title: 'Memperbarui barang',
      description: '${actor.nama} memperbarui barang ${product.namaBarang}',
      metadata: {
        'nama_barang': product.namaBarang,
        'stok': product.stok,
        'harga_jual': product.hargaJual,
      },
    );
  }

  Future<void> deleteProduct({
    required Product product,
    required AppUser actor,
  }) async {
    await _db.collection('barang').doc(product.id).delete();
    await logActivity(
      actor: actor,
      action: 'product_delete',
      targetType: 'barang',
      targetId: product.id,
      title: 'Menghapus barang',
      description: '${actor.nama} menghapus barang ${product.namaBarang}',
      metadata: {'nama_barang': product.namaBarang},
    );
  }

  Future<void> updateStock({required String productId, required int stock}) {
    return _db.collection('barang').doc(productId).update({'stok': stock});
  }

  Future<void> addStock({
    required Product product,
    required int qty,
    required AppUser actor,
  }) async {
    final productRef = _db.collection('barang').doc(product.id);
    final restockRef = _db.collection('barang_masuk').doc();
    final logRef = _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) throw Exception('Barang tidak ditemukan');

      final currentStock =
          (snapshot.data()?['stok'] as num?)?.toInt() ?? product.stok;
      final newStock = currentStock + qty;

      transaction.update(productRef, {'stok': newStock});
      transaction.set(restockRef, {
        'tanggal': FieldValue.serverTimestamp(),
        'barang_id': product.id,
        'nama_barang': product.namaBarang,
        'qty': qty,
        'stok_awal': currentStock,
        'stok_akhir': newStock,
        'id_user': actor.id,
        'id_kasir': actor.id,
        'nama_user': actor.nama,
        'nama_kasir': actor.nama,
      });
      transaction.set(
        logRef,
        _activityLogData(
          actor: actor,
          action: 'stock_add',
          targetType: 'barang',
          targetId: product.id,
          title: 'Menambah stok',
          description:
              '${actor.nama} menambah stok ${product.namaBarang} sebanyak $qty',
          metadata: {
            'nama_barang': product.namaBarang,
            'qty': qty,
            'stok_awal': currentStock,
            'stok_akhir': newStock,
          },
        ),
      );
    });
  }

  Future<void> reduceStockForOpname({
    required Product product,
    required int qty,
    required String note,
    required AppUser actor,
    String proofUrl = '',
  }) async {
    final productRef = _db.collection('barang').doc(product.id);
    final opnameRef = _db.collection('stok_opname_keluar').doc();
    final logRef = _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) throw Exception('Barang tidak ditemukan');

      final currentStock =
          (snapshot.data()?['stok'] as num?)?.toInt() ?? product.stok;
      if (qty <= 0) throw Exception('Jumlah harus lebih dari 0');
      if (currentStock < qty) {
        throw Exception('Stok ${product.namaBarang} tidak mencukupi');
      }

      final newStock = currentStock - qty;
      transaction.update(productRef, {'stok': newStock});
      transaction.set(opnameRef, {
        'tanggal': FieldValue.serverTimestamp(),
        'barang_id': product.id,
        'nama_barang': product.namaBarang,
        'qty': qty,
        'stok_awal': currentStock,
        'stok_akhir': newStock,
        'keterangan': note.trim(),
        'proof_url': proofUrl.trim(),
        'id_user': actor.id,
        'id_kasir': actor.id,
        'nama_user': actor.nama,
        'nama_kasir': actor.nama,
        'jenis': 'stok_rusak',
      });
      transaction.set(
        logRef,
        _activityLogData(
          actor: actor,
          action: 'stock_reduce',
          targetType: 'barang',
          targetId: product.id,
          title: 'Mengurangi stok',
          description:
              '${actor.nama} mengurangi stok ${product.namaBarang} sebanyak $qty',
          metadata: {
            'nama_barang': product.namaBarang,
            'qty': qty,
            'stok_awal': currentStock,
            'stok_akhir': newStock,
            'keterangan': note.trim(),
          },
        ),
      );
    });
  }

  Future<void> updateProductActive({
    required Product product,
    required bool isActive,
    required AppUser actor,
  }) async {
    await _db.collection('barang').doc(product.id).update({
      'is_active': isActive,
    });
    await logActivity(
      actor: actor,
      action: isActive ? 'product_activate' : 'product_deactivate',
      targetType: 'barang',
      targetId: product.id,
      title: isActive ? 'Mengaktifkan barang' : 'Menonaktifkan barang',
      description:
          '${actor.nama} ${isActive ? 'mengaktifkan' : 'menonaktifkan'} barang ${product.namaBarang}',
      metadata: {'nama_barang': product.namaBarang, 'is_active': isActive},
    );
  }

  Future<AppUser> createUserAccount({
    required String nama,
    required String username,
    required String password,
    required UserRole role,
    required AppUser actor,
  }) async {
    final normalized = username.trim().toLowerCase();
    final email = normalized.contains('@')
        ? normalized
        : '$normalized@bakulandfrozen.local';

    final secondaryApp = await _secondaryFirebaseApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final user = AppUser(
        id: uid,
        nama: nama.trim(),
        username: normalized,
        role: role,
      );
      await _db.collection('users').doc(uid).set(user.toMap());
      await credential.user?.updateDisplayName(user.nama);
      await logActivity(
        actor: actor,
        action: 'account_create',
        targetType: 'user',
        targetId: uid,
        title: 'Membuat akun',
        description: '${actor.nama} membuat akun ${user.nama}',
        metadata: {'username': user.username, 'role': user.role.name},
      );
      return user;
    } finally {
      await secondaryAuth.signOut();
    }
  }

  Future<FirebaseApp> _secondaryFirebaseApp() async {
    const appName = 'BakulanUserCreation';
    try {
      return Firebase.app(appName);
    } catch (_) {
      return Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> restockProduct({
    required Product product,
    required int qty,
    required AppUser actor,
  }) async {
    return addStock(product: product, qty: qty, actor: actor);
  }

  Future<void> openShift({
    required AppUser actor,
    required int openingCash,
  }) async {
    final existing = await _findActiveShift(actor.id);
    if (existing != null) {
      throw Exception('Shift kasir masih terbuka.');
    }

    final shiftRef = await _db.collection('cashier_shifts').add({
      'user_id': actor.id,
      'user_name': actor.nama,
      'opened_at': FieldValue.serverTimestamp(),
      'opening_cash': openingCash,
      'status': 'open',
      'total_sales': 0,
      'cash_sales': 0,
      'transfer_sales': 0,
      'qris_sales': 0,
      'invoice_count': 0,
    });

    await logActivity(
      actor: actor,
      action: 'shift_open',
      targetType: 'shift',
      targetId: shiftRef.id,
      title: 'Membuka shift',
      description: '${actor.nama} membuka shift kasir',
      metadata: {'opening_cash': openingCash},
    );
  }

  Future<void> closeShift({
    required CashierShift shift,
    required int closingCash,
    required AppUser actor,
  }) async {
    if (!shift.isOpen) throw Exception('Shift ini sudah ditutup.');

    final invoices = await _db
        .collection('sales_invoices')
        .where('shift_id', isEqualTo: shift.id)
        .get();

    var totalSales = 0;
    var cashSales = 0;
    var transferSales = 0;
    var qrisSales = 0;
    for (final doc in invoices.docs) {
      final data = doc.data();
      final amount = (data['total_harga'] as num?)?.toInt() ?? 0;
      totalSales += amount;
      final method = data['metode_pembayaran']?.toString().toLowerCase() ?? '';
      if (method.contains('cash')) {
        cashSales += amount;
      } else if (method.contains('qris')) {
        qrisSales += amount;
      } else {
        transferSales += amount;
      }
    }

    await _db.collection('cashier_shifts').doc(shift.id).update({
      'status': 'closed',
      'closed_at': FieldValue.serverTimestamp(),
      'closing_cash': closingCash,
      'total_sales': totalSales,
      'cash_sales': cashSales,
      'transfer_sales': transferSales,
      'qris_sales': qrisSales,
      'invoice_count': invoices.docs.length,
    });

    await logActivity(
      actor: actor,
      action: 'shift_close',
      targetType: 'shift',
      targetId: shift.id,
      title: 'Menutup shift',
      description: '${actor.nama} menutup shift kasir',
      metadata: {
        'closing_cash': closingCash,
        'total_sales': totalSales,
        'invoice_count': invoices.docs.length,
      },
    );
  }

  Future<void> addSupplier({
    required Supplier supplier,
    required AppUser actor,
  }) async {
    await _assertNoDuplicateSupplier(supplier);
    final supplierRef = await _db.collection('suppliers').add(supplier.toMap());
    await logActivity(
      actor: actor,
      action: 'supplier_create',
      targetType: 'supplier',
      targetId: supplierRef.id,
      title: 'Menambahkan supplier',
      description: '${actor.nama} menambahkan supplier ${supplier.name}',
      metadata: {'nama_supplier': supplier.name, 'telepon': supplier.phone},
    );
  }

  Future<void> recordPurchase({
    required Supplier supplier,
    required Product product,
    required int qty,
    required int unitCost,
    required AppUser actor,
  }) async {
    if (qty <= 0) throw Exception('Qty pembelian harus lebih dari 0');
    if (unitCost < 0) throw Exception('Harga beli tidak boleh negatif');

    final productRef = _db.collection('barang').doc(product.id);
    final purchaseRef = _db.collection('purchase_records').doc();
    final restockRef = _db.collection('barang_masuk').doc();
    final logRef = _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) throw Exception('Barang tidak ditemukan');

      final currentStock =
          (snapshot.data()?['stok'] as num?)?.toInt() ?? product.stok;
      final newStock = currentStock + qty;

      transaction.update(productRef, {
        'stok': newStock,
        'harga_beli': unitCost,
      });
      transaction.set(purchaseRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'product_id': product.id,
        'product_name': product.namaBarang,
        'supplier_id': supplier.id,
        'supplier_name': supplier.name,
        'qty': qty,
        'unit_cost': unitCost,
        'total_cost': unitCost * qty,
        'user_id': actor.id,
        'user_name': actor.nama,
      });
      transaction.set(restockRef, {
        'tanggal': FieldValue.serverTimestamp(),
        'barang_id': product.id,
        'nama_barang': product.namaBarang,
        'qty': qty,
        'stok_awal': currentStock,
        'stok_akhir': newStock,
        'id_user': actor.id,
        'id_kasir': actor.id,
        'nama_user': actor.nama,
        'nama_kasir': actor.nama,
        'supplier_id': supplier.id,
        'supplier_name': supplier.name,
        'jenis': 'pembelian_supplier',
      });
      transaction.set(
        logRef,
        _activityLogData(
          actor: actor,
          action: 'purchase_create',
          targetType: 'purchase',
          targetId: purchaseRef.id,
          title: 'Mencatat pembelian',
          description:
              '${actor.nama} mencatat pembelian ${product.namaBarang} dari ${supplier.name}',
          metadata: {
            'nama_barang': product.namaBarang,
            'nama_supplier': supplier.name,
            'qty': qty,
            'harga_beli': unitCost,
            'total_biaya': unitCost * qty,
            'stok_awal': currentStock,
            'stok_akhir': newStock,
          },
        ),
      );
    });
  }

  Future<void> returnInvoiceItem({
    required SalesInvoice invoice,
    required SalesTransaction item,
    required int qty,
    required String note,
    required AppUser actor,
  }) async {
    if (qty <= 0) throw Exception('Qty retur harus lebih dari 0');
    if (qty > item.remainingQty) {
      throw Exception('Qty retur melebihi sisa item yang belum diretur');
    }

    final productRef = _db.collection('barang').doc(item.barangId);
    final itemRef = _db.collection('transaksi').doc(item.id);
    final invoiceRef = _db.collection('sales_invoices').doc(invoice.id);
    final returnRef = _db.collection('retur_transaksi').doc();
    final logRef = _db.collection('activity_logs').doc();
    final unitPrice = item.hargaJual > 0
        ? item.hargaJual
        : item.totalHarga ~/ item.qty;
    final returnAmount = unitPrice * qty;

    await _db.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      final itemSnapshot = await transaction.get(itemRef);
      final invoiceSnapshot = await transaction.get(invoiceRef);
      if (!itemSnapshot.exists || !invoiceSnapshot.exists) {
        throw Exception('Data transaksi tidak ditemukan');
      }

      final currentStock =
          (productSnapshot.data()?['stok'] as num?)?.toInt() ?? 0;
      final newReturnedQty = item.returnedQty + qty;
      final itemStatus = newReturnedQty >= item.qty
          ? 'returned'
          : 'partial_return';
      final invoiceReturnedQty = invoice.returnedQty + qty;
      final invoiceReturnedAmount = invoice.returnedAmount + returnAmount;
      final invoiceStatus = invoiceReturnedQty >= invoice.totalQty
          ? 'returned'
          : 'partial_return';

      transaction.update(productRef, {'stok': currentStock + qty});
      transaction.update(itemRef, {
        'returned_qty': newReturnedQty,
        'item_status': itemStatus,
      });
      transaction.update(invoiceRef, {
        'returned_qty': invoiceReturnedQty,
        'returned_amount': invoiceReturnedAmount,
        'status': invoiceStatus,
      });
      transaction.set(returnRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'invoice_id': invoice.id,
        'invoice_code': invoice.invoiceCode,
        'transaction_id': item.id,
        'product_id': item.barangId,
        'product_name': item.namaBarang,
        'qty': qty,
        'amount': returnAmount,
        'note': note.trim(),
        'user_id': actor.id,
        'user_name': actor.nama,
      });
      transaction.set(
        logRef,
        _activityLogData(
          actor: actor,
          action: 'sale_return',
          targetType: 'invoice',
          targetId: invoice.id,
          title: 'Retur transaksi',
          description:
              '${actor.nama} meretur ${item.namaBarang} sebanyak $qty dari invoice ${invoice.invoiceCode}',
          metadata: {
            'invoice_code': invoice.invoiceCode,
            'nama_barang': item.namaBarang,
            'qty': qty,
            'jumlah_retur': returnAmount,
            'keterangan': note.trim(),
          },
        ),
      );
    });
  }

  Future<void> cancelInvoice({
    required SalesInvoice invoice,
    required List<SalesTransaction> items,
    required String note,
    required AppUser actor,
  }) async {
    if (invoice.isCancelled) {
      throw Exception('Invoice ini sudah dibatalkan');
    }

    final invoiceRef = _db.collection('sales_invoices').doc(invoice.id);
    final returnRef = _db.collection('retur_transaksi').doc();
    final logRef = _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      for (final item in items) {
        final remainingQty = item.remainingQty;
        if (remainingQty <= 0) continue;

        final productRef = _db.collection('barang').doc(item.barangId);
        final productSnapshot = await transaction.get(productRef);
        final currentStock =
            (productSnapshot.data()?['stok'] as num?)?.toInt() ?? 0;
        transaction.update(productRef, {'stok': currentStock + remainingQty});
        transaction.update(_db.collection('transaksi').doc(item.id), {
          'returned_qty': item.qty,
          'item_status': 'cancelled',
        });
      }

      transaction.update(invoiceRef, {
        'status': 'cancelled',
        'returned_qty': invoice.totalQty,
        'returned_amount': invoice.totalHarga,
        'cancel_note': note.trim(),
      });
      transaction.set(returnRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'invoice_id': invoice.id,
        'invoice_code': invoice.invoiceCode,
        'qty': invoice.totalQty,
        'amount': invoice.totalHarga,
        'note': note.trim(),
        'user_id': actor.id,
        'user_name': actor.nama,
        'type': 'cancel_invoice',
      });
      transaction.set(
        logRef,
        _activityLogData(
          actor: actor,
          action: 'sale_cancel',
          targetType: 'invoice',
          targetId: invoice.id,
          title: 'Membatalkan transaksi',
          description:
              '${actor.nama} membatalkan invoice ${invoice.invoiceCode}',
          metadata: {
            'invoice_code': invoice.invoiceCode,
            'qty_total': invoice.totalQty,
            'total_harga': invoice.totalHarga,
            'keterangan': note.trim(),
          },
        ),
      );
    });
  }

  Future<void> processSale({
    required List<SaleItem> items,
    required String metodePembayaran,
    required AppUser actor,
    String? paymentProofUrl,
    String? paymentAccountName,
    String? paymentAccountNumber,
  }) async {
    if (items.isEmpty) throw Exception('Keranjang masih kosong');
    final proofUrl = paymentProofUrl?.trim() ?? '';
    final accountName = paymentAccountName?.trim() ?? '';
    final accountNumber = paymentAccountNumber?.trim() ?? '';
    final activeShift = await _findActiveShift(actor.id);
    final totalQty = items.fold<int>(0, (total, item) => total + item.qty);
    final totalAmount = items.fold<int>(
      0,
      (total, item) => total + item.subtotal,
    );
    final saleNames = items.map((item) => item.product.namaBarang).join(', ');
    final logRef = _db.collection('activity_logs').doc();
    final invoiceRef = _db.collection('sales_invoices').doc();
    final invoiceCode = _generateInvoiceCode();

    await _db.runTransaction((transaction) async {
      final refs = items
          .map((item) => _db.collection('barang').doc(item.product.id))
          .toList();
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final ref in refs) {
        snapshots.add(await transaction.get(ref));
      }

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final snapshot = snapshots[i];
        if (!snapshot.exists) {
          throw Exception('${item.product.namaBarang} tidak ditemukan');
        }

        final stock = (snapshot.data()?['stok'] as num?)?.toInt() ?? 0;
        if (stock < item.qty) {
          throw Exception('Stok ${item.product.namaBarang} tidak mencukupi');
        }
      }

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final stock = (snapshots[i].data()?['stok'] as num?)?.toInt() ?? 0;
        transaction.update(refs[i], {'stok': stock - item.qty});

        final trxRef = _db.collection('transaksi').doc();
        transaction.set(trxRef, {
          'tanggal': FieldValue.serverTimestamp(),
          'invoice_id': invoiceRef.id,
          'invoice_code': invoiceCode,
          'barang_id': item.product.id,
          'nama_barang': item.product.namaBarang,
          'qty': item.qty,
          'harga_beli': item.product.hargaBeli,
          'harga_jual': item.product.hargaJual,
          'total_harga': item.subtotal,
          'laba': item.profit,
          'metode_pembayaran': metodePembayaran,
          'id_user': actor.id,
          'id_kasir': actor.id,
          'nama_user': actor.nama,
          'nama_kasir': actor.nama,
          'payment_proof_url': proofUrl,
          'payment_account_name': accountName,
          'payment_account_number': accountNumber,
          'payment_status': 'lunas',
          'returned_qty': 0,
          'item_status': 'completed',
          'shift_id': activeShift?.id ?? '',
        });
      }

      transaction.set(invoiceRef, {
        'invoice_code': invoiceCode,
        'tanggal': FieldValue.serverTimestamp(),
        'total_qty': totalQty,
        'total_harga': totalAmount,
        'metode_pembayaran': metodePembayaran,
        'id_user': actor.id,
        'id_kasir': actor.id,
        'nama_user': actor.nama,
        'nama_kasir': actor.nama,
        'payment_proof_url': proofUrl,
        'payment_account_name': accountName,
        'payment_account_number': accountNumber,
        'payment_status': 'lunas',
        'status': 'completed',
        'returned_qty': 0,
        'returned_amount': 0,
        'shift_id': activeShift?.id ?? '',
      });

      transaction.set(
        logRef,
        _activityLogData(
          actor: actor,
          action: 'sale_create',
          targetType: 'invoice',
          targetId: invoiceRef.id,
          title: 'Membuat transaksi',
          description: '${actor.nama} memproses transaksi $totalQty item',
          metadata: {
            'invoice_code': invoiceCode,
            'qty_total': totalQty,
            'total_harga': totalAmount,
            'metode_pembayaran': metodePembayaran,
            'barang': saleNames,
            'line_items': items
                .map(
                  (item) => {
                    'nama_barang': item.product.namaBarang,
                    'qty': item.qty,
                    'harga_jual': item.product.hargaJual,
                    'subtotal': item.subtotal,
                  },
                )
                .toList(),
          },
        ),
      );
    });
  }

  Future<void> logActivity({
    required AppUser actor,
    required String action,
    required String targetType,
    required String targetId,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) {
    return _db
        .collection('activity_logs')
        .add(
          _activityLogData(
            actor: actor,
            action: action,
            targetType: targetType,
            targetId: targetId,
            title: title,
            description: description,
            metadata: metadata,
          ),
        );
  }

  Future<CashierShift?> _findActiveShift(String userId) async {
    final snapshot = await _db
        .collection('cashier_shifts')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return CashierShift.fromDoc(snapshot.docs.first);
  }

  String _generateInvoiceCode() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final time = now.millisecond.toString().padLeft(3, '0');
    return 'INV-$year$month$day-${now.hour}${now.minute}${now.second}$time';
  }

  Future<void> _assertNoDuplicateProduct(
    Product product, {
    String? ignoreId,
  }) async {
    final snapshot = await _db.collection('barang').get();
    final normalizedName = product.namaBarang.trim().toLowerCase();
    final normalizedBarcode = product.barcode.trim().toLowerCase();

    for (final doc in snapshot.docs) {
      if (ignoreId != null && doc.id == ignoreId) continue;
      final data = doc.data();
      final existingName =
          data['nama_barang']?.toString().trim().toLowerCase() ?? '';
      final existingBarcode =
          data['barcode']?.toString().trim().toLowerCase() ?? '';

      if (existingName.isNotEmpty && existingName == normalizedName) {
        throw Exception('Nama barang sudah ada. Gunakan nama lain.');
      }

      if (normalizedBarcode.isNotEmpty &&
          existingBarcode.isNotEmpty &&
          existingBarcode == normalizedBarcode) {
        throw Exception('Barcode barang sudah dipakai produk lain.');
      }
    }
  }

  Future<void> _assertNoDuplicateSupplier(
    Supplier supplier, {
    String? ignoreId,
  }) async {
    final snapshot = await _db.collection('suppliers').get();
    final normalizedName = supplier.name.trim().toLowerCase();

    for (final doc in snapshot.docs) {
      if (ignoreId != null && doc.id == ignoreId) continue;
      final data = doc.data();
      final existingName = data['name']?.toString().trim().toLowerCase() ?? '';
      if (existingName.isNotEmpty && existingName == normalizedName) {
        throw Exception('Nama supplier sudah ada. Gunakan nama lain.');
      }
    }
  }

  Map<String, dynamic> _activityLogData({
    required AppUser actor,
    required String action,
    required String targetType,
    required String targetId,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'timestamp': FieldValue.serverTimestamp(),
      'user_id': actor.id,
      'user_name': actor.nama,
      'user_role': actor.role.name,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'title': title,
      'description': description,
      'metadata': metadata ?? <String, dynamic>{},
    };
  }
}
