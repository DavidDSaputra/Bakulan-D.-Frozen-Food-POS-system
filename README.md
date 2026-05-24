# Bakulan D. Frozen POS

Aplikasi mobile Flutter untuk project kampus:

**Analisis dan Perancangan Sistem Informasi Penjualan dan Manajemen Stok Berbasis Mobile pada UMKM Bakulan D. Frozen**

## Teknologi

- Flutter
- Firebase Authentication
- Cloud Firestore
- Provider
- Cloudinary

## Fitur

- Splash screen dan login
- Role owner dan petugas/kasir
- Dashboard statistik
- Kelola barang: tambah, edit, hapus, cari
- Filter barang berdasarkan kategori
- Upload dan tampilkan gambar produk
- Kelola stok dan update stok
- Input barang masuk/restock, stok otomatis bertambah
- Riwayat stok masuk dan keluar untuk owner
- Input penjualan dengan validasi stok
- Pembayaran cash, QRIS, transfer
- Share PDF struk
- Laporan penjualan harian, mingguan, bulanan dengan grafik
- Dark mode
- Bottom navigation

## Struktur Firestore

Collection `users`

```text
id
nama
username
role: owner | kasir
```

Password dikelola oleh Firebase Authentication. Field `password` tidak disimpan sebagai plaintext di Firestore agar lebih aman.

Collection `kategori`

```text
id
nama_kategori
```

Contoh kategori:

```text
frozen_food -> Frozen Food
sembako -> Sembako
lain_lain -> Lain-lain
```

Collection `barang`

```text
id
nama_barang
harga
stok
kategori_id
image_url
```

Collection `transaksi`

```text
id
tanggal
nama_barang
qty
total_harga
metode_pembayaran
id_user
barang_id
```

Collection tambahan `barang_masuk` dipakai untuk riwayat restock.

## Setup Firebase

1. Buat project Firebase.
2. Aktifkan Authentication dengan metode Email/Password.
3. Aktifkan Cloud Firestore.
4. Jalankan:

```bash
flutterfire configure
```

5. Ganti isi `lib/firebase_options.dart` dengan hasil konfigurasi asli dari Firebase.
6. Buat user di Firebase Authentication. Untuk username `kasir`, gunakan email:

```text
kasir@bakulandfrozen.local
```

7. Buat dokumen profile di `users` dengan ID sama seperti UID Firebase Auth.

Contoh owner:

```json
{
  "nama": "Owner Bakulan",
  "username": "owner",
  "role": "owner"
}
```

## Setup Cloudinary

1. Buat akun dan cloud di Cloudinary.
2. Buka **Settings > Upload**.
3. Buat **unsigned upload preset** untuk upload dari aplikasi mobile.
4. Aplikasi sudah memakai default Cloudinary:

```text
CLOUDINARY_CLOUD_NAME=dop6ml3pj
CLOUDINARY_UPLOAD_PRESET=bakulan_unsigned
```

Kalau ingin mengganti cloud atau preset, jalankan aplikasi dengan konfigurasi:

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=nama_cloud --dart-define=CLOUDINARY_UPLOAD_PRESET=nama_upload_preset
```

Gambar produk akan diupload ke folder `bakulan-products` di Cloudinary. Firestore hanya menyimpan URL gambar pada field `image_url`.

Contoh kasir:

```json
{
  "nama": "Petugas Kasir",
  "username": "kasir",
  "role": "kasir"
}
```

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

## Verifikasi

```bash
flutter analyze
flutter test
```
