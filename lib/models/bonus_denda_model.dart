class BonusDendaModel {
  const BonusDendaModel({
    required this.idBonusDenda,
    required this.bulan, // YYYY-MM
    required this.idCapster,
    required this.namaCapster,
    required this.nominalBonus,
    required this.nominalDenda,
    required this.keterangan,
  });

  final String idBonusDenda;
  final String bulan;
  final String idCapster;
  final String namaCapster;
  final int nominalBonus;
  final int nominalDenda;
  final String keterangan;

  factory BonusDendaModel.fromRow(List<dynamic> row) {
    return BonusDendaModel(
      idBonusDenda: row.isNotEmpty ? row[0].toString() : '',
      bulan: row.length > 1 ? row[1].toString() : '',
      idCapster: row.length > 2 ? row[2].toString() : '',
      namaCapster: row.length > 3 ? row[3].toString() : '',
      nominalBonus: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      nominalDenda: row.length > 5 ? int.tryParse(row[5].toString()) ?? 0 : 0,
      keterangan: row.length > 6 ? row[6].toString() : '',
    );
  }

  List<dynamic> toRow() => [
        idBonusDenda,
        bulan,
        idCapster,
        namaCapster,
        nominalBonus,
        nominalDenda,
        keterangan,
      ];
}
