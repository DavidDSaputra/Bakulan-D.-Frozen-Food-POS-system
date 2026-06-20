import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_service.dart';
import '../utils/category_helpers.dart';
import '../utils/formatters.dart';
import '../utils/number_input_formatter.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'barcode_scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _expirationDateController;
  final _imagePicker = ImagePicker();
  final _cloudinaryService = CloudinaryService();
  Uint8List? _previewImageBytes;
  String? _selectedCategoryId;
  DateTime? _expirationDate;
  bool _isUploadingImage = false;
  bool _isActive = true;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.namaBarang ?? '');
    _purchasePriceController = TextEditingController(
      text: product == null ? '' : AppFormatters.number(product.hargaBeli),
    );
    _salePriceController = TextEditingController(
      text: product == null ? '' : AppFormatters.number(product.hargaJual),
    );
    _stockController = TextEditingController(
      text: product == null ? '' : AppFormatters.number(product.stok),
    );
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _expirationDate = product?.expirationDate;
    _expirationDateController = TextEditingController(
      text: _formatExpirationDate(_expirationDate),
    );
    _selectedCategoryId = product?.kategoriId.isEmpty == true
        ? null
        : product?.kategoriId;
    _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final actor = context.read<AuthProvider>().user;
    if (actor == null) {
      showAppSnackBar(context, 'Sesi pengguna tidak ditemukan', isError: true);
      return;
    }

    final product = Product(
      id: widget.product?.id ?? '',
      namaBarang: _nameController.text.trim(),
      hargaBeli: AppFormatters.parseNumberInput(_purchasePriceController.text)!,
      harga: AppFormatters.parseNumberInput(_salePriceController.text)!,
      stok: AppFormatters.parseNumberInput(_stockController.text)!,
      kategoriId: _selectedCategoryId ?? '',
      imageUrl: _imageUrlController.text.trim(),
      isActive: _isActive,
      barcode: _barcodeController.text.trim(),
      description: _descriptionController.text.trim(),
      expirationDate: _expirationDate,
    );

    try {
      await context.read<ProductProvider>().saveProduct(
        product,
        isEdit: _isEdit,
        actor: actor,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        _isEdit ? 'Barang berhasil diperbarui' : 'Barang berhasil ditambahkan',
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 20, 12, 31),
      helpText: 'Pilih tanggal kedaluwarsa',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _expirationDate = DateTime(picked.year, picked.month, picked.day);
      _expirationDateController.text = _formatExpirationDate(_expirationDate);
    });
  }

  void _clearExpirationDate() {
    setState(() {
      _expirationDate = null;
      _expirationDateController.clear();
    });
  }

  String _formatExpirationDate(DateTime? date) {
    if (date == null) return '';
    return AppFormatters.fullDate(date);
  }

  Future<void> _pickAndUploadImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _previewImageBytes = bytes);

      final imageUrl = await _cloudinaryService.uploadProductImage(
        bytes: bytes,
        fileName: image.name,
      );
      if (!mounted) return;

      _imageUrlController.text = imageUrl;
      showAppSnackBar(context, 'Gambar produk berhasil diupload');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          error.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null || !mounted) return;
    _barcodeController.text = result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = _imageUrlController.text.trim();
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Barang' : 'Tambah Barang')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: .5,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: .5),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_previewImageBytes != null)
                          Image.memory(_previewImageBytes!, fit: BoxFit.cover)
                        else if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _ImagePlaceholder(scheme: scheme),
                          )
                        else
                          _ImagePlaceholder(scheme: scheme),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 76,
                            color: Colors.black.withValues(alpha: .28),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: FilledButton.icon(
                            onPressed: _isUploadingImage
                                ? null
                                : _pickAndUploadImage,
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_rounded),
                            label: Text(
                              _isUploadingImage
                                  ? 'Mengupload...'
                                  : 'Pilih Gambar Produk',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _nameController,
                    label: 'Nama Barang',
                    icon: Icons.fastfood_rounded,
                    validator: (value) =>
                        Validators.requiredText(value, field: 'Nama barang'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _purchasePriceController,
                    label: 'Harga Modal',
                    icon: Icons.shopping_bag_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandSeparatorInputFormatter()],
                    validator: (value) => Validators.nonNegativeNumber(
                      value,
                      field: 'Harga modal',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _salePriceController,
                    label: 'Harga Jual',
                    icon: Icons.sell_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandSeparatorInputFormatter()],
                    validator: (value) =>
                        Validators.positiveNumber(value, field: 'Harga jual'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _stockController,
                    label: 'Stok',
                    icon: Icons.inventory_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandSeparatorInputFormatter()],
                    validator: (value) =>
                        Validators.nonNegativeNumber(value, field: 'Stok'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _barcodeController,
                    label: 'Barcode',
                    icon: Icons.qr_code_2_rounded,
                    keyboardType: TextInputType.text,
                    suffixIcon: IconButton(
                      tooltip: 'Scan barcode',
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<List<ProductCategory>>(
                    stream: context.read<ProductProvider>().watchCategories(),
                    builder: (context, snapshot) {
                      final categories = CategoryHelpers.merge(
                        snapshot.data ?? const [],
                      );
                      final hasSelectedCategory =
                          _selectedCategoryId != null &&
                          categories.any(
                            (category) => category.id == _selectedCategoryId,
                          );
                      final items = [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.namaKategori),
                          ),
                        if (_selectedCategoryId != null && !hasSelectedCategory)
                          DropdownMenuItem(
                            value: _selectedCategoryId,
                            child: Text(
                              CategoryHelpers.readableId(_selectedCategoryId!),
                            ),
                          ),
                      ];

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        items: items,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        hint: Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Memuat kategori...'
                              : 'Pilih kategori barang',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Kategori wajib dipilih'
                            : null,
                        onChanged: items.isEmpty
                            ? null
                            : (value) {
                                setState(() => _selectedCategoryId = value);
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    minLines: 2,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expirationDateController,
                    readOnly: true,
                    onTap: _pickExpirationDate,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Kedaluwarsa',
                      prefixIcon: const Icon(Icons.event_rounded),
                      suffixIcon: _expirationDate == null
                          ? const Icon(Icons.calendar_month_rounded)
                          : IconButton(
                              tooltip: 'Kosongkan tanggal kedaluwarsa',
                              onPressed: _clearExpirationDate,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _imageUrlController,
                    label: 'URL Gambar Produk Cloudinary',
                    icon: Icons.image_rounded,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    value: _isActive,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Barang aktif',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Barang tampil di kasir'
                          : 'Barang disembunyikan dari penjualan',
                    ),
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 24),
                  Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      return AppButton(
                        label: 'Simpan',
                        icon: Icons.save_rounded,
                        isLoading: provider.isLoading,
                        onPressed: _save,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              color: scheme.onSurfaceVariant,
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada gambar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
