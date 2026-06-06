class OperasionalModel {
  const OperasionalModel({
    required this.idOperasional,
    required this.bulan,
    required this.namaBiaya,
    required this.akun,
    required this.nominal,
    required this.keterangan,
  });

  final String idOperasional;
  final String bulan;
  final String namaBiaya;
  final String akun;
  final int nominal;
  final String keterangan;

  factory OperasionalModel.fromRow(List<dynamic> row) {
    return OperasionalModel(
      idOperasional: row.isNotEmpty ? row[0].toString() : '',
      bulan: row.length > 1 ? row[1].toString() : '',
      namaBiaya: row.length > 2 ? row[2].toString() : '',
      akun: row.length > 3 ? row[3].toString() : '',
      nominal: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      keterangan: row.length > 5 ? row[5].toString() : '',
    );
  }

  List<dynamic> toRow() => [
        idOperasional,
        bulan,
        namaBiaya,
        akun,
        nominal,
        keterangan,
      ];
}
