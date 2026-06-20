import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/app_theme.dart';
import '../utils/category_helpers.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _orange = AppTheme.brandPrimary;
  static const _page = AppTheme.brandSurface;
  static const _text = AppTheme.brandInk;
  static const _muted = Color(0xFF8A94A6);

  void _openEdit(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Hapus ${product.namaBarang} dari daftar barang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final actor = context.read<AuthProvider>().user;
    if (actor == null) {
      showAppSnackBar(context, 'Sesi pengguna tidak ditemukan', isError: true);
      return;
    }

    try {
      await context.read<ProductProvider>().deleteProduct(product, actor);
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(context, 'Barang berhasil dihapus');
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

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().user?.isOwner == true;

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _orange,
        titleSpacing: 0,
        title: const Text(
          'Detail Barang',
          style: TextStyle(fontWeight: FontWeight.w900, color: _orange),
        ),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              iconColor: _orange,
              onSelected: (value) {
                if (value == 'edit') _openEdit(widget.product);
                if (value == 'delete') _deleteProduct(widget.product);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: context.read<ProductProvider>().watchProducts(),
        builder: (context, productSnapshot) {
          if (!productSnapshot.hasData) return const AppLoadingIndicator();

          final products = productSnapshot.data!;
          Product? product;
          for (final item in products) {
            if (item.id == widget.product.id) {
              product = item;
              break;
            }
          }

          if (product == null) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Barang tidak ditemukan',
              subtitle: 'Data barang ini sudah tidak tersedia.',
            );
          }
          final currentProduct = product;

          return StreamBuilder<List<ProductCategory>>(
            stream: context.read<ProductProvider>().watchCategories(),
            builder: (context, categorySnapshot) {
              final categories = CategoryHelpers.merge(
                categorySnapshot.data ?? const [],
              );
              final categoryName = _categoryName(currentProduct, categories);

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  const SizedBox(height: 18),
                  Center(child: _ProductImage(product: currentProduct)),
                  const SizedBox(height: 14),
                  _ProductInfoCard(
                    product: currentProduct,
                    categoryName: categoryName,
                    canEdit: isOwner,
                    onEdit: () => _openEdit(currentProduct),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _categoryName(Product product, List<ProductCategory> categories) {
    if (product.kategoriId.trim().isEmpty) return '-';
    for (final category in categories) {
      if (category.id == product.kategoriId) return category.namaKategori;
    }
    return CategoryHelpers.readableId(product.kategoriId);
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl.trim().isNotEmpty;

    return Hero(
      tag: 'product-image-${product.id}',
      child: Container(
        width: 86,
        height: 86,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: hasImage
            ? Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                cacheWidth: 720,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_rounded,
                  color: _ProductDetailScreenState._orange,
                ),
              )
            : const Icon(
                Icons.inventory_2_rounded,
                color: _ProductDetailScreenState._orange,
              ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({
    required this.product,
    required this.categoryName,
    required this.canEdit,
    required this.onEdit,
  });

  final Product product;
  final String categoryName;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Informasi Barang',
                  style: TextStyle(
                    color: _ProductDetailScreenState._text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (canEdit)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: _ProductDetailScreenState._text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.edit_square,
                          size: 17,
                          color: _ProductDetailScreenState._text,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(label: 'Nama Barang', value: product.namaBarang),
          _InfoRow(
            label: 'Barcode',
            value: _readable(product.barcode, product.id),
          ),
          _InfoRow(label: 'Stok', value: '${product.stok}'),
          _InfoRow(
            label: 'Kategori',
            value: categoryName,
            valueBuilder: (value) => Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB9C6D8)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _ProductDetailScreenState._text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          _InfoRow(
            label: 'Harga Jual',
            value: AppFormatters.rupiah(product.hargaJual),
          ),
          _InfoRow(
            label: 'Harga Modal',
            value: AppFormatters.rupiah(product.hargaBeli),
          ),
          _InfoRow(
            label: 'Deskripsi',
            value: _readable(product.description, '-'),
            maxLines: 3,
          ),
          _InfoRow(
            label: 'Tanggal Kedaluwarsa',
            value: _formatExpirationDate(product.expirationDate),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  static String _readable(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _formatExpirationDate(DateTime? date) {
    if (date == null) return '-';
    return AppFormatters.fullDate(date);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueBuilder,
    this.maxLines = 2,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Widget Function(String value)? valueBuilder;
  final int maxLines;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final valueWidget =
        valueBuilder?.call(value) ??
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ProductDetailScreenState._text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ProductDetailScreenState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 9),
            child: Divider(height: 1, color: Color(0xFFE8ECF1)),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}
