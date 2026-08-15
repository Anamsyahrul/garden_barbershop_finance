class KasbonModel {
  const KasbonModel({
    required this.idKasbon,
    required this.tanggal,
    required this.idCapster,
    required this.namaCapster,
    required this.nominal,
    required this.keterangan,
  });

  final String idKasbon;
  final String tanggal;
  final String idCapster;
  final String namaCapster;
  final int nominal;
  final String keterangan;

  factory KasbonModel.fromRow(List<dynamic> row) {
    return KasbonModel(
      idKasbon: row.isNotEmpty ? row[0].toString() : '',
      tanggal: row.length > 1 ? row[1].toString() : '',
      idCapster: row.length > 2 ? row[2].toString() : '',
      namaCapster: row.length > 3 ? row[3].toString() : '',
      nominal: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      keterangan: row.length > 5 ? row[5].toString() : '',
    );
  }

  List<dynamic> toRow() => [
        idKasbon,
        tanggal,
        idCapster,
        namaCapster,
        nominal,
        keterangan,
      ];
}
