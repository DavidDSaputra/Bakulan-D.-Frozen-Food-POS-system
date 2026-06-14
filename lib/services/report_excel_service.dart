import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sales_transaction.dart';
import '../utils/formatters.dart';

class ReportExcelService {
  static final _blue = ExcelColor.fromHexString('FF1E5A9B');
  static final _lightBlue = ExcelColor.fromHexString('FFEAF2FF');
  static final _darkText = ExcelColor.fromHexString('FF1F2937');
  static final _mutedText = ExcelColor.fromHexString('FF667085');
  static final _borderColor = ExcelColor.fromHexString('FFD0D5DD');
  static final _moneyFormat = NumFormat.custom(formatCode: '"Rp" #,##0');

  Future<void> shareReport({
    required List<SalesTransaction> transactions,
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final bytes = _buildReport(
      transactions: transactions,
      periodLabel: periodLabel,
      startDate: startDate,
      endDate: endDate,
    );
    final filename = _filename(periodLabel, startDate);

    await SharePlus.instance.share(
      ShareParams(
        title: 'Laporan Penjualan $periodLabel',
        text: 'Laporan Penjualan Bakulan D. Frozen',
        files: [
          XFile.fromData(
            bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: filename,
          ),
        ],
        downloadFallbackEnabled: true,
      ),
    );
  }

  Uint8List _buildReport({
    required List<SalesTransaction> transactions,
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Ringkasan');

    final paymentTotals = _groupByPayment(transactions);
    final productTotals = _groupByProduct(transactions);
    final revenue = transactions.fold<int>(
      0,
      (sum, trx) => sum + trx.totalHarga,
    );
    final totalQty = transactions.fold<int>(0, (sum, trx) => sum + trx.qty);

    _buildSummarySheet(
      excel['Ringkasan'],
      periodLabel: periodLabel,
      startDate: startDate,
      endDate: endDate,
      revenue: revenue,
      totalQty: totalQty,
      transactionCount: transactions.length,
      paymentTotals: paymentTotals,
    );
    _buildProductSheet(excel['Produk'], productTotals);
    _buildTransactionSheet(excel['Transaksi'], transactions);

    excel.setDefaultSheet('Ringkasan');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? const <int>[]);
  }

  void _buildSummarySheet(
    Sheet sheet, {
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
    required int revenue,
    required int totalQty,
    required int transactionCount,
    required Map<String, int> paymentTotals,
  }) {
    _setupColumns(sheet, const [24, 22, 18, 18]);
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('D1'),
      customValue: _text('Bakulan D. Frozen'),
    );
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('D2'),
      customValue: _text('Laporan Penjualan $periodLabel'),
    );

    _styleCell(sheet, 0, 0, _titleStyle);
    _styleCell(sheet, 1, 0, _subtitleStyle);
    sheet.setRowHeight(0, 26);
    sheet.setRowHeight(1, 22);

    _put(sheet, 3, 0, _text('Periode'), style: _labelStyle);
    _put(sheet, 3, 1, _text(_rangeLabel(startDate, endDate)));
    _put(sheet, 4, 0, _text('Dicetak'), style: _labelStyle);
    _put(sheet, 4, 1, _text(AppFormatters.date(DateTime.now())));

    _section(sheet, 6, 'Ringkasan Utama');
    _put(sheet, 7, 0, _text('Total Omzet'), style: _labelStyle);
    _put(sheet, 7, 1, _int(revenue), style: _moneyStyle);
    _put(sheet, 8, 0, _text('Item Terjual'), style: _labelStyle);
    _put(sheet, 8, 1, _int(totalQty), style: _numberStyle);
    _put(sheet, 9, 0, _text('Jumlah Transaksi'), style: _labelStyle);
    _put(sheet, 9, 1, _int(transactionCount), style: _numberStyle);

    _section(sheet, 11, 'Metode Pembayaran');
    _headerRow(sheet, 12, ['Metode', 'Omzet']);
    var row = 13;
    for (final entry in paymentTotals.entries) {
      _put(sheet, row, 0, _text(entry.key.toUpperCase()), style: _bodyStyle);
      _put(sheet, row, 1, _int(entry.value), style: _moneyStyle);
      row++;
    }
  }

  void _buildProductSheet(
    Sheet sheet,
    Map<String, _ProductReportTotal> productTotals,
  ) {
    _setupColumns(sheet, const [32, 12, 18]);
    _sheetTitle(sheet, 'Produk Terjual');
    _headerRow(sheet, 2, ['Produk', 'Qty', 'Omzet']);

    var row = 3;
    for (final entry in productTotals.entries) {
      _put(sheet, row, 0, _text(entry.key), style: _bodyStyle);
      _put(sheet, row, 1, _int(entry.value.qty), style: _numberStyle);
      _put(sheet, row, 2, _int(entry.value.revenue), style: _moneyStyle);
      row++;
    }
  }

  void _buildTransactionSheet(
    Sheet sheet,
    List<SalesTransaction> transactions,
  ) {
    _setupColumns(sheet, const [22, 30, 10, 14, 18]);
    _sheetTitle(sheet, 'Rincian Transaksi');
    _headerRow(sheet, 2, ['Tanggal', 'Produk', 'Qty', 'Metode', 'Total']);

    var row = 3;
    for (final trx in transactions) {
      _put(
        sheet,
        row,
        0,
        _text(AppFormatters.date(trx.tanggal)),
        style: _bodyStyle,
      );
      _put(sheet, row, 1, _text(trx.namaBarang), style: _bodyStyle);
      _put(sheet, row, 2, _int(trx.qty), style: _numberStyle);
      _put(
        sheet,
        row,
        3,
        _text(trx.metodePembayaran.toUpperCase()),
        style: _bodyStyle,
      );
      _put(sheet, row, 4, _int(trx.totalHarga), style: _moneyStyle);
      row++;
    }
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

  void _sheetTitle(Sheet sheet, String title) {
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
      customValue: _text(title),
    );
    _styleCell(sheet, 0, 0, _titleStyle);
    sheet.setRowHeight(0, 26);
  }

  void _section(Sheet sheet, int row, String title) {
    _put(sheet, row, 0, _text(title), style: _sectionStyle);
  }

  void _headerRow(Sheet sheet, int row, List<String> labels) {
    for (var col = 0; col < labels.length; col++) {
      _put(sheet, row, col, _text(labels[col]), style: _headerStyle);
    }
    sheet.setRowHeight(row, 22);
  }

  void _setupColumns(Sheet sheet, List<double> widths) {
    sheet.setDefaultRowHeight(19);
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  void _put(
    Sheet sheet,
    int row,
    int col,
    CellValue value, {
    CellStyle? style,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  void _styleCell(Sheet sheet, int row, int col, CellStyle style) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .cellStyle =
        style;
  }

  TextCellValue _text(String value) => TextCellValue(value);

  IntCellValue _int(int value) => IntCellValue(value);

  CellStyle get _titleStyle => CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: _blue,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle get _subtitleStyle => CellStyle(
    bold: true,
    fontSize: 12,
    fontColorHex: _darkText,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle get _sectionStyle => CellStyle(
    bold: true,
    fontColorHex: _blue,
    backgroundColorHex: _lightBlue,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle get _headerStyle => CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: _blue,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
    topBorder: _thinBorder,
    bottomBorder: _thinBorder,
  );

  CellStyle get _labelStyle => CellStyle(
    bold: true,
    fontColorHex: _mutedText,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle get _bodyStyle => CellStyle(
    fontColorHex: _darkText,
    verticalAlign: VerticalAlign.Center,
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
    topBorder: _thinBorder,
    bottomBorder: _thinBorder,
  );

  CellStyle get _numberStyle => _bodyStyle.copyWith(
    horizontalAlignVal: HorizontalAlign.Right,
    numberFormat: NumFormat.standard_3,
  );

  CellStyle get _moneyStyle => _bodyStyle.copyWith(
    horizontalAlignVal: HorizontalAlign.Right,
    numberFormat: _moneyFormat,
  );

  Border get _thinBorder =>
      Border(borderStyle: BorderStyle.Thin, borderColorHex: _borderColor);

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

  String _filename(String periodLabel, DateTime startDate) {
    return 'laporan-bakulan-${periodLabel.toLowerCase()}-${_fileDate(startDate)}.xlsx';
  }
}

class _ProductReportTotal {
  const _ProductReportTotal({this.qty = 0, this.revenue = 0});

  final int qty;
  final int revenue;
}
