import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale_item.dart';
import '../utils/formatters.dart';

class ReceiptPdfService {
  Future<void> shareReceipt({
    required List<SaleItem> items,
    required String method,
    required int paid,
  }) async {
    final bytes = await _buildReceipt(items: items, method: method, paid: paid);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'struk-bakulan-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Uint8List> _buildReceipt({
    required List<SaleItem> items,
    required String method,
    required int paid,
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
              pw.Center(child: pw.Text(AppFormatters.date(DateTime.now()))),
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
              _row('Total', AppFormatters.rupiah(total), bold: true),
              if (method == 'cash') ...[
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
