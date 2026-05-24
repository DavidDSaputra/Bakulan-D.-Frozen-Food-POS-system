import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/sale_item.dart';
import '../models/sales_transaction.dart';

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

  Future<void> restockProduct({
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
      transaction.update(productRef, {'stok': currentStock + qty});
      transaction.set(restockRef, {
        'tanggal': FieldValue.serverTimestamp(),
        'barang_id': product.id,
        'nama_barang': product.namaBarang,
        'qty': qty,
        'id_user': userId,
      });
    });
  }

  Future<void> processSale({
    required List<SaleItem> items,
    required String metodePembayaran,
    required String userId,
  }) async {
    if (items.isEmpty) throw Exception('Keranjang masih kosong');

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
          'nama_barang': item.product.namaBarang,
          'qty': item.qty,
          'total_harga': item.subtotal,
          'metode_pembayaran': metodePembayaran,
          'id_user': userId,
        });
      }
    });
  }
}
