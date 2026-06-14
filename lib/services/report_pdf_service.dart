import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sales_transaction.dart';
import '../utils/formatters.dart';

class ReportPdfService {
  Future<void> shareReport({
    required List<SalesTransaction> transactions,
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final bytes = await _buildReport(
      transactions: transactions,
      periodLabel: periodLabel,
      startDate: startDate,
      endDate: endDate,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'laporan-bakulan-${periodLabel.toLowerCase()}-${_fileDate(startDate)}.pdf',
    );
  }

  Future<Uint8List> _buildReport({
    required List<SalesTransaction> transactions,
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final document = pw.Document();
    final revenue = transactions.fold<int>(
      0,
      (sum, trx) => sum + trx.totalHarga,
    );
    final totalQty = transactions.fold<int>(0, (sum, trx) => sum + trx.qty);
    final paymentTotals = _groupByPayment(transactions);
    final productTotals = _groupByProduct(transactions);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            pw.Text(
              'Bakulan D. Frozen',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Laporan Penjualan $periodLabel',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Periode: ${_rangeLabel(startDate, endDate)}'),
            pw.Text('Dicetak: ${AppFormatters.date(DateTime.now())}'),
            pw.Divider(height: 28),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _summaryBox(
                    title: 'Total Omzet',
                    value: AppFormatters.rupiah(revenue),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _summaryBox(
                    title: 'Item Terjual',
                    value: '$totalQty item',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _summaryBox(
                    title: 'Transaksi',
                    value: '${transactions.length} data',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            _sectionTitle('Ringkasan Metode Pembayaran'),
            if (paymentTotals.isEmpty)
              pw.Text('Tidak ada transaksi pada periode ini.')
            else
              _keyValueTable(
                headers: const ['Metode', 'Omzet'],
                rows: paymentTotals.entries
                    .map(
                      (entry) => [
                        entry.key.toUpperCase(),
                        AppFormatters.rupiah(entry.value),
                      ],
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 18),
            _sectionTitle('Produk Terjual'),
            if (productTotals.isEmpty)
              pw.Text('Tidak ada produk terjual pada periode ini.')
            else
              _keyValueTable(
                headers: const ['Produk', 'Qty', 'Omzet'],
                rows: productTotals.entries
                    .map(
                      (entry) => [
                        entry.key,
                        '${entry.value.qty}',
                        AppFormatters.rupiah(entry.value.revenue),
                      ],
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 18),
            _sectionTitle('Rincian Transaksi'),
            if (transactions.isEmpty)
              pw.Text('Tidak ada transaksi pada periode ini.')
            else
              _transactionTable(transactions),
          ];
        },
      ),
    );

    return document.save();
  }

  Map<String, int> _groupByPayment(List<SalesTransaction> transactions) {
    final totals = <String, int>{};
    for (final trx in transactions) {
      totals[trx.metodePembayaran] =
          (totals[trx.metodePembayaran] ?? 0) + trx.totalHarga;
    }
    return totals;
  }

  Map<String, _ProductReportTotal> _groupByProduct(
    List<SalesTransaction> transactions,
  ) {
    final totals = <String, _ProductReportTotal>{};
    for (final trx in transactions) {
      final current = totals[trx.namaBarang] ?? const _ProductReportTotal();
      totals[trx.namaBarang] = _ProductReportTotal(
        qty: current.qty + trx.qty,
        revenue: current.revenue + trx.totalHarga,
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    return Map.fromEntries(entries);
  }

  pw.Widget _summaryBox({required String title, required String value}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _keyValueTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.blueGrey100),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    );
  }

  pw.Widget _transactionTable(List<SalesTransaction> transactions) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Tanggal', 'Produk', 'Qty', 'Metode', 'Total'],
      data: [
        for (final trx in transactions)
          [
            AppFormatters.date(trx.tanggal),
            trx.namaBarang,
            '${trx.qty}',
            trx.metodePembayaran.toUpperCase(),
            AppFormatters.rupiah(trx.totalHarga),
          ],
      ],
      border: pw.TableBorder.all(color: PdfColors.blueGrey100),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.45),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(.55),
        3: pw.FlexColumnWidth(.9),
        4: pw.FlexColumnWidth(1.05),
      },
    );
  }

  String _rangeLabel(DateTime startDate, DateTime endDate) {
    final lastDate = endDate.subtract(const Duration(days: 1));
    return '${AppFormatters.date(_dateOnly(startDate)).split(',').first} - '
        '${AppFormatters.date(_dateOnly(lastDate)).split(',').first}';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _fileDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _ProductReportTotal {
  const _ProductReportTotal({this.qty = 0, this.revenue = 0});

  final int qty;
  final int revenue;
}
