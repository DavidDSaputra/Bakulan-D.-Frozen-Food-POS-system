import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class BackupExportService {
  BackupExportService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _collections = [
    'barang',
    'kategori',
    'users',
    'sales_invoices',
    'transaksi',
    'barang_masuk',
    'stok_opname_keluar',
    'activity_logs',
    'cashier_shifts',
    'suppliers',
    'purchase_records',
    'retur_transaksi',
  ];

  Future<void> shareBackup() async {
    final payload = <String, dynamic>{
      'exported_at': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
    };

    for (final name in _collections) {
      final snapshot = await _db.collection(name).get();
      payload['collections'][name] = snapshot.docs
          .map((doc) => {'id': doc.id, 'data': _encodeValue(doc.data())})
          .toList();
    }

    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    await SharePlus.instance.share(
      ShareParams(
        title: 'Backup Data Bakulan POS',
        text: 'Backup data aplikasi Bakulan POS',
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: 'backup-bakulan-$stamp.json',
          ),
        ],
        downloadFallbackEnabled: true,
      ),
    );
  }

  dynamic _encodeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is DocumentReference) return value.path;
    if (value is Map<String, dynamic>) {
      return value.map((key, item) => MapEntry(key, _encodeValue(item)));
    }
    if (value is List) {
      return value.map(_encodeValue).toList();
    }
    return value;
  }
}
