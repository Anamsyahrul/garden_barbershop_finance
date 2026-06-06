class BukuKasModel {
  const BukuKasModel({
    required this.idKas,
    required this.tanggal,
    required this.uraian,
    required this.akun,
    required this.penerimaan,
    required this.pengeluaran,
    required this.saldo,
    required this.keterangan,
  });

  final String idKas;
  final String tanggal;
  final String uraian;
  final String akun;
  final int penerimaan;
  final int pengeluaran;
  final int saldo;
  final String keterangan;

  factory BukuKasModel.fromRow(List<dynamic> row) {
    return BukuKasModel(
      idKas: row.isNotEmpty ? row[0].toString() : '',
      tanggal: row.length > 1 ? row[1].toString() : '',
      uraian: row.length > 2 ? row[2].toString() : '',
      akun: row.length > 3 ? row[3].toString() : '',
      penerimaan: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      pengeluaran: row.length > 5 ? int.tryParse(row[5].toString()) ?? 0 : 0,
      saldo: row.length > 6 ? int.tryParse(row[6].toString()) ?? 0 : 0,
      keterangan: row.length > 7 ? row[7].toString() : '',
    );
  }

  List<dynamic> toRow() => [
        idKas,
        tanggal,
        uraian,
        akun,
        penerimaan,
        pengeluaran,
        saldo,
        keterangan,
      ];
}
