import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/buku_kas_model.dart';
import '../models/capster_model.dart';
import '../models/laporan_bulanan_model.dart';
import '../models/layanan_model.dart';
import '../models/operasional_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/app_notification_model.dart';
import '../models/neraca_model.dart';
import '../models/kasbon_model.dart';
import '../utils/date_formatter.dart';
import '../services/calculation_service.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  FirebaseFirestore? _firestore;
  bool _dummyMode = true;
  bool _initialized = false;
  bool _forceDummyMode = false;

  bool get dummyMode => _dummyMode;
  bool get initialized => _initialized;

  final Map<String, List<String>> _headers = const {
    'capster': ['id_capster', 'nama_capster', 'no_hp', 'status'],
    'layanan': [
      'id_layanan',
      'kode_layanan',
      'nama_layanan',
      'harga',
      'kategori',
      'status'
    ],
    'pendapatan_harian': [
      'id_pendapatan',
      'tanggal',
      'id_capster',
      'nama_capster',
      'SN',
      'RC',
      'PC',
      'GC',
      'CJ',
      'KR',
      'CH',
      'HS',
      'PR',
      'KM',
      'pendapatan',
      'CS',
      'CU',
      'total_customer',
    ],
    'buku_kas_umum': [
      'id_kas',
      'tanggal',
      'uraian',
      'akun',
      'penerimaan',
      'pengeluaran',
      'saldo',
      'keterangan'
    ],
    'operasional': [
      'id_operasional',
      'bulan',
      'nama_biaya',
      'akun',
      'nominal',
      'keterangan'
    ],
    'laporan_bulanan': [
      'bulan',
      'id_capster',
      'nama_capster',
      'pendapatan_kotor',
      'total_operasional',
      'operasional_per_capster',
      'pendapatan_bersih',
      'bagian_capster',
      'bagian_pondok',
      'total_kasbon',
      'sisa_diterima_capster',
    ],
    'kasbon': [
      'id_kasbon',
      'tanggal',
      'id_capster',
      'nama_capster',
      'nominal',
      'keterangan',
    ],
    'rekap_customer': [
      'id_rekap',
      'tanggal',
      'total_pendapatan',
      'customer_santri',
      'customer_umum',
      'total_customer'
    ],
    'neraca': [
      'id_neraca',
      'bulan',
      'piutang_usaha',
      'mesin_peralatan',
      'peralatan_lainnya',
      'sdm_barber',
      'harta_lain_lain',
      'akum_penyusutan',
      'hutang_usaha',
      'hutang_lancar_lainnya',
      'hutang_bank',
      'pinjaman_pihak_ketiga',
      'pinjaman_jangka_panjang',
      'modal_awal',
      'laba_tahun_lalu',
      'prive'
    ],
    'users': [
      'id_user',
      'username',
      'password',
      'nama',
      'role',
      'status',
      'id_capster',
    ],
  };

  final Map<String, List<List<dynamic>>> _dummyCollections = {};

  void useDummyModeForTesting() {
    _forceDummyMode = true;
    _dummyMode = true;
    _initialized = false;
    _firestore = null;
    _dummyCollections.clear();
  }

  Future<void> init() async {
    if (_initialized) return;
    _seedDummyData();

    if (_forceDummyMode) {
      _dummyMode = true;
      _initialized = true;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firestore = FirebaseFirestore.instance;
      _dummyMode = false;
      await _seedFirestoreIfEmpty();
    } catch (_) {
      _dummyMode = true;
    }
    _initialized = true;
  }

  Future<List<List<dynamic>>> readRows(String collectionName) async {
    await init();
    if (_dummyMode) {
      return List<List<dynamic>>.from(_dummyCollections[collectionName] ?? []);
    }

    final header = _headers[collectionName] ?? const <String>[];
    final snapshot = await _firestore!.collection(collectionName).get();
    final rows = snapshot.docs.map((doc) {
      final data = doc.data();
      return header.map((key) => data[key] ?? '').toList();
    }).toList();

    rows.sort((a, b) => _sortKey(collectionName, a).compareTo(
          _sortKey(collectionName, b),
        ));
    return [header, ...rows];
  }

  Future<void> appendRow(String collectionName, List<dynamic> row) async {
    await init();
    if (_dummyMode) {
      _dummyCollections.putIfAbsent(collectionName, () => []);
      final rows = _dummyCollections[collectionName]!;
      final docId = _docIdFor(collectionName, row);
      for (var i = 1; i < rows.length; i++) {
        if (_docIdFor(collectionName, rows[i]) == docId) {
          rows[i] = row;
          return;
        }
      }
      rows.add(row);
      return;
    }
    await _setFirestoreRow(collectionName, row);
  }

  Future<void> updateRow(
      String collectionName, int rowIndex, List<dynamic> row) async {
    await init();
    if (_dummyMode) {
      final rows = _dummyCollections[collectionName];
      if (rows != null && rowIndex >= 0 && rowIndex < rows.length) {
        rows[rowIndex] = row;
      }
      return;
    }
    await _setFirestoreRow(collectionName, row);
  }

  Future<void> deleteRow(String collectionName, int rowNumber) async {
    await init();
    if (_dummyMode) {
      final rows = _dummyCollections[collectionName];
      final index = rowNumber - 1;
      if (rows != null && index > 0 && index < rows.length) {
        rows.removeAt(index);
      }
      return;
    }

    final rows = await readRows(collectionName);
    final index = rowNumber - 1;
    if (index > 0 && index < rows.length) {
      await _deleteByDocumentId(
          collectionName, _docIdFor(collectionName, rows[index]));
    }
  }

  Future<int> getLastSaldo() async {
    final data = await getBukuKas();
    if (data.isEmpty) return 0;
    return data.last.saldo;
  }

  Future<int> getSaldoSebelumKas(String tanggal, String idKas) async {
    final tanggalKey = DateFormatter.toStorageDate(tanggal);
    final data = await getBukuKas();
    final sorted = data
        .where((item) => item.idKas != idKas)
        .where((item) =>
            '${DateFormatter.toStorageDate(item.tanggal)}_${item.idKas}'
                .compareTo('${tanggalKey}_$idKas') <
            0)
        .toList();
    if (sorted.isEmpty) return 0;
    return sorted.last.saldo;
  }

  Future<List<CapsterModel>> getCapsterAktif() {
    return getCapsters(activeOnly: true);
  }

  Future<List<LayananModel>> getLayananAktif() {
    return getLayanan(activeOnly: true);
  }

  Future<List<PendapatanHarianModel>> getPendapatanByMonth(String bulan) async {
    final monthKey = DateFormatter.toStorageMonth(bulan);
    final rows = await readRows('pendapatan_harian');
    return rows.skip(1).map(PendapatanHarianModel.fromRow).where((item) {
      return DateFormatter.toStorageDate(item.tanggal).startsWith(monthKey);
    }).toList();
  }

  Future<List<OperasionalModel>> getOperasionalByMonth(String bulan) async {
    final monthKey = DateFormatter.toStorageMonth(bulan);
    final rows = await readRows('operasional');
    return rows.skip(1).map(OperasionalModel.fromRow).where((item) {
      return DateFormatter.toStorageMonth(item.bulan) == monthKey;
    }).toList();
  }

  Future<void> saveLaporanBulanan(List<LaporanBulananModel> laporan) async {
    for (final item in laporan) {
      await _updateById(
        'laporan_bulanan',
        '${item.bulan}_${item.idCapster}',
        item.toRow(),
      );
    }
  }

  Future<List<CapsterModel>> getCapsters({bool activeOnly = false}) async {
    final rows = await readRows('capster');
    final data = rows.skip(1).map(CapsterModel.fromRow).toList();
    return activeOnly ? data.where((item) => item.aktif).toList() : data;
  }

  Future<void> saveCapster(CapsterModel model) {
    return appendRow('capster', model.toRow());
  }

  Future<void> updateCapster(CapsterModel model) {
    return _updateById('capster', model.idCapster, model.toRow());
  }

  Future<void> deleteCapster(String idCapster) {
    return _deleteById('capster', idCapster);
  }

  Future<List<LayananModel>> getLayanan({bool activeOnly = false}) async {
    final rows = await readRows('layanan');
    final data = rows.skip(1).map(LayananModel.fromRow).toList();
    return activeOnly ? data.where((item) => item.aktif).toList() : data;
  }

  Future<void> saveLayanan(LayananModel model) {
    return appendRow('layanan', model.toRow());
  }

  Future<void> updateLayanan(LayananModel model) {
    return _updateById('layanan', model.idLayanan, model.toRow());
  }

  Future<void> deleteLayanan(String idLayanan) {
    return _deleteById('layanan', idLayanan);
  }

  Future<List<PendapatanHarianModel>> getPendapatanHarian() async {
    final rows = await readRows('pendapatan_harian');
    return rows.skip(1).map(PendapatanHarianModel.fromRow).toList();
  }

  Future<void> savePendapatanHarian(PendapatanHarianModel model) async {
    await _updateById('pendapatan_harian', model.idPendapatan, model.toRow());
    await _updateById('rekap_customer', model.idPendapatan, [
      model.idPendapatan,
      model.tanggal,
      model.pendapatan,
      model.cs,
      model.cu,
      model.totalCustomer,
    ]);
    await _syncKasPondok(DateFormatter.toStorageMonth(model.tanggal));
  }

  Future<void> deletePendapatanHarian(PendapatanHarianModel model) async {
    await _deleteById('pendapatan_harian', model.idPendapatan);
    await _deleteById('rekap_customer', model.idPendapatan);
    await _syncKasPondok(DateFormatter.toStorageMonth(model.tanggal));
  }

  Future<List<BukuKasModel>> getBukuKas() async {
    final rows = await readRows('buku_kas_umum');
    var data = rows.skip(1).map(BukuKasModel.fromRow).toList();
    data.sort((a, b) => '${DateFormatter.toStorageDate(a.tanggal)}_${a.idKas}'
        .compareTo('${DateFormatter.toStorageDate(b.tanggal)}_${b.idKas}'));
    
    int runningSaldo = 0;
    for (var i = 0; i < data.length; i++) {
      runningSaldo += data[i].penerimaan - data[i].pengeluaran;
      data[i] = data[i].copyWith(saldo: runningSaldo);
    }
    
    return data;
  }

  Future<void> saveBukuKas(BukuKasModel model) {
    return appendRow('buku_kas_umum', model.toRow());
  }

  Future<void> upsertBukuKas(BukuKasModel model) {
    return _updateById('buku_kas_umum', model.idKas, model.toRow());
  }

  Future<void> deleteBukuKas(String idKas) {
    return _deleteById('buku_kas_umum', idKas);
  }

  Future<void> saveOperasional(OperasionalModel model) async {
    await appendRow('operasional', model.toRow());
    await _syncKasPondok(DateFormatter.toStorageMonth(model.bulan));
  }

  Future<List<OperasionalModel>> getOperasional() async {
    final rows = await readRows('operasional');
    return rows.skip(1).map(OperasionalModel.fromRow).toList();
  }

  Future<void> deleteOperasional(OperasionalModel model) async {
    await _deleteById('operasional', model.idOperasional);
    await _syncKasPondok(DateFormatter.toStorageMonth(model.bulan));
  }

  Future<List<KasbonModel>> getKasbonByMonth(String bulan) async {
    final monthKey = DateFormatter.toStorageMonth(bulan);
    final rows = await readRows('kasbon');
    return rows.skip(1).map(KasbonModel.fromRow).where((item) {
      return DateFormatter.toStorageDate(item.tanggal).startsWith(monthKey);
    }).toList();
  }

  Future<void> saveKasbon(KasbonModel model) async {
    await appendRow('kasbon', model.toRow());

    // Otomatis catat Kasbon sebagai pengeluaran di Buku Kas
    final kasModel = BukuKasModel(
      idKas: 'BK-${model.idKasbon}',
      tanggal: model.tanggal,
      uraian: 'Kasbon capster ${model.namaCapster}',
      akun: 'Kasbon Karyawan',
      penerimaan: 0,
      pengeluaran: model.nominal,
      saldo: 0, // Saldo will be calculated dynamically in getBukuKas
      keterangan: model.keterangan,
    );
    await upsertBukuKas(kasModel);

    await _syncKasPondok(DateFormatter.toStorageMonth(model.tanggal));
  }

  Future<List<KasbonModel>> getKasbon() async {
    final rows = await readRows('kasbon');
    return rows.skip(1).map(KasbonModel.fromRow).toList();
  }

  Future<void> deleteKasbon(KasbonModel model) async {
    await _deleteById('kasbon', model.idKasbon);
    await deleteBukuKas('BK-${model.idKasbon}');
    await _syncKasPondok(DateFormatter.toStorageMonth(model.tanggal));
  }

  Future<List<UserModel>> getUsers() async {
    final rows = await readRows('users');
    var data = rows.skip(1).map(UserModel.fromRow).toList();
    if (!data.any((item) => item.username.toLowerCase() == 'admin')) {
      await appendRow(
        'users',
        const UserModel(
          idUser: 'UADMIN',
          username: 'admin',
          password: 'admin123',
          name: 'Admin Garden',
          role: UserRole.admin,
          status: 'aktif',
          idCapster: '',
        ).toRow(),
      );
      final updatedRows = await readRows('users');
      data = updatedRows.skip(1).map(UserModel.fromRow).toList();
    }
    return data;
  }

  Future<UserModel?> findUserByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    final users = await getUsers();
    for (final user in users) {
      if (user.username.toLowerCase() == normalized && user.aktif) {
        return user;
      }
    }
    return null;
  }

  Future<void> saveUser(UserModel model) {
    return appendRow('users', model.toRow());
  }

  Future<void> updateUser(UserModel model) {
    return _updateById('users', model.idUser, model.toRow());
  }

  Future<void> deleteUser(String idUser) {
    return _deleteById('users', idUser);
  }

  Future<void> _updateById(
      String collectionName, String id, List<dynamic> row) async {
    await init();
    if (_dummyMode) {
      final rows = _dummyCollections[collectionName] ?? [];
      for (var i = 1; i < rows.length; i++) {
        if (_docIdFor(collectionName, rows[i]) == id ||
            (rows[i].isNotEmpty && rows[i][0].toString() == id)) {
          rows[i] = row;
          return;
        }
      }
      rows.add(row);
      _dummyCollections[collectionName] = rows;
      return;
    }
    await _setFirestoreRow(collectionName, row, explicitId: id);
  }

  Future<void> _deleteById(String collectionName, String id) async {
    await init();
    if (_dummyMode) {
      final rows = _dummyCollections[collectionName];
      if (rows == null) return;
      for (var i = 1; i < rows.length; i++) {
        if (_docIdFor(collectionName, rows[i]) == id ||
            (rows[i].isNotEmpty && rows[i][0].toString() == id)) {
          rows.removeAt(i);
          return;
        }
      }
      return;
    }
    await _deleteByDocumentId(collectionName, id);
  }

  Future<void> _setFirestoreRow(
    String collectionName,
    List<dynamic> row, {
    String? explicitId,
  }) async {
    final header = _headers[collectionName] ?? const <String>[];
    final data = <String, dynamic>{};
    for (var i = 0; i < header.length && i < row.length; i++) {
      data[header[i]] = row[i];
    }
    data['updated_at'] = FieldValue.serverTimestamp();
    final id = explicitId ?? _docIdFor(collectionName, row);
    await _firestore!.collection(collectionName).doc(id).set(data);
  }

  Future<void> _deleteByDocumentId(String collectionName, String id) async {
    await _firestore!.collection(collectionName).doc(id).delete();
  }

  Future<void> _syncKasPondok(String bulan) async {
    final capster = await getCapsterAktif();
    final pendapatan = await getPendapatanByMonth(bulan);
    final operasional = await getOperasionalByMonth(bulan);
    final kasbon = await getKasbonByMonth(bulan);
    
    final laporan = CalculationService().generateLaporanBulanan(
      bulan: bulan,
      capsterAktif: capster,
      pendapatan: pendapatan,
      operasional: operasional,
      kasbon: kasbon,
    );
    
    final totalBagianPondok = laporan.fold(0, (total, item) => total + item.bagianPondok);
    final idKas = 'K-PONDOK-$bulan';
    
    if (totalBagianPondok <= 0) {
      await deleteBukuKas(idKas);
      return;
    }
    
    String tanggalAkhir = DateFormatter.formatDateKey(DateTime.now());
    final parts = bulan.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null) {
        tanggalAkhir = DateFormatter.formatDateKey(DateTime(year, month + 1, 0));
      }
    }
    
    final saldoSebelumnya = await getSaldoSebelumKas(tanggalAkhir, idKas);
    
    final kasModel = BukuKasModel(
      idKas: idKas,
      tanggal: tanggalAkhir,
      uraian: 'Pendapatan usaha pondok bulan ${DateFormatter.displayMonth(bulan)}',
      akun: 'Pendapatan Usaha',
      penerimaan: totalBagianPondok,
      pengeluaran: 0,
      saldo: saldoSebelumnya + totalBagianPondok,
      keterangan: 'Otomatis dari bagian pondok pada laporan pembagian hasil',
    );
    
    await upsertBukuKas(kasModel);
    await saveLaporanBulanan(laporan);
  }

  String _docIdFor(String collectionName, List<dynamic> row) {
    if (collectionName == 'laporan_bulanan') {
      final bulan = row.isNotEmpty ? row[0].toString() : '';
      final idCapster = row.length > 1 ? row[1].toString() : '';
      return '${bulan}_$idCapster';
    }
    if (collectionName == 'rekap_customer') {
      return row.isNotEmpty
          ? row[0].toString()
          : DateTime.now().microsecondsSinceEpoch.toString();
    }
    return row.isNotEmpty
        ? row[0].toString()
        : DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _sortKey(String collectionName, List<dynamic> row) {
    if (collectionName == 'pendapatan_harian' ||
        collectionName == 'buku_kas_umum') {
      final tanggal =
          row.length > 1 ? DateFormatter.toStorageDate(row[1].toString()) : '';
      final id = row.isNotEmpty ? row[0].toString() : '';
      return '${tanggal}_$id';
    }
    if (collectionName == 'operasional' ||
        collectionName == 'laporan_bulanan') {
      return row.isNotEmpty ? row[0].toString() : '';
    }
    return row.isNotEmpty ? row[0].toString() : '';
  }

  Future<void> _seedFirestoreIfEmpty() async {
    final users = await _firestore!.collection('users').limit(1).get();
    if (users.docs.isNotEmpty) return;
    for (final entry in _dummyCollections.entries) {
      for (final row in entry.value.skip(1)) {
        await _setFirestoreRow(entry.key, row);
      }
    }
  }

  void _seedDummyData() {
    if (_dummyCollections.isNotEmpty) return;
    _dummyCollections['capster'] = [
      _headers['capster']!,
      ['C001', 'Muhamad Diva Syarri', '081234567001', 'aktif'],
      ['C002', 'Umar Fauzi', '081234567002', 'aktif'],
      ['C003', 'Abdul Mujib', '081234567003', 'aktif'],
    ];
    _dummyCollections['layanan'] = [
      _headers['layanan']!,
      ['L001', 'SN', 'Santri', 11000, 'Potong Rambut', 'aktif'],
      ['L002', 'RC', 'Reguler Haircut', 15000, 'Potong Rambut', 'aktif'],
      ['L003', 'PC', 'Premium Cut', 20000, 'Potong Rambut', 'aktif'],
      ['L004', 'GC', 'Garden Cut', 23000, 'Potong Rambut', 'aktif'],
      ['L005', 'CJ', 'Cukur Jenggot/Kumis', 3000, 'Tambahan', 'aktif'],
      ['L006', 'KR', 'Keramas', 5000, 'Tambahan', 'aktif'],
      ['L007', 'CH', 'Coloring Hair', 50000, 'Tambahan', 'aktif'],
      ['L008', 'HS', 'Home Service', 35000, 'Tambahan', 'aktif'],
      ['L009', 'PR', 'Perming', 0, 'Tambahan', 'aktif'],
      [
        'L010',
        'KM',
        'Kartu Member / Cukur Gratis Member',
        0,
        'Member',
        'aktif'
      ],
    ];
    _dummyCollections['pendapatan_harian'] = [
      _headers['pendapatan_harian']!,
      [
        'P001',
        '2026-05-01',
        'C001',
        'Muhamad Diva Syarri',
        11,
        2,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        191000,
        11,
        2,
        13
      ],
      [
        'P002',
        '2026-05-01',
        'C002',
        'Umar Fauzi',
        6,
        7,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        201000,
        6,
        7,
        13
      ],
      [
        'P003',
        '2026-05-01',
        'C003',
        'Abdul Mujib',
        6,
        7,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        171000,
        6,
        7,
        13
      ],
      [
        'P004',
        '2026-05-31',
        'C001',
        'Muhamad Diva Syarri',
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1618000,
        0,
        0,
        0
      ],
      [
        'P005',
        '2026-05-31',
        'C002',
        'Umar Fauzi',
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1519000,
        0,
        0,
        0
      ],
      [
        'P006',
        '2026-05-31',
        'C003',
        'Abdul Mujib',
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1414000,
        0,
        0,
        0
      ],
    ];
    _dummyCollections['buku_kas_umum'] = [
      _headers['buku_kas_umum']!,
      [
        'K001',
        '2026-05-01',
        'Pendapatan usaha pondok',
        'Pendapatan Usaha',
        0,
        0,
        0,
        'Pendapatan Usaha otomatis berasal dari bagian pondok'
      ],
    ];
    _dummyCollections['operasional'] = [
      _headers['operasional']!,
      ['O001', '2026-05', 'Wifi', 'Wifi', 291400, 'Biaya wifi Mei'],
      ['O002', '2026-05', 'Listrik', 'Listrik', 1130720, 'Biaya listrik Mei'],
      [
        'O003',
        '2026-05',
        'Kebersihan',
        'Kebersihan',
        15000,
        'Biaya kebersihan'
      ],
      [
        'O004',
        '2026-05',
        'Perlengkapan',
        'Harga Pokok Penjualan',
        142500,
        'Perlengkapan cukur'
      ],
    ];
    _dummyCollections['laporan_bulanan'] = [_headers['laporan_bulanan']!];
    _dummyCollections['kasbon'] = [_headers['kasbon']!];
    _dummyCollections['rekap_customer'] = [_headers['rekap_customer']!];
    _dummyCollections['users'] = [
      _headers['users']!,
      ['UADMIN', 'admin', 'admin123', 'Admin Garden', 'admin', 'aktif', ''],
      [
        'U001',
        'diva',
        'capster123',
        'Muhamad Diva Syarri',
        'capster',
        'aktif',
        'C001'
      ],
      [
        'U002',
        'pemilik',
        'pemilik123',
        'Pemilik Pondok',
        'pemilik',
        'aktif',
        ''
      ],
      [
        'U003',
        'senior',
        'senior123',
        'Capster Senior',
        'adminHarian',
        'aktif',
        'C002'
      ],
    ];
  }

  // --- NOTIFICATIONS ---
  Future<List<AppNotification>> getNotifications() async {
    await init();
    if (_dummyMode || _firestore == null) {
      return [];
    }

    try {
      final snapshot = await _firestore!
          .collection('notifications')
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((doc) => AppNotification.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print("Warning: Gagal mengambil notifikasi: $e");
      return [];
    }
  }

  Stream<List<AppNotification>> streamNotifications() async* {
    await init();
    if (_dummyMode || _firestore == null) {
      yield [];
      return;
    }

    yield* _firestore!
        .collection('notifications')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<int> getUnreadNotificationCount() async {
    await init();
    if (_dummyMode || _firestore == null) return 0;
    
    try {
      final snapshot = await _firestore!
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Warning: Gagal menghitung notifikasi belum dibaca: $e");
      return 0;
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    await init();
    if (_dummyMode || _firestore == null) return;
    
    final notification = AppNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      date: DateTime.now(),
      type: type,
    );
    
    await _firestore!.collection('notifications').doc(notification.id).set(notification.toMap());
  }

  Future<void> markNotificationAsRead(String id) async {
    await init();
    if (_dummyMode || _firestore == null) return;
    await _firestore!.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    await init();
    if (_dummyMode || _firestore == null) return;
    
    final batch = _firestore!.batch();
    final snapshot = await _firestore!
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
        
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }

  // --- NERACA / MANAJEMEN ASET ---
  Future<NeracaModel> getNeraca(String bulan) async {
    await init();
    
    // Convert to YYYY-MM
    final monthKey = DateFormatter.toStorageMonth(bulan);
    final id = 'NRC-$monthKey';

    if (_dummyMode) {
      final rows = _dummyCollections['neraca'] ?? [];
      final header = _headers['neraca']!;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row[0] == id) {
          final map = <String, dynamic>{};
          for (var j = 0; j < header.length; j++) {
            map[header[j]] = row[j];
          }
          return NeracaModel.fromMap(map);
        }
      }
      return NeracaModel.defaultBalances(monthKey);
    }

    final doc = await _firestore!.collection('neraca').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return NeracaModel.fromMap(doc.data()!);
    }

    try {
      final query = await _firestore!.collection('neraca')
          .where('bulan', isLessThan: monthKey)
          .orderBy('bulan', descending: true)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        final oldModel = NeracaModel.fromMap(query.docs.first.data());
        return oldModel.copyWithNewBulan(monthKey);
      }
    } catch (e) {
      print("Warning: Gagal mencari fallback neraca $e");
    }

    return NeracaModel.defaultBalances(monthKey);
  }

  Future<void> saveNeraca(NeracaModel model) async {
    await init();
    if (_dummyMode) {
      final header = _headers['neraca']!;
      final map = model.toMap();
      final row = header.map((k) => map[k]).toList();
      await appendRow('neraca', row);
      return;
    }
    
    await _firestore!.collection('neraca').doc(model.idNeraca).set(model.toMap());
  }

  // --- SEMUA LAPORAN BULANAN (REKAP) ---
  Future<List<LaporanBulananModel>> getSemuaLaporanBulanan() async {
    await init();
    if (_dummyMode) {
      final rows = _dummyCollections['laporan_bulanan'] ?? [];
      final header = _headers['laporan_bulanan']!;
      final result = <LaporanBulananModel>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final map = <String, dynamic>{};
        for (var j = 0; j < header.length; j++) {
          map[header[j]] = row[j];
        }
        result.add(LaporanBulananModel.fromMap(map));
      }
      return result;
    }

    final querySnapshot = await _firestore!.collection('laporan_bulanan').get();
    return querySnapshot.docs
        .map((doc) => LaporanBulananModel.fromMap(doc.data()))
        .toList();
  }
}
