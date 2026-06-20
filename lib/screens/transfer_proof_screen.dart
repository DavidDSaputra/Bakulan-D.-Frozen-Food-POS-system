import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/sale_item.dart';
import '../models/app_user.dart';
import '../models/transfer_payment_option.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sales_provider.dart';
import '../services/cloudinary_service.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/app_button.dart';
import 'receipt_screen.dart';

class TransferProofScreen extends StatefulWidget {
  const TransferProofScreen({
    super.key,
    required this.items,
    required this.method,
    required this.option,
    required this.actor,
  });

  final List<SaleItem> items;
  final String method;
  final TransferPaymentOption option;
  final AppUser? actor;

  @override
  State<TransferProofScreen> createState() => _TransferProofScreenState();
}

class _TransferProofScreenState extends State<TransferProofScreen> {
  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();

  Uint8List? _proofBytes;
  String? _proofFileName;
  bool _isSubmitting = false;

  int get _total => widget.items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _pickProof(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _proofBytes = bytes;
      _proofFileName = image.name;
    });
  }

  Future<void> _copyAccountNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.option.accountNumber));
    if (!mounted) return;
    showAppSnackBar(context, 'Nomor tujuan disalin');
  }

  Future<void> _submitPayment() async {
    final proofBytes = _proofBytes;
    final proofFileName = _proofFileName;
    if (proofBytes == null || proofFileName == null) {
      showAppSnackBar(
        context,
        'Upload foto bukti pembayaran dulu',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final items = List<SaleItem>.unmodifiable(widget.items);
    final method = widget.method;
    final option = widget.option;
    final total = _total;
    try {
      final proofUrl = await _cloudinaryService.uploadPaymentProof(
        bytes: proofBytes,
        fileName: proofFileName,
      );
      if (proofUrl.isEmpty) {
        throw Exception('Upload bukti pembayaran tidak menghasilkan URL.');
      }
      if (!mounted) return;

      final actor = widget.actor ?? context.read<AuthProvider>().user;
      if (actor == null) {
        throw Exception('Sesi pengguna tidak ditemukan');
      }
      await context.read<SalesProvider>().processSale(
        items: items,
        metodePembayaran: method,
        actor: actor,
        paymentProofUrl: proofUrl,
        paymentAccountName: option.accountName,
        paymentAccountNumber: option.accountNumber,
      );
      if (!mounted) return;

      context.read<CartProvider>().clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            items: items,
            method: method,
            paid: total,
            cashierName: actor.nama,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, _paymentErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _paymentErrorMessage(Object error) {
    final message = error.toString().replaceAll('Exception: ', '');
    if (message.contains('cloud_firestore/permission-denied')) {
      return 'Firestore menolak update stok. Publish firestore.rules terbaru dulu.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bukti Transfer')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProofBrandMark(option: widget.option),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.option.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                widget.option.typeLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _infoRow('Nomor Tujuan', widget.option.accountNumber),
                    _infoRow('Atas Nama', widget.option.accountName),
                    _infoRow('Total Transfer', AppFormatters.rupiah(_total)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _copyAccountNumber,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Salin Nomor Tujuan'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bukti Pembayaran',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _ProofPickerCard(
              bytes: _proofBytes,
              onCamera: () => _pickProof(ImageSource.camera),
              onGallery: () => _pickProof(ImageSource.gallery),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Konfirmasi & Proses',
              icon: Icons.verified_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitPayment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPickerCard extends StatelessWidget {
  const _ProofPickerCard({
    required this.bytes,
    required this.onCamera,
    required this.onGallery,
  });

  final Uint8List? bytes;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: bytes == null
                ? ColoredBox(
                    color: scheme.surfaceContainerHighest.withValues(alpha: .5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 46,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada bukti',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  )
                : Image.memory(bytes!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Foto'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofBrandMark extends StatelessWidget {
  const _ProofBrandMark({required this.option});

  final TransferPaymentOption option;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: option.color,
        borderRadius: BorderRadius.circular(13),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            option.logoText,
            style: TextStyle(
              color: option.foreground,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
