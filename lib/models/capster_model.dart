class CapsterModel {
  const CapsterModel({
    required this.idCapster,
    required this.namaCapster,
    required this.noHp,
    required this.status,
  });

  final String idCapster;
  final String namaCapster;
  final String noHp;
  final String status;

  bool get aktif => status.toLowerCase() == 'aktif';

  factory CapsterModel.fromRow(List<dynamic> row) {
    return CapsterModel(
      idCapster: row.isNotEmpty ? row[0].toString() : '',
      namaCapster: row.length > 1 ? row[1].toString() : '',
      noHp: row.length > 2 ? row[2].toString() : '',
      status: row.length > 3 ? row[3].toString() : 'aktif',
    );
  }

  List<dynamic> toRow() => [idCapster, namaCapster, noHp, status];

  CapsterModel copyWith({
    String? idCapster,
    String? namaCapster,
    String? noHp,
    String? status,
  }) {
    return CapsterModel(
      idCapster: idCapster ?? this.idCapster,
      namaCapster: namaCapster ?? this.namaCapster,
      noHp: noHp ?? this.noHp,
      status: status ?? this.status,
    );
  }
}
