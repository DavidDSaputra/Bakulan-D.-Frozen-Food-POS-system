import '../models/category.dart';

class CategoryHelpers {
  static const defaultCategories = [
    ProductCategory(id: 'frozen_food', namaKategori: 'Frozen Food'),
    ProductCategory(id: 'sembako', namaKategori: 'Sembako'),
    ProductCategory(id: 'lain_lain', namaKategori: 'Lain-lain'),
  ];

  static List<ProductCategory> merge(
    List<ProductCategory> firestoreCategories,
  ) {
    final categories = <String, ProductCategory>{};
    final names = <String>{};

    for (final category in defaultCategories) {
      categories[category.id] = category;
      names.add(normalizeName(category.namaKategori));
    }

    for (final category in firestoreCategories) {
      final normalizedName = normalizeName(category.namaKategori);
      if (categories.containsKey(category.id) ||
          names.contains(normalizedName)) {
        continue;
      }
      categories[category.id] = category;
      names.add(normalizedName);
    }

    return categories.values.toList()
      ..sort((a, b) => a.namaKategori.compareTo(b.namaKategori));
  }

  static String readableId(String id) {
    return id
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'[\s_\-]+'), ' ').toLowerCase();
  }
}
