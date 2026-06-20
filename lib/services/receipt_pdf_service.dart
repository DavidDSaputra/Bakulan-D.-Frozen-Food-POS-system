import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale_item.dart';
import '../models/product.dart';
import '../models/sales_invoice.dart';
import '../models/sales_transaction.dart';
import '../utils/formatters.dart';

class ReceiptPdfService {
  Future<void> shareReceipt({
    required List<SaleItem> items,
    required String method,
    required int paid,
    required String cashierName,
  }) async {
    final bytes = await _buildReceipt(
      items: items,
      method: method,
      paid: paid,
      cashierName: cashierName,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'struk-bakulan-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> shareTransactionReceipt({
    required SalesTransaction transaction,
  }) async {
    final item = SaleItem(
      product: Product(
        id: transaction.barangId,
        namaBarang: transaction.namaBarang,
        hargaBeli: transaction.hargaBeli,
        harga: transaction.hargaJual > 0
            ? transaction.hargaJual
            : transaction.totalHarga,
        stok: 0,
        kategoriId: '',
      ),
      qty: transaction.qty,
    );

    final bytes = await _buildReceipt(
      items: [item],
      method: transaction.metodePembayaran,
      paid: transaction.totalHarga,
      cashierName: transaction.namaUser,
      printedAt: transaction.tanggal,
      showCashBreakdown: false,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'struk-transaksi-${transaction.id}-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> shareInvoiceReceipt({
    required SalesInvoice invoice,
    required List<SalesTransaction> items,
  }) async {
    final saleItems = items
        .map(
          (transaction) => SaleItem(
            product: Product(
              id: transaction.barangId,
              namaBarang: transaction.namaBarang,
              hargaBeli: transaction.hargaBeli,
              harga: transaction.hargaJual > 0
                  ? transaction.hargaJual
                  : transaction.totalHarga,
              stok: 0,
              kategoriId: '',
            ),
            qty: transaction.qty,
          ),
        )
        .toList();

    final bytes = await _buildReceipt(
      items: saleItems,
      method: invoice.metodePembayaran,
      paid: invoice.totalHarga,
      cashierName: invoice.namaUser,
      printedAt: invoice.tanggal,
      showCashBreakdown: false,
      receiptCode: invoice.invoiceCode,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'struk-${invoice.invoiceCode}-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Uint8List> _buildReceipt({
    required List<SaleItem> items,
    required String method,
    required int paid,
    required String cashierName,
    DateTime? printedAt,
    bool showCashBreakdown = true,
    String? receiptCode,
  }) async {
    final document = pw.Document();
    final total = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    final change = method == 'cash' ? paid - total : 0;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'Bakulan D. Frozen',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              if ((receiptCode ?? '').trim().isNotEmpty)
                pw.Center(child: pw.Text(receiptCode!.trim())),
              if ((receiptCode ?? '').trim().isNotEmpty) pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(AppFormatters.date(printedAt ?? DateTime.now())),
              ),
              pw.Divider(height: 20),
              for (final item in items) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text('${item.product.namaBarang} x${item.qty}'),
                    ),
                    pw.Text(AppFormatters.rupiah(item.subtotal)),
                  ],
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Divider(height: 20),
              _row('Metode', method.toUpperCase()),
              _row('Nama Kasir', cashierName),
              _row('Total', AppFormatters.rupiah(total), bold: true),
              if (method == 'cash' && showCashBreakdown) ...[
                _row('Dibayar', AppFormatters.rupiah(paid)),
                _row('Kembali', AppFormatters.rupiah(change), bold: true),
              ],
              pw.SizedBox(height: 18),
              pw.Center(child: pw.Text('Terima kasih')),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  pw.Widget _row(String label, String value, {bool bold = false}) {
    final style = bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
