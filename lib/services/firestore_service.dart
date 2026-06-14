import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale_item.dart';
import '../models/sales_transaction.dart';
import '../models/stock_movement.dart';

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

  Stream<List<SalesTransaction>> watchTransactions() {
    return _db
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(SalesTransaction.fromDoc).toList(),
        );
  }

  Stream<List<AppUser>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('nama')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppUser.fromDoc).toList());
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

  Future<void> addProduct(Product product) {
    return _db.collection('barang').add(product.toMap());
  }

  Future<void> updateProduct(Product product) {
    return _db.collection('barang').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) {
    return _db.collection('barang').doc(id).delete();
  }

  Future<void> updateStock({required String productId, required int stock}) {
    return _db.collection('barang').doc(productId).update({'stok': stock});
  }

  Future<void> addStock({
    required Product product,
    required int qty,
    required String userId,
  }) async {
    final productRef = _db.collection('barang').doc(product.id);
    final restockRef = _db.collection('barang_masuk').doc();

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
        'id_user': userId,
      });
    });
  }

  Future<void> reduceStockForOpname({
    required Product product,
    required int qty,
    required String note,
    required String userId,
    String proofUrl = '',
  }) async {
    final productRef = _db.collection('barang').doc(product.id);
    final opnameRef = _db.collection('stok_opname_keluar').doc();

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
        'id_user': userId,
        'jenis': 'stok_rusak',
      });
    });
  }

  Future<void> updateProductActive({
    required String productId,
    required bool isActive,
  }) {
    return _db.collection('barang').doc(productId).update({
      'is_active': isActive,
    });
  }

  Future<AppUser> createUserAccount({
    required String nama,
    required String username,
    required String password,
    required UserRole role,
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
    required String userId,
  }) async {
    return addStock(product: product, qty: qty, userId: userId);
  }

  Future<void> processSale({
    required List<SaleItem> items,
    required String metodePembayaran,
    required String userId,
    String? paymentProofUrl,
    String? paymentAccountName,
    String? paymentAccountNumber,
  }) async {
    if (items.isEmpty) throw Exception('Keranjang masih kosong');
    final proofUrl = paymentProofUrl?.trim() ?? '';
    final accountName = paymentAccountName?.trim() ?? '';
    final accountNumber = paymentAccountNumber?.trim() ?? '';

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
          'barang_id': item.product.id,
          'nama_barang': item.product.namaBarang,
          'qty': item.qty,
          'harga_beli': item.product.hargaBeli,
          'harga_jual': item.product.hargaJual,
          'total_harga': item.subtotal,
          'laba': item.profit,
          'metode_pembayaran': metodePembayaran,
          'id_user': userId,
          'payment_proof_url': proofUrl,
          'payment_account_name': accountName,
          'payment_account_number': accountNumber,
          'payment_status': 'lunas',
        });
      }
    });
  }
}
