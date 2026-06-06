class LayananModel {
  const LayananModel({
    required this.idLayanan,
    required this.kodeLayanan,
    required this.namaLayanan,
    required this.harga,
    required this.kategori,
    required this.status,
  });

  final String idLayanan;
  final String kodeLayanan;
  final String namaLayanan;
  final int harga;
  final String kategori;
  final String status;

  bool get aktif => status.toLowerCase() == 'aktif';

  factory LayananModel.fromRow(List<dynamic> row) {
    return LayananModel(
      idLayanan: row.isNotEmpty ? row[0].toString() : '',
      kodeLayanan: row.length > 1 ? row[1].toString() : '',
      namaLayanan: row.length > 2 ? row[2].toString() : '',
      harga: row.length > 3 ? int.tryParse(row[3].toString()) ?? 0 : 0,
      kategori: row.length > 4 ? row[4].toString() : '',
      status: row.length > 5 ? row[5].toString() : 'aktif',
    );
  }

  List<dynamic> toRow() => [
        idLayanan,
        kodeLayanan.toUpperCase(),
        namaLayanan,
        harga,
        kategori,
        status,
      ];

  LayananModel copyWith({
    String? idLayanan,
    String? kodeLayanan,
    String? namaLayanan,
    int? harga,
    String? kategori,
    String? status,
  }) {
    return LayananModel(
      idLayanan: idLayanan ?? this.idLayanan,
      kodeLayanan: kodeLayanan ?? this.kodeLayanan,
      namaLayanan: namaLayanan ?? this.namaLayanan,
      harga: harga ?? this.harga,
      kategori: kategori ?? this.kategori,
      status: status ?? this.status,
    );
  }
}
