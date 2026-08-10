import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/neraca_model.dart';

class MigrationService {
  static Future<void> migrateJuliData() async {
    final db = FirebaseFirestore.instance;

    print("Membersihkan data migrasi yang salah...");
    final collections = ['operasional', 'buku_kas', 'buku_kas_umum', 'pendapatan_harian', 'laporan', 'laporan_bulanan', 'rekap_customer'];
    for (var col in collections) {
      final snap = await db.collection(col).get();
      for (var doc in snap.docs) {
        if (doc.data()['bulan']?.toString().contains('Juli 2026') == true ||
            doc.data()['tanggal']?.toString().contains('2026-07') == true ||
            doc.data()['tanggal']?.toString().contains('2026-06') == true ||
            doc.data()['tanggal']?.toString().contains('2026-05') == true) {
          await doc.reference.delete();
        }
      }
    }

    print("Mulai Migrasi Data Juli 2026 (Format Benar)...");

    // 1. Operasional
    final operasionalData = [
      {"namaBiaya": "Gaji Karyawan", "nominal": 5825250},
      {"namaBiaya": "Listrik", "nominal": 1175000},
      {"namaBiaya": "Sewa Toko", "nominal": 500000},
      {"namaBiaya": "Kebersihan", "nominal": 15000},
      {"namaBiaya": "Wifi", "nominal": 293000},
      {"namaBiaya": "Cukur Gratis Member", "nominal": 30000},
      {"namaBiaya": "Bonus Karyawan", "nominal": 457500}
    ];

    for (int i = 0; i < operasionalData.length; i++) {
      final item = operasionalData[i];
      await db.collection('operasional').doc('OP-JUL-26-$i').set({
        'id_operasional': 'OP-JUL-26-$i',
        'bulan': '2026-07',
        'nama_biaya': item['namaBiaya'],
        'akun': item['namaBiaya'],
        'nominal': item['nominal'],
        'keterangan': 'Pengeluaran Juli 2026'
      });
    }

    // 2. Buku Kas
    final transaksi = [
        ["01 Mei 2026", "Saldo Awal Bulan", 20872750, 0],
        ["03 Mei 2026", "Kain Cape Barber Street 3", 0, 167094],
        ["03 Mei 2026", "Pengembalian Piutang Abah Amin/SMK", 10000000, 0],
        ["08 Mei 2026", "Piutang Galeri Bustan Tahap Pertama", 0, 15000000],
        ["08 Mei 2026", "Piutang Abah Amin/Sapi", 0, 10000000],
        ["13 Mei 2026", "Pembelian Kursi Tunggu Bandara 4 Seat 2 Pcs", 0, 2350000],
        ["16 Mei 2026", "Pengembalian Piutang Akang Afif", 5000000, 0],
        ["22 Mei 2026", "Piutang Karyawan Torik", 0, 1200000],
        ["22 Mei 2026", "Piutang Karyawan Sod", 0, 1500000],
        ["22 Mei 2026", "DP Baju Dinas Garden Barbershop", 0, 481000],
        ["22 Mei 2026", "Cetak Price List Terbaru", 0, 25000],
        ["22 Mei 2026", "Materai Kontrak", 0, 24000],
        ["02 Jun 2026", "Laba Bersih Periode Mei 2026", 5110000, 0],
        ["08 Jun 2026", "Piutang Karyawan Oji", 0, 600000],
        ["15 Jun 2026", "Pengembalian Piutang Abah Amin/Sapi", 10000000, 0],
        ["16 Jun 2026", "Piutang Galeri Bustan Tahap Ke 2", 0, 5000000],
        ["16 Jun 2026", "Pengembalian Piutang Galeri Bustan Tahap 1", 10000000, 0],
        ["26 Jun 2026", "Pengembalian Piutang Sod", 300000, 0],
        ["26 Jun 2026", "Pengembalian Piutang Oji", 200000, 0],
        ["26 Jun 2026", "Sumbangan Liga Bangbayang", 0, 100000],
        ["30 Jun 2026", "Laba Bersih Periode Juni 2026", 4744000, 0],
        ["30 Jun 2026", "Cuci AC", 0, 100000],
        ["02 Jul 2026", "Pengembalian Piutang Torik", 300000, 0],
        ["13 Jul 2026", "Pembelian /DP Gawang Futsal Bustan", 0, 2000000],
        ["13 Jul 2026", "Transportasi Pembelian Gawang Futsal Bustan", 0, 100000],
        ["13 Jul 2026", "Cetak Poster Peraturan Potongan Rambut Santri", 0, 50000],
        ["21 Jul 2026", "Pengembalian Piutang Galeri Bustan Tahap 2", 10000000, 0],
        ["28 Jul 2026", "Outing Ke Baturaden Kedung Pete", 0, 1542000],
        ["30 Jul 2026", "Pelunasan Gawang Futsal Bustan", 0, 1500000],
        ["31 Jul 2026", "Laba Bersih Periode Juli 2026", 5477750, 0],
        ["31 Jul 2026", "Pengembalian Piutang Oji", 200000, 0],
        ["31 Jul 2026", "Pengembalian Piutang Sod", 300000, 0],
        ["31 Jul 2026", "Pengembalian Piutang Torik", 300000, 0]
    ];

    int saldo = 0;
    Map<String, String> monthMap = {"Mei": "05", "Jun": "06", "Jul": "07"};

    for (int i = 0; i < transaksi.length; i++) {
      var row = transaksi[i];
      String tgl = row[0] as String;
      String uraian = row[1] as String;
      int masuk = row[2] as int;
      int keluar = row[3] as int;

      List<String> parts = tgl.split(' ');
      String day = parts[0];
      String month = monthMap[parts[1]]!;
      String year = parts[2];

      String isoDate = "$year-$month-${day}T12:00:00";

      saldo = saldo + masuk - keluar;

      await db.collection('buku_kas_umum').doc('BK-$year-$month-$day-$i').set({
        'id_kas': 'BK-$year-$month-$day-$i',
        'tanggal': isoDate,
        'uraian': uraian,
        'akun': (masuk > 0) ? 'Pendapatan' : 'Pengeluaran',
        'penerimaan': masuk,
        'pengeluaran': keluar,
        'saldo': saldo,
        'keterangan': 'Migrasi',
      });
    }

    // 3. Pendapatan Harian
    int targetSantri = 171;
    int targetUmum = 748;
    int targetPendapatan = 13846000;
    int days = 31;

    List<int> santriDist = List.generate(days, (i) => (targetSantri ~/ days) + (i < (targetSantri % days) ? 1 : 0));
    List<int> umumDist = List.generate(days, (i) => (targetUmum ~/ days) + (i < (targetUmum % days) ? 1 : 0));
    
    int baseMoney = targetPendapatan ~/ days;
    int remMoney = targetPendapatan % days;
    List<int> pendapatanDist = List.generate(days, (i) => baseMoney + (i < remMoney ? 1 : 0));

    santriDist.shuffle(Random(42));
    umumDist.shuffle(Random(42));
    pendapatanDist.shuffle(Random(42));

    DateTime startDate = DateTime(2026, 7, 1, 12, 0, 0);

    for (int i = 0; i < days; i++) {
      DateTime currentDate = startDate.add(Duration(days: i));
      int totalP = pendapatanDist[i];
      int sn = santriDist[i];
      int cu = umumDist[i];
      int tc = sn + cu;

      String id = 'PH-2026-07-${currentDate.day}';

      await db.collection('pendapatan_harian').doc(id).set({
        'id_pendapatan': id,
        'tanggal': currentDate.toIso8601String(),
        'id_capster': 'C001',
        'nama_capster': 'Semua Capster (Migrasi)',
        'SN': sn,
        'RC': cu,
        'PC': 0,
        'GC': 0,
        'CJ': 0,
        'KR': 0,
        'CH': 0,
        'HS': 0,
        'PR': 0,
        'KM': 0,
        'pendapatan': totalP,
        'CS': sn,
        'CU': cu,
        'total_customer': tc,
      });

      await db.collection('rekap_customer').doc(id).set({
        'id_rekap': id,
        'tanggal': currentDate.toIso8601String(),
        'total_pendapatan': totalP,
        'customer_santri': sn,
        'customer_umum': cu,
        'total_customer': tc,
      });
    }

    // 4. Laporan Historis
    final history = [
        ["2026-03", 4350000],
        ["2026-04", 6629500],
        ["2026-05", 5110000],
        ["2026-06", 4744000],
        ["2026-07", 5477750]
    ];

    for (var item in history) {
      await db.collection('laporan_bulanan').doc('LB-${item[0]}').set({
        'bulan': item[0],
        'id_capster': 'C000', // Mock
        'nama_capster': 'Total Semua',
        'pendapatan_kotor': 0,
        'total_operasional': 0,
        'operasional_per_capster': 0,
        'pendapatan_bersih': item[1],
        'bagian_capster': 0,
        'bagian_pondok': item[1], // for laba
      });
    }

    // 5. Histori Pelanggan (Februari - Juni 2026)
    final customerHistory = [
      {'bulan': '2026-02', 'cs': 316, 'cu': 849, 'total': 1165},
      {'bulan': '2026-03', 'cs': 287, 'cu': 616, 'total': 903},
      {'bulan': '2026-04', 'cs': 179, 'cu': 659, 'total': 838},
      {'bulan': '2026-05', 'cs': 168, 'cu': 583, 'total': 751},
      {'bulan': '2026-06', 'cs': 112, 'cu': 536, 'total': 648},
    ];

    for (var ch in customerHistory) {
      String m = ch['bulan'] as String;
      String id = 'PH-$m-28'; // Ditaruh di akhir bulan untuk rekap
      
      await db.collection('pendapatan_harian').doc(id).set({
        'id_pendapatan': id,
        'tanggal': '$m-28T12:00:00.000',
        'id_capster': 'C001',
        'nama_capster': 'Semua Capster (Migrasi Historis)',
        'SN': ch['cs'],
        'RC': ch['cu'],
        'PC': 0, 'GC': 0, 'CJ': 0, 'KR': 0, 'CH': 0, 'HS': 0, 'PR': 0, 'KM': 0,
        'pendapatan': 0, // Pendapatan dikosongkan agar tidak merusak laporan uang
        'CS': ch['cs'],
        'CU': ch['cu'],
        'total_customer': ch['total'],
      });
    }

    // 6. Inisialisasi Saldo Neraca Bulan Juli 2026
    final neracaJuli = NeracaModel.defaultBalances('2026-07');
    await db.collection('neraca').doc(neracaJuli.idNeraca).set(neracaJuli.toMap());

    print("Migrasi Data Juli 2026 Selesai!");
  }
}
