class NeracaModel {
  final String idNeraca;
  final String bulan; // format: YYYY-MM
  final int piutangUsaha;
  final int mesinPeralatan;
  final int peralatanLainnya;
  final int sdmBarber;
  final int hartaLainLain;
  final int akumPenyusutan;
  final int hutangUsaha;
  final int hutangLancarLainnya;
  final int hutangBank;
  final int pinjamanPihakKetiga;
  final int pinjamanJangkaPanjang;
  final int modalAwal;
  final int labaTahunLalu;
  final int prive;

  NeracaModel({
    required this.idNeraca,
    required this.bulan,
    required this.piutangUsaha,
    required this.mesinPeralatan,
    required this.peralatanLainnya,
    required this.sdmBarber,
    required this.hartaLainLain,
    required this.akumPenyusutan,
    required this.hutangUsaha,
    required this.hutangLancarLainnya,
    required this.hutangBank,
    required this.pinjamanPihakKetiga,
    required this.pinjamanJangkaPanjang,
    required this.modalAwal,
    required this.labaTahunLalu,
    required this.prive,
  });

  factory NeracaModel.fromMap(Map<String, dynamic> data) {
    return NeracaModel(
      idNeraca: data['id_neraca'] ?? '',
      bulan: data['bulan'] ?? '',
      piutangUsaha: data['piutang_usaha'] ?? 0,
      mesinPeralatan: data['mesin_peralatan'] ?? 0,
      peralatanLainnya: data['peralatan_lainnya'] ?? 0,
      sdmBarber: data['sdm_barber'] ?? 0,
      hartaLainLain: data['harta_lain_lain'] ?? 0,
      akumPenyusutan: data['akum_penyusutan'] ?? 0,
      hutangUsaha: data['hutang_usaha'] ?? 0,
      hutangLancarLainnya: data['hutang_lancar_lainnya'] ?? 0,
      hutangBank: data['hutang_bank'] ?? 0,
      pinjamanPihakKetiga: data['pinjaman_pihak_ketiga'] ?? 0,
      pinjamanJangkaPanjang: data['pinjaman_jangka_panjang'] ?? 0,
      modalAwal: data['modal_awal'] ?? 0,
      labaTahunLalu: data['laba_tahun_lalu'] ?? 0,
      prive: data['prive'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_neraca': idNeraca,
      'bulan': bulan,
      'piutang_usaha': piutangUsaha,
      'mesin_peralatan': mesinPeralatan,
      'peralatan_lainnya': peralatanLainnya,
      'sdm_barber': sdmBarber,
      'harta_lain_lain': hartaLainLain,
      'akum_penyusutan': akumPenyusutan,
      'hutang_usaha': hutangUsaha,
      'hutang_lancar_lainnya': hutangLancarLainnya,
      'hutang_bank': hutangBank,
      'pinjaman_pihak_ketiga': pinjamanPihakKetiga,
      'pinjaman_jangka_panjang': pinjamanJangkaPanjang,
      'modal_awal': modalAwal,
      'laba_tahun_lalu': labaTahunLalu,
      'prive': prive,
    };
  }

  factory NeracaModel.defaultBalances(String currentBulan) {
    return NeracaModel(
      idNeraca: 'NRC-$currentBulan',
      bulan: currentBulan,
      piutangUsaha: 1700000,
      mesinPeralatan: 39371889,
      peralatanLainnya: 1054983,
      sdmBarber: 16140609,
      hartaLainLain: 50000,
      akumPenyusutan: 0,
      hutangUsaha: 0,
      hutangLancarLainnya: 0,
      hutangBank: 0,
      pinjamanPihakKetiga: 0,
      pinjamanJangkaPanjang: 0,
      modalAwal: 43221000,
      labaTahunLalu: 42148087,
      prive: -12297450,
    );
  }

  NeracaModel copyWithNewBulan(String newBulan) {
    return NeracaModel(
      idNeraca: 'NRC-$newBulan',
      bulan: newBulan,
      piutangUsaha: piutangUsaha,
      mesinPeralatan: mesinPeralatan,
      peralatanLainnya: peralatanLainnya,
      sdmBarber: sdmBarber,
      hartaLainLain: hartaLainLain,
      akumPenyusutan: akumPenyusutan,
      hutangUsaha: hutangUsaha,
      hutangLancarLainnya: hutangLancarLainnya,
      hutangBank: hutangBank,
      pinjamanPihakKetiga: pinjamanPihakKetiga,
      pinjamanJangkaPanjang: pinjamanJangkaPanjang,
      modalAwal: modalAwal,
      labaTahunLalu: labaTahunLalu,
      prive: prive,
    );
  }
}
