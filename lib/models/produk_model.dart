class ProdukModel {
  const ProdukModel({
    required this.idProduk,
    required this.namaProduk,
    required this.hargaBeli,
    required this.hargaJual,
    required this.stok,
    this.idCabang = 'CBG01',
  });

  final String idProduk;
  final String namaProduk;
  final int hargaBeli;
  final int hargaJual;
  final int stok;
  final String idCabang;

  factory ProdukModel.fromRow(List<dynamic> row) {
    return ProdukModel(
      idProduk: row.isNotEmpty ? row[0].toString() : '',
      namaProduk: row.length > 1 ? row[1].toString() : '',
      hargaBeli: row.length > 2 ? int.tryParse(row[2].toString()) ?? 0 : 0,
      hargaJual: row.length > 3 ? int.tryParse(row[3].toString()) ?? 0 : 0,
      stok: row.length > 4 ? int.tryParse(row[4].toString()) ?? 0 : 0,
      idCabang: row.length > 5 ? row[5].toString() : 'CBG01',
    );
  }

  List<dynamic> toRow() => [
        idProduk,
        namaProduk,
        hargaBeli,
        hargaJual,
        stok,
        idCabang,
      ];
}
