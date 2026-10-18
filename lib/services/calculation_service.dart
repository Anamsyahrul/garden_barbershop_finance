import '../models/capster_model.dart';
import '../models/kasbon_model.dart';
import '../models/bonus_denda_model.dart';
import '../models/laporan_bulanan_model.dart';
import '../models/layanan_model.dart';
import '../models/operasional_model.dart';
import '../models/pendapatan_harian_model.dart';

class CalculationService {
  int hitungPendapatanHarian(
    Map<String, int> jumlahLayanan,
    List<LayananModel> layanan,
  ) {
    var total = 0;
    final hargaByKode = {
      for (final item in layanan.where((e) => e.aktif))
        item.kodeLayanan.toUpperCase(): item.harga,
    };

    for (final entry in jumlahLayanan.entries) {
      final kode =
          entry.key.toUpperCase() == 'RG' ? 'RC' : entry.key.toUpperCase();
      final jumlah = entry.value;
      if (jumlah <= 0) continue;
      final harga =
          hargaByKode[kode] ?? (kode == 'RC' ? hargaByKode['RG'] : null);
      if (harga == null) {
        throw Exception('Harga layanan $kode belum tersedia');
      }
      total += jumlah * harga;
    }
    return total;
  }

  int hitungTotalOperasional(List<OperasionalModel> operasional) {
    return operasional.fold(0, (total, item) => total + item.nominal);
  }

  int hitungOperasionalPerCapster(
      int totalOperasional, int jumlahCapsterAktif) {
    if (jumlahCapsterAktif <= 0) return 0;
    return (totalOperasional / jumlahCapsterAktif).round();
  }

  int hitungPendapatanBersih(int pendapatanKotor, int operasionalPerCapster) {
    return pendapatanKotor - operasionalPerCapster;
  }

  int hitungBagianCapster(int pendapatanBersih, double persentaseCapster) {
    return (pendapatanBersih * persentaseCapster).round();
  }

  int hitungBagianPondok(int pendapatanBersih, double persentaseCapster) {
    return (pendapatanBersih * (1.0 - persentaseCapster)).round();
  }

  List<LaporanBulananModel> generateLaporanBulanan({
    required String bulan,
    required List<CapsterModel> capsterAktif,
    required List<PendapatanHarianModel> pendapatan,
    required List<OperasionalModel> operasional,
    List<KasbonModel> kasbon = const [],
    List<BonusDendaModel> bonusDenda = const [],
    double persentaseCapster = 0.5,
  }) {
    final totalOperasional = hitungTotalOperasional(operasional);
    final operasionalPerCapster = hitungOperasionalPerCapster(
      totalOperasional,
      capsterAktif.length,
    );

    return capsterAktif.map((capster) {
      final pendapatanKotor = pendapatan
          .where((item) => item.idCapster == capster.idCapster)
          .fold(0, (total, item) => total + item.pendapatan);
      final pendapatanBersih = hitungPendapatanBersih(
        pendapatanKotor,
        operasionalPerCapster,
      );
      final bagianCapster = hitungBagianCapster(pendapatanBersih, persentaseCapster);
      final bagianPondok = hitungBagianPondok(pendapatanBersih, persentaseCapster);
      
      final totalKasbon = kasbon
          .where((k) => k.idCapster == capster.idCapster)
          .fold(0, (sum, item) => sum + item.nominal);
          
      final bonus = bonusDenda
          .where((b) => b.idCapster == capster.idCapster)
          .fold(0, (sum, item) => sum + item.nominalBonus);
          
      final denda = bonusDenda
          .where((d) => d.idCapster == capster.idCapster)
          .fold(0, (sum, item) => sum + item.nominalDenda);
      
      final sisaDiterimaCapster = (bagianCapster + bonus) - totalKasbon - denda;

      return LaporanBulananModel(
        bulan: bulan,
        idCapster: capster.idCapster,
        namaCapster: capster.namaCapster,
        pendapatanKotor: pendapatanKotor,
        totalOperasional: totalOperasional,
        operasionalPerCapster: operasionalPerCapster,
        pendapatanBersih: pendapatanBersih,
        bagianCapster: bagianCapster,
        bagianPondok: bagianPondok,
        totalKasbon: totalKasbon,
        bonus: bonus,
        denda: denda,
        sisaDiterimaCapster: sisaDiterimaCapster,
      );
    }).toList();
  }
}
