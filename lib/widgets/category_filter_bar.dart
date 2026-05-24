import 'package:flutter/material.dart';

import '../models/category.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final value = category?.id;
          final selected = selectedCategoryId == value;

          return ChoiceChip(
            label: Text(isAll ? 'Semua' : category!.namaKategori),
            selected: selected,
            showCheckmark: false,
            avatar: isAll
                ? Icon(
                    Icons.apps_rounded,
                    size: 18,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  )
                : null,
            onSelected: (_) => onChanged(value),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: categories.length + 1,
      ),
    );
  }
}
