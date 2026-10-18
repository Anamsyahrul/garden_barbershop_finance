class AbsensiModel {
  const AbsensiModel({
    required this.idAbsensi,
    required this.tanggal,
    required this.idCapster,
    required this.namaCapster,
    required this.waktuCheckIn,
    this.waktuCheckOut,
    this.idCabang = 'CBG01',
  });

  final String idAbsensi;
  final String tanggal; // YYYY-MM-DD
  final String idCapster;
  final String namaCapster;
  final String waktuCheckIn; // HH:mm
  final String? waktuCheckOut; // HH:mm
  final String idCabang;

  factory AbsensiModel.fromRow(List<dynamic> row) {
    return AbsensiModel(
      idAbsensi: row.isNotEmpty ? row[0].toString() : '',
      tanggal: row.length > 1 ? row[1].toString() : '',
      idCapster: row.length > 2 ? row[2].toString() : '',
      namaCapster: row.length > 3 ? row[3].toString() : '',
      waktuCheckIn: row.length > 4 ? row[4].toString() : '',
      waktuCheckOut: row.length > 5 && row[5].toString().isNotEmpty ? row[5].toString() : null,
      idCabang: row.length > 6 ? row[6].toString() : 'CBG01',
    );
  }

  List<dynamic> toRow() => [
        idAbsensi,
        tanggal,
        idCapster,
        namaCapster,
        waktuCheckIn,
        waktuCheckOut ?? '',
        idCabang,
      ];
}
