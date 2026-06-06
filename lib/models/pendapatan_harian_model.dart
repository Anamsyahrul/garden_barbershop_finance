class PendapatanHarianModel {
  const PendapatanHarianModel({
    required this.idPendapatan,
    required this.tanggal,
    required this.idCapster,
    required this.namaCapster,
    required this.jumlahLayanan,
    required this.pendapatan,
    required this.cs,
    required this.cu,
    required this.totalCustomer,
  });

  final String idPendapatan;
  final String tanggal;
  final String idCapster;
  final String namaCapster;
  final Map<String, int> jumlahLayanan;
  final int pendapatan;
  final int cs;
  final int cu;
  final int totalCustomer;

  static const kodeLayanan = [
    'SN',
    'RC',
    'PC',
    'GC',
    'CJ',
    'KR',
    'CH',
    'HS',
    'PR',
    'KM'
  ];

  factory PendapatanHarianModel.fromRow(List<dynamic> row) {
    final counts = <String, int>{};
    for (var i = 0; i < kodeLayanan.length; i++) {
      counts[kodeLayanan[i]] =
          row.length > i + 4 ? int.tryParse(row[i + 4].toString()) ?? 0 : 0;
    }
    return PendapatanHarianModel(
      idPendapatan: row.isNotEmpty ? row[0].toString() : '',
      tanggal: row.length > 1 ? row[1].toString() : '',
      idCapster: row.length > 2 ? row[2].toString() : '',
      namaCapster: row.length > 3 ? row[3].toString() : '',
      jumlahLayanan: counts,
      pendapatan: row.length > 14 ? int.tryParse(row[14].toString()) ?? 0 : 0,
      cs: row.length > 15 ? int.tryParse(row[15].toString()) ?? 0 : 0,
      cu: row.length > 16 ? int.tryParse(row[16].toString()) ?? 0 : 0,
      totalCustomer:
          row.length > 17 ? int.tryParse(row[17].toString()) ?? 0 : 0,
    );
  }

  List<dynamic> toRow() => [
        idPendapatan,
        tanggal,
        idCapster,
        namaCapster,
        for (final kode in kodeLayanan) jumlahLayanan[kode] ?? 0,
        pendapatan,
        cs,
        cu,
        totalCustomer,
      ];
}
