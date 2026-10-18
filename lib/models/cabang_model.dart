class CabangModel {
  final String idCabang;
  final String namaCabang;
  final String alamat;

  CabangModel({
    required this.idCabang,
    required this.namaCabang,
    required this.alamat,
  });

  factory CabangModel.fromMap(Map<String, dynamic> data) {
    return CabangModel(
      idCabang: data['id_cabang'] ?? '',
      namaCabang: data['nama_cabang'] ?? '',
      alamat: data['alamat'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_cabang': idCabang,
      'nama_cabang': namaCabang,
      'alamat': alamat,
    };
  }

  CabangModel copyWith({
    String? idCabang,
    String? namaCabang,
    String? alamat,
  }) {
    return CabangModel(
      idCabang: idCabang ?? this.idCabang,
      namaCabang: namaCabang ?? this.namaCabang,
      alamat: alamat ?? this.alamat,
    );
  }
}
