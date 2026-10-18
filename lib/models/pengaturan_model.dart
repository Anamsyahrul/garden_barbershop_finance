class PengaturanModel {
  final String idPengaturan;
  final String idCabang;
  final int persentaseCapster;

  PengaturanModel({
    required this.idPengaturan,
    required this.idCabang,
    required this.persentaseCapster,
  });

  factory PengaturanModel.fromMap(Map<String, dynamic> data) {
    return PengaturanModel(
      idPengaturan: data['id_pengaturan'] ?? '',
      idCabang: data['id_cabang'] ?? '',
      persentaseCapster: data['persentase_capster'] ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_pengaturan': idPengaturan,
      'id_cabang': idCabang,
      'persentase_capster': persentaseCapster,
    };
  }

  PengaturanModel copyWith({
    String? idPengaturan,
    String? idCabang,
    int? persentaseCapster,
  }) {
    return PengaturanModel(
      idPengaturan: idPengaturan ?? this.idPengaturan,
      idCabang: idCabang ?? this.idCabang,
      persentaseCapster: persentaseCapster ?? this.persentaseCapster,
    );
  }
}
