# Garden Barbershop Finance

Aplikasi Flutter untuk skripsi:

**Rancang Bangun Aplikasi Android Pengelolaan Pendapatan dan Pembagian Hasil Capster pada Garden Barbershop Berbasis Firebase**

## Fitur

- Login pengguna berdasarkan role.
- Dashboard ringkasan pendapatan, operasional, capster aktif, bagian capster, dan bagian pondok.
- Admin/Pengelola dapat mengelola akun pengguna, capster, layanan, buku kas umum, operasional, dan laporan.
- Admin Harian atau capster senior dapat membantu input pendapatan harian.
- Capster hanya dapat melihat laporan yang terkait dengan akun capster miliknya.
- Pemilik dapat memantau laporan usaha.
- Input pendapatan harian otomatis menghitung customer santri dan customer umum.
- Laporan pembagian hasil otomatis menghitung bagian capster dan bagian pondok.
- Pendapatan Usaha pada buku kas umum berasal dari total bagian pondok.
- Data disimpan ke Cloud Firestore.
- Fallback dummy data tersedia jika Firebase belum dikonfigurasi.

## Akun Login Prototype

```text
Admin
username: admin
password: admin123

Admin Harian / Capster Senior
username: senior
password: senior123

Capster
username: diva
password: capster123

Pemilik
username: pemilik
password: pemilik123
```

## Cara Menjalankan

Pastikan Flutter SDK sudah terpasang.

```bash
cd garden_barbershop_finance
flutter pub get
flutter run
```

Jika folder platform belum tersedia, jalankan:

```bash
flutter create .
flutter pub get
flutter run
```

## Konfigurasi Firebase

Aplikasi menggunakan `firebase_core` dan `cloud_firestore`. Jika Firebase belum dikonfigurasi, aplikasi tetap dapat berjalan menggunakan dummy data sehingga UI dan alur pengujian skripsi masih bisa diuji.

Langkah umum konfigurasi:

1. Buat project Firebase di Firebase Console.
2. Tambahkan aplikasi Android sesuai package name project.
3. Unduh file `google-services.json`.
4. Letakkan file tersebut di:

```text
android/app/google-services.json
```

5. Pastikan package name Android pada Firebase memakai:

```text
com.example.garden_barbershop_finance
```

6. Aktifkan Cloud Firestore.
7. Jalankan `flutter pub get`.
8. Jalankan aplikasi dengan `flutter run`.

Plugin Google Services pada Android diterapkan otomatis hanya jika file `android/app/google-services.json` tersedia. Jika file tersebut belum ada, build tetap dapat berjalan dan aplikasi memakai dummy data.

Catatan: untuk pengembangan skripsi, aturan Firestore dapat dibuat sementara sesuai kebutuhan pengujian. Untuk produksi, aturan akses harus dibatasi berdasarkan autentikasi dan role pengguna.

## Struktur Collection Firestore

Gunakan collection berikut.

### capster

```text
id_capster, nama_capster, no_hp, status
```

### layanan

```text
id_layanan, kode_layanan, nama_layanan, harga, kategori, status
```

Kode layanan:

```text
SN = Santri
RC/RG = Reguler Haircut
PC = Premium Cut
GC = Garden Cut
CJ = Cukur Jenggot/Kumis
KR = Keramas
CH = Coloring Hair
HS = Home Service
PR = Perming
KM = Kartu Member / Cukur Gratis Member
```

### pendapatan_harian

```text
id_pendapatan, tanggal, id_capster, nama_capster, SN, RC, PC, GC, CJ, KR, CH, HS, PR, KM, pendapatan, CS, CU, total_customer
```

### buku_kas_umum

```text
id_kas, tanggal, uraian, akun, penerimaan, pengeluaran, saldo, keterangan
```

### operasional

```text
id_operasional, bulan, nama_biaya, akun, nominal, keterangan
```

### laporan_bulanan

```text
bulan, id_capster, nama_capster, pendapatan_kotor, total_operasional, operasional_per_capster, pendapatan_bersih, bagian_capster, bagian_pondok
```

### rekap_customer

```text
id_rekap, tanggal, total_pendapatan, customer_santri, customer_umum, total_customer
```

### users

```text
id_user, username, password, nama, role, status, id_capster
```

Nilai role:

```text
admin
adminHarian
capster
pemilik
```

## Rumus Pembagian Hasil

```text
Beban Operasional Per Capster = Total Operasional Bulanan / Jumlah Capster Aktif
Pendapatan Bersih Capster = Pendapatan Kotor Capster - Beban Operasional Per Capster
Bagian Capster = Pendapatan Bersih Capster x 50%
Bagian Pondok = Pendapatan Bersih Capster x 50%
```

Contoh:

```text
Total operasional bulanan = Rp1.579.620
Jumlah capster aktif = 3
Beban operasional per capster = Rp526.540

Pendapatan Muhamad Diva Syarri = Rp1.809.000
Pendapatan bersih = Rp1.282.460
Bagian capster = Rp641.230
Bagian pondok = Rp641.230
```

## Struktur Project

```text
lib/
  main.dart
  app.dart
  models/
  services/
    firebase_service.dart
    auth_service.dart
    calculation_service.dart
  screens/
  widgets/
  utils/
```
