import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/formatters.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stockColor = product.isOutOfStock
        ? scheme.error
        : product.isLowStock
        ? const Color(0xFFE69A26)
        : scheme.primary;
    final statusColor = product.isActive ? stockColor : scheme.outline;
    final hasImage = product.imageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .36)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .06),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: hasImage
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 140,
                        cacheHeight: 140,
                        filterQuality: FilterQuality.low,
                        gaplessPlayback: true,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(
                                scheme.primary.withValues(alpha: .5),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_rounded,
                          color: scheme.primary,
                        ),
                      )
                    : Icon(Icons.ac_unit_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AppFormatters.rupiah(product.hargaJual),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Stok ${product.stok}',
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Off',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (product.isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Kedaluwarsa',
                              style: TextStyle(
                                color: scheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else if (product.isExpiringSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE69A26,
                              ).withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Segera kedaluwarsa',
                              style: TextStyle(
                                color: Color(0xFFE69A26),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
