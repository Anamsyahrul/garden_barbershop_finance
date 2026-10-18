class PenjualanProdukModel {
  const PenjualanProdukModel({
    required this.idPenjualan,
    required this.tanggal, // YYYY-MM-DD
    required this.idProduk,
    required this.namaProduk,
    required this.qty,
    required this.hargaJual,
    required this.total,
    this.idCabang = 'CBG01',
  });

  final String idPenjualan;
  final String tanggal;
  final String idProduk;
  final String namaProduk;
  final int qty;
  final int hargaJual;
  final int total;
  final String idCabang;

  factory PenjualanProdukModel.fromRow(List<dynamic> row) {
    return PenjualanProdukModel(
      idPenjualan: row.isNotEmpty ? row[0].toString() : '',
      tanggal: row.length > 1 ? row[1].toString() : '',
      idProduk: row.length > 2 ? row[2].toString() : '',
      namaProduk: row.length > 3 ? row[3].toString() : '',
      qty: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      hargaJual: row.length > 5 ? int.tryParse(row[5].toString()) ?? 0 : 0,
      total: row.length > 6 ? int.tryParse(row[6].toString()) ?? 0 : 0,
      idCabang: row.length > 7 ? row[7].toString() : 'CBG01',
    );
  }

  List<dynamic> toRow() => [
        idPenjualan,
        tanggal,
        idProduk,
        namaProduk,
        qty,
        hargaJual,
        total,
        idCabang,
      ];
}
