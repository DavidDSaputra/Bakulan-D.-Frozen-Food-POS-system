import 'package:cloud_firestore/cloud_firestore.dart';

class SeedDataService {
  static Future<void> seedFrozenFoodProducts() async {
    final db = FirebaseFirestore.instance;

    try {
      // Check if category "Frozen Food" already exists
      final categoryQuery = await db
          .collection('kategori')
          .where('nama_kategori', isEqualTo: 'Frozen Food')
          .limit(1)
          .get();

      late String frozenFoodCategoryId;

      if (categoryQuery.docs.isEmpty) {
        // Create "Frozen Food" category
        final categoryRef = await db.collection('kategori').add({
          'nama_kategori': 'Frozen Food',
        });
        frozenFoodCategoryId = categoryRef.id;
      } else {
        frozenFoodCategoryId = categoryQuery.docs.first.id;
      }

      // List of 20 frozen food products with new image URLs
      final frozenFoodProducts = [
        {
          'nama': 'Daging Sapi Beku',
          'harga': 85000,
          'stok': 25,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=1',
        },
        {
          'nama': 'Daging Ayam Fillet',
          'harga': 45000,
          'stok': 30,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=2',
        },
        {
          'nama': 'Udang Vaname Beku',
          'harga': 75000,
          'stok': 20,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=3',
        },
        {
          'nama': 'Ikan Salmon Fillet',
          'harga': 95000,
          'stok': 15,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=4',
        },
        {
          'nama': 'Bakso Sapi Beku',
          'harga': 35000,
          'stok': 40,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=5',
        },
        {
          'nama': 'Nugget Ayam',
          'harga': 28000,
          'stok': 45,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=6',
        },
        {
          'nama': 'Sosis Sapi',
          'harga': 22000,
          'stok': 35,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=7',
        },
        {
          'nama': 'Perkedel Beku',
          'harga': 18000,
          'stok': 50,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=8',
        },
        {
          'nama': 'Tahu Goreng Beku',
          'harga': 12000,
          'stok': 60,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=9',
        },
        {
          'nama': 'Lumpia Beku',
          'harga': 25000,
          'stok': 38,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=10',
        },
        {
          'nama': 'Martabak Beku',
          'harga': 32000,
          'stok': 32,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=11',
        },
        {
          'nama': 'Ikan Tenggiri Fillet',
          'harga': 68000,
          'stok': 18,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=12',
        },
        {
          'nama': 'Cumi-Cumi Beku',
          'harga': 55000,
          'stok': 16,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=13',
        },
        {
          'nama': 'Paru Sapi Beku',
          'harga': 38000,
          'stok': 22,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=14',
        },
        {
          'nama': 'Hati Ayam Beku',
          'harga': 32000,
          'stok': 26,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=15',
        },
        {
          'nama': 'Tempe Goreng Beku',
          'harga': 15000,
          'stok': 70,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=16',
        },
        {
          'nama': 'Otak Sapi Beku',
          'harga': 42000,
          'stok': 14,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=17',
        },
        {
          'nama': 'Kerang Beku',
          'harga': 58000,
          'stok': 19,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=18',
        },
        {
          'nama': 'Scallop Beku',
          'harga': 72000,
          'stok': 17,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=19',
        },
        {
          'nama': 'Es Krim Vanilla',
          'harga': 18000,
          'stok': 55,
          'imageUrl': 'https://loremflickr.com/300/300/food?lock=20',
        },
      ];

      // Check existing products to avoid duplicates
      final existingProducts = await db
          .collection('barang')
          .where('kategori_id', isEqualTo: frozenFoodCategoryId)
          .get();

      final existingNames = existingProducts.docs
          .map((doc) => doc['nama_barang'])
          .toSet();

      // Add products that don't exist yet
      for (final product in frozenFoodProducts) {
        if (!existingNames.contains(product['nama'])) {
          await db.collection('barang').add({
            'nama_barang': product['nama'],
            'harga': product['harga'],
            'harga_beli': ((product['harga'] as int) * .72).round(),
            'harga_jual': product['harga'],
            'stok': product['stok'],
            'kategori_id': frozenFoodCategoryId,
            'image_url': product['imageUrl'],
            'is_active': true,
          });
        } else {
          // Update existing products with new image URL if needed
          final existingDoc = existingProducts.docs.firstWhere(
            (doc) => doc['nama_barang'] == product['nama'],
          );
          final existingData = existingDoc.data();
          await existingDoc.reference.update({
            'image_url': product['imageUrl'],
            'harga_beli': existingData.containsKey('harga_beli')
                ? existingData['harga_beli']
                : ((product['harga'] as int) * .72).round(),
            'harga_jual': product['harga'],
            'is_active': existingData.containsKey('is_active')
                ? existingData['is_active']
                : true,
          });
        }
      }
    } catch (e) {
      // Seed error handled silently
      rethrow;
    }
  }
}
