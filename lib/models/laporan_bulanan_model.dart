class LaporanBulananModel {
  const LaporanBulananModel({
    required this.bulan,
    required this.idCapster,
    required this.namaCapster,
    required this.pendapatanKotor,
    required this.totalOperasional,
    required this.operasionalPerCapster,
    required this.pendapatanBersih,
    required this.bagianCapster,
    required this.bagianPondok,
    required this.totalKasbon,
    this.bonus = 0,
    this.denda = 0,
    required this.sisaDiterimaCapster,
  });

  final String bulan;
  final String idCapster;
  final String namaCapster;
  final int pendapatanKotor;
  final int totalOperasional;
  final int operasionalPerCapster;
  final int pendapatanBersih;
  final int bagianCapster;
  final int bagianPondok;
  final int totalKasbon;
  final int bonus;
  final int denda;
  final int sisaDiterimaCapster;

  factory LaporanBulananModel.fromRow(List<dynamic> row) {
    return LaporanBulananModel(
      bulan: row.isNotEmpty ? row[0].toString() : '',
      idCapster: row.length > 1 ? row[1].toString() : '',
      namaCapster: row.length > 2 ? row[2].toString() : '',
      pendapatanKotor: row.length > 3 ? int.tryParse(row[3].toString()) ?? 0 : 0,
      totalOperasional: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      operasionalPerCapster: row.length > 5 ? int.tryParse(row[5].toString()) ?? 0 : 0,
      pendapatanBersih: row.length > 6 ? int.tryParse(row[6].toString()) ?? 0 : 0,
      bagianCapster: row.length > 7 ? int.tryParse(row[7].toString()) ?? 0 : 0,
      bagianPondok: row.length > 8 ? int.tryParse(row[8].toString()) ?? 0 : 0,
      totalKasbon: row.length > 9 ? int.tryParse(row[9].toString()) ?? 0 : 0,
      sisaDiterimaCapster: row.length > 10 ? int.tryParse(row[10].toString()) ?? 0 : 0,
      bonus: row.length > 11 ? int.tryParse(row[11].toString()) ?? 0 : 0,
      denda: row.length > 12 ? int.tryParse(row[12].toString()) ?? 0 : 0,
    );
  }

  List<dynamic> toRow() => [
        bulan,
        idCapster,
        namaCapster,
        pendapatanKotor,
        totalOperasional,
        operasionalPerCapster,
        pendapatanBersih,
        bagianCapster,
        bagianPondok,
        totalKasbon,
        sisaDiterimaCapster,
        bonus,
        denda,
      ];

  factory LaporanBulananModel.fromMap(Map<String, dynamic> map) {
    return LaporanBulananModel(
      bulan: map['bulan'] ?? '',
      idCapster: map['id_capster'] ?? '',
      namaCapster: map['nama_capster'] ?? '',
      pendapatanKotor: map['pendapatan_kotor'] ?? 0,
      totalOperasional: map['total_operasional'] ?? 0,
      operasionalPerCapster: map['operasional_per_capster'] ?? 0,
      pendapatanBersih: map['pendapatan_bersih'] ?? 0,
      bagianCapster: map['bagian_capster'] ?? 0,
      bagianPondok: map['bagian_pondok'] ?? 0,
      totalKasbon: map['total_kasbon'] ?? 0,
      sisaDiterimaCapster: map['sisa_diterima_capster'] ?? 0,
      bonus: map['bonus'] ?? 0,
      denda: map['denda'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bulan': bulan,
      'id_capster': idCapster,
      'nama_capster': namaCapster,
      'pendapatan_kotor': pendapatanKotor,
      'total_operasional': totalOperasional,
      'operasional_per_capster': operasionalPerCapster,
      'pendapatan_bersih': pendapatanBersih,
      'bagian_capster': bagianCapster,
      'bagian_pondok': bagianPondok,
      'total_kasbon': totalKasbon,
      'sisa_diterima_capster': sisaDiterimaCapster,
      'bonus': bonus,
      'denda': denda,
    };
  }
}

class LaporanBulanAgregat {
  LaporanBulanAgregat({
    required this.bulan,
    required this.pendapatanKotor,
    required this.totalOperasional,
    required this.pendapatanBersih,
    required this.bagianPondok,
    required this.sisaDiterimaCapster,
    required this.totalSantri,
    required this.totalUmum,
  });
  final String bulan;
  final int pendapatanKotor;
  final int totalOperasional;
  final int pendapatanBersih;
  final int bagianPondok;
  final int sisaDiterimaCapster;
  final int totalSantri;
  final int totalUmum;
}
