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
      ];
}
