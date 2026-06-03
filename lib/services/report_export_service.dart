import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report_period.dart';
import '../models/sales_transaction.dart';
import '../utils/formatters.dart';

class ReportExportService {
  static final _brandColor = PdfColor.fromHex('#1565C0');
  static final _lightBlue = PdfColor.fromHex('#E3F2FD');
  static final _altRow = PdfColor.fromHex('#F5F9FF');

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> exportPdf({
    required List<SalesTransaction> transactions,
    required ReportPeriod period,
  }) async {
    final bytes = await _buildPdf(transactions: transactions, period: period);
    final filename = 'laporan-${_periodSlug(period)}-${_dateSlug()}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> exportExcel({
    required List<SalesTransaction> transactions,
    required ReportPeriod period,
  }) async {
    final bytes = _buildExcel(transactions: transactions, period: period);
    final filename = 'laporan-${_periodSlug(period)}-${_dateSlug()}.xlsx';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text:
            'Laporan Penjualan ${_periodLabel(period)} - Bakulan D. Frozen Food',
      ),
    );
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf({
    required List<SalesTransaction> transactions,
    required ReportPeriod period,
  }) async {
    final doc = pw.Document();
    final totalRevenue = transactions.fold<int>(0, (s, t) => s + t.totalHarga);
    final totalQty = transactions.fold<int>(0, (s, t) => s + t.qty);
    final paymentBreakdown = _groupByPayment(transactions);
    final topProducts = _topProducts(transactions);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        header: (_) => _pdfHeader(period),
        footer: (ctx) => _pdfFooter(ctx),
        build: (_) => [
          _pdfSummarySection(totalRevenue, totalQty, transactions.length),
          pw.SizedBox(height: 16),
          _pdfPaymentSection(paymentBreakdown),
          pw.SizedBox(height: 16),
          if (topProducts.isNotEmpty) ...[
            _pdfTopProductsSection(topProducts),
            pw.SizedBox(height: 16),
          ],
          _pdfTransactionTable(transactions),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfHeader(ReportPeriod period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: pw.BoxDecoration(color: _brandColor),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bakulan D. Frozen Food',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Laporan Penjualan ${_periodLabel(period)}  ·  ${_periodRangeText(period)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  pw.Widget _pdfFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak: ${AppFormatters.date(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Hal ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _brandColor, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
    );
  }

  pw.Widget _pdfSummarySection(int totalRevenue, int totalQty, int totalTrx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfSectionTitle('Ringkasan'),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _pdfStatBox('Total Omzet', AppFormatters.rupiah(totalRevenue)),
            pw.SizedBox(width: 8),
            _pdfStatBox('Jumlah Transaksi', '$totalTrx'),
            pw.SizedBox(width: 8),
            _pdfStatBox('Item Terjual', '$totalQty'),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _lightBlue,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: _brandColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfPaymentSection(Map<String, _PaymentSummary> breakdown) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfSectionTitle('Rincian Pembayaran'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1.5),
          },
          children: [
            _pdfHeaderRow(['Metode Pembayaran', 'Total', 'Transaksi']),
            for (final e in breakdown.entries)
              _pdfDataRow([
                e.key.toUpperCase(),
                AppFormatters.rupiah(e.value.totalAmount),
                '${e.value.count}',
              ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfTopProductsSection(List<_ProductSummary> topProducts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfSectionTitle('Produk Terlaris'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
          columnWidths: const {
            0: pw.FixedColumnWidth(22),
            1: pw.FlexColumnWidth(3),
            2: pw.FixedColumnWidth(28),
            3: pw.FlexColumnWidth(2.5),
          },
          children: [
            _pdfHeaderRow(['#', 'Produk', 'Qty', 'Total']),
            for (var i = 0; i < topProducts.length; i++)
              _pdfDataRow([
                '${i + 1}',
                topProducts[i].name,
                '${topProducts[i].qty}',
                AppFormatters.rupiah(topProducts[i].revenue),
              ], isAlt: i.isOdd),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfTransactionTable(List<SalesTransaction> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfSectionTitle('Detail Transaksi (${transactions.length})'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
          columnWidths: const {
            0: pw.FixedColumnWidth(20),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(3),
            3: pw.FixedColumnWidth(24),
            4: pw.FlexColumnWidth(1.5),
            5: pw.FlexColumnWidth(2.2),
          },
          children: [
            _pdfHeaderRow(['#', 'Tanggal', 'Produk', 'Qty', 'Metode', 'Total']),
            for (var i = 0; i < transactions.length; i++)
              _pdfDataRow([
                '${i + 1}',
                DateFormat('dd/MM/yy HH:mm').format(transactions[i].tanggal),
                transactions[i].namaBarang,
                '${transactions[i].qty}',
                transactions[i].metodePembayaran.toUpperCase(),
                AppFormatters.rupiah(transactions[i].totalHarga),
              ], isAlt: i.isOdd),
          ],
        ),
      ],
    );
  }

  pw.TableRow _pdfHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _brandColor),
      children: [
        for (final h in headers)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(
              h,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
            ),
          ),
      ],
    );
  }

  pw.TableRow _pdfDataRow(List<String> cells, {bool isAlt = false}) {
    return pw.TableRow(
      decoration: isAlt ? pw.BoxDecoration(color: _altRow) : null,
      children: [
        for (final c in cells)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
          ),
      ],
    );
  }

  // ── Excel ──────────────────────────────────────────────────────────────────

  List<int> _buildExcel({
    required List<SalesTransaction> transactions,
    required ReportPeriod period,
  }) {
    final xcel = Excel.createExcel();
    xcel.delete('Sheet1');

    _buildSummarySheet(xcel, transactions, period);
    _buildDetailSheet(xcel, transactions);

    return xcel.encode()!;
  }

  void _buildSummarySheet(
    Excel xcel,
    List<SalesTransaction> transactions,
    ReportPeriod period,
  ) {
    final sheet = xcel['Ringkasan'];

    final titleStyle = CellStyle(bold: true, fontSize: 14);
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.white,
    );
    final subStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
    );
    final altStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F9FF'),
    );

    var row = 0;

    _xCell(sheet, row, 0, 'Bakulan D. Frozen Food', titleStyle);
    row++;
    _xCell(
      sheet,
      row,
      0,
      'Laporan Penjualan ${_periodLabel(period)}  ·  ${_periodRangeText(period)}',
      CellStyle(bold: true),
    );
    row++;
    _xCell(sheet, row, 0, 'Dicetak: ${AppFormatters.date(DateTime.now())}');
    row += 2;

    // Ringkasan
    _xRow(sheet, row, ['RINGKASAN', ''], headerStyle);
    row++;

    final totalRevenue = transactions.fold<int>(0, (s, t) => s + t.totalHarga);
    final totalQty = transactions.fold<int>(0, (s, t) => s + t.qty);

    _xRow(sheet, row, [
      'Total Omzet',
      AppFormatters.rupiah(totalRevenue),
    ], subStyle);
    row++;
    _xRow(sheet, row, ['Jumlah Transaksi', '${transactions.length}']);
    row++;
    _xRow(sheet, row, ['Total Item Terjual', '$totalQty'], altStyle);
    row += 2;

    // Rincian pembayaran
    _xRow(sheet, row, ['RINCIAN PEMBAYARAN', '', ''], headerStyle);
    row++;
    _xRow(sheet, row, ['Metode', 'Total', 'Transaksi'], subStyle);
    row++;
    var isAlt = false;
    for (final e in _groupByPayment(transactions).entries) {
      _xRow(sheet, row, [
        e.key.toUpperCase(),
        AppFormatters.rupiah(e.value.totalAmount),
        '${e.value.count}',
      ], isAlt ? altStyle : null);
      isAlt = !isAlt;
      row++;
    }
    row++;

    // Produk terlaris
    final topProducts = _topProducts(transactions);
    if (topProducts.isNotEmpty) {
      _xRow(sheet, row, ['PRODUK TERLARIS', '', '', ''], headerStyle);
      row++;
      _xRow(sheet, row, ['#', 'Produk', 'Qty', 'Total'], subStyle);
      row++;
      for (var i = 0; i < topProducts.length; i++) {
        _xRow(sheet, row, [
          '${i + 1}',
          topProducts[i].name,
          '${topProducts[i].qty}',
          AppFormatters.rupiah(topProducts[i].revenue),
        ], i.isOdd ? altStyle : null);
        row++;
      }
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 18);
  }

  void _buildDetailSheet(Excel xcel, List<SalesTransaction> transactions) {
    final sheet = xcel['Detail Transaksi'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.white,
    );
    final altStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F9FF'),
    );

    _xRow(sheet, 0, [
      'No',
      'Tanggal',
      'Produk',
      'Qty',
      'Metode Pembayaran',
      'Total',
    ], headerStyle);

    for (var i = 0; i < transactions.length; i++) {
      final trx = transactions[i];
      _xRow(sheet, i + 1, [
        '${i + 1}',
        AppFormatters.date(trx.tanggal),
        trx.namaBarang,
        '${trx.qty}',
        trx.metodePembayaran.toUpperCase(),
        AppFormatters.rupiah(trx.totalHarga),
      ], i.isOdd ? altStyle : null);
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 32);
    sheet.setColumnWidth(3, 8);
    sheet.setColumnWidth(4, 20);
    sheet.setColumnWidth(5, 20);
  }

  void _xCell(Sheet sheet, int row, int col, String value, [CellStyle? style]) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    if (style != null) cell.cellStyle = style;
  }

  void _xRow(Sheet sheet, int row, List<String> values, [CellStyle? style]) {
    for (var i = 0; i < values.length; i++) {
      _xCell(sheet, row, i, values[i], style);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, _PaymentSummary> _groupByPayment(
    List<SalesTransaction> transactions,
  ) {
    final map = <String, _PaymentSummary>{};
    for (final trx in transactions) {
      final prev = map[trx.metodePembayaran];
      map[trx.metodePembayaran] = _PaymentSummary(
        totalAmount: (prev?.totalAmount ?? 0) + trx.totalHarga,
        count: (prev?.count ?? 0) + 1,
      );
    }
    return map;
  }

  List<_ProductSummary> _topProducts(List<SalesTransaction> transactions) {
    final map = <String, _ProductSummary>{};
    for (final trx in transactions) {
      final prev = map[trx.namaBarang];
      map[trx.namaBarang] = _ProductSummary(
        name: trx.namaBarang,
        qty: (prev?.qty ?? 0) + trx.qty,
        revenue: (prev?.revenue ?? 0) + trx.totalHarga,
      );
    }
    return (map.values.toList()..sort((a, b) => b.qty.compareTo(a.qty)))
        .take(10)
        .toList();
  }

  String _periodLabel(ReportPeriod period) => switch (period) {
    ReportPeriod.daily => 'Harian',
    ReportPeriod.weekly => 'Mingguan',
    ReportPeriod.monthly => 'Bulanan',
  };

  String _periodSlug(ReportPeriod period) => switch (period) {
    ReportPeriod.daily => 'harian',
    ReportPeriod.weekly => 'mingguan',
    ReportPeriod.monthly => 'bulanan',
  };

  String _periodRangeText(ReportPeriod period) {
    final now = DateTime.now();
    final fmt = DateFormat('d MMM yyyy', 'id_ID');
    return switch (period) {
      ReportPeriod.daily => fmt.format(now),
      ReportPeriod.weekly =>
        '${fmt.format(now.subtract(Duration(days: now.weekday - 1)))} – ${fmt.format(now)}',
      ReportPeriod.monthly => DateFormat('MMMM yyyy', 'id_ID').format(now),
    };
  }

  String _dateSlug() => DateFormat('yyyyMMdd').format(DateTime.now());
}

class _PaymentSummary {
  const _PaymentSummary({required this.totalAmount, required this.count});
  final int totalAmount;
  final int count;
}

class _ProductSummary {
  const _ProductSummary({
    required this.name,
    required this.qty,
    required this.revenue,
  });
  final String name;
  final int qty;
  final int revenue;
}
