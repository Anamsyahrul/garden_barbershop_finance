import 'package:flutter/material.dart';
import '../models/cabang_model.dart';

import '../services/calculation_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/notification_bell.dart';
import '../utils/migration_tool.dart';
import '../services/migration_service.dart';
import '../models/capster_model.dart';
import '../models/absensi_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../models/user_role.dart';
import '../models/user_model.dart';
import '../models/laporan_bulanan_model.dart';
import 'akun_pengguna_screen.dart';
import 'buku_kas_screen.dart';
import 'capster_screen.dart';
import 'laporan_screen.dart';
import 'layanan_screen.dart';
import 'operasional_screen.dart';
import 'pendapatan_harian_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final user = await AuthService().currentUser();
    final bulan = DateFormatter.formatMonthKey(_selectedDate);
    final firebase = FirebaseService.instance;
    final calc = CalculationService();
    final capster = await firebase.getCapsterAktif();
    final cabangs = await firebase.getSemuaCabang();
    if (cabangs.isNotEmpty && !cabangs.any((c) => c.idCabang == firebase.activeCabang)) {
      firebase.setActiveCabang(cabangs.first.idCabang);
    }
    final pendapatan = await firebase.getPendapatanByMonth(bulan);
    final operasional = await firebase.getOperasionalByMonth(bulan);
    final kasbon = await firebase.getKasbonByMonth(bulan);
    final bonusDenda = await firebase.getBonusDendaByMonth(bulan);
    final persentase = await firebase.getPersentaseCapster();
    final laporan = calc.generateLaporanBulanan(
      bulan: bulan,
      capsterAktif: capster,
      pendapatan: pendapatan,
      operasional: operasional,
      kasbon: kasbon,
      bonusDenda: bonusDenda,
      persentaseCapster: persentase,
    );
    final absensiHariIni = await firebase.getAbsensiByDate(DateFormatter.formatDateKey(DateTime.now()));

    if ((user?.role == UserRole.capster ||
            user?.role == UserRole.adminHarian) &&
        user!.idCapster.isNotEmpty) {
      final ownPendapatan = pendapatan
          .where((item) => item.idCapster == user.idCapster);
      final totalPendapatanKotor = ownPendapatan.fold(0, (total, item) => total + item.pendapatan);
      final totalCustomerBulanIni = ownPendapatan.fold(0, (total, item) => total + item.totalCustomer);
      final ownLaporan =
          laporan.where((item) => item.idCapster == user.idCapster).toList();
      return _DashboardData(
        totalPendapatan: totalPendapatanKotor,
        totalOperasional:
            ownLaporan.isEmpty ? 0 : ownLaporan.first.operasionalPerCapster,
        jumlahCapsterAktif: 1,
        totalCustomerBulanan: totalCustomerBulanIni,
        totalBagianCapster:
            ownLaporan.fold(0, (total, item) => total + item.bagianCapster),
        totalBagianPondok:
            ownLaporan.fold(0, (total, item) => total + item.bagianPondok),
        user: user,
      cabangs: cabangs,
        semuaPendapatan: pendapatan,
        semuaCapster: capster,
        laporanBulanan: ownLaporan,
        absensiHariIni: absensiHariIni,
      );
    }
    return _DashboardData(
      totalPendapatan:
          pendapatan.fold(0, (total, item) => total + item.pendapatan),
      totalOperasional: calc.hitungTotalOperasional(operasional),
      jumlahCapsterAktif: capster.length,
      totalCustomerBulanan: pendapatan.fold(0, (total, item) => total + item.totalCustomer),
      totalBagianCapster:
          laporan.fold(0, (total, item) => total + item.bagianCapster),
      totalBagianPondok:
          laporan.fold(0, (total, item) => total + item.bagianPondok),
      user: user,
      cabangs: cabangs,
      semuaPendapatan: pendapatan,
      semuaCapster: capster,
      laporanBulanan: laporan,
      absensiHariIni: absensiHariIni,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: DashboardScreen.routeName,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          FutureBuilder<_DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final data = snapshot.data!;
              if (data.user?.role == UserRole.pemilik || data.user?.role == UserRole.admin) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.storefront_rounded),
                      tooltip: 'Kelola Cabang',
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/cabang');
                        setState(() {
                          _future = _load();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      tooltip: 'Pengaturan',
                      onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: NotificationBell(),
          ),
        ],
      ),
      body: _dashboardBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: FutureBuilder<_DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Terjadi Kesalahan:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final role = data.user?.role ?? UserRole.admin;
              final personalView =
                  role == UserRole.capster || role == UserRole.adminHarian;
              return ListView(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 120 + MediaQuery.paddingOf(context).bottom),
                children: [
                  _primaryBalance(data),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth >= 720
                          ? (constraints.maxWidth - 36) / 4
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: CompactMetricCard(
                              title: personalView
                                  ? 'Beban Operasional'
                                  : 'Operasional',
                              value: CurrencyFormatter.format(
                                  data.totalOperasional),
                              icon: Icons.receipt_long_rounded,
                              tint: AppColors.brass,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: CompactMetricCard(
                              title: 'Total Customer',
                              value: '${data.totalCustomerBulanan} orang',
                              icon: Icons.groups_2_rounded,
                              tint: AppColors.blue,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: CompactMetricCard(
                              title: 'Bagian Pondok',
                              value: CurrencyFormatter.format(data.totalBagianPondok),
                              icon: Icons.account_balance_rounded,
                              tint: AppColors.teal,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: CompactMetricCard(
                              title: personalView
                                  ? 'Bagian Saya'
                                  : 'Bagian Capster',
                              value: CurrencyFormatter.format(data.totalBagianCapster),
                              icon: Icons.savings_rounded,
                              tint: const Color(0xFFF59E0B), // Amber/Brass
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (personalView) _absensiCard(context, data),
                  if (personalView) const SizedBox(height: 20),
                  _dailyReportSection(context, data),
                  const SizedBox(height: 20),
                  _monthlyReportSection(context, data),
                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _dashboardBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: _ambientGlow(240, AppColors.teal.withValues(alpha: 0.13)),
        ),
        Positioned(
          top: 220,
          left: -120,
          child: _ambientGlow(210, AppColors.brass.withValues(alpha: 0.11)),
        ),
        Positioned(
          bottom: -150,
          right: -80,
          child: _ambientGlow(260, AppColors.blue.withValues(alpha: 0.07)),
        ),
        child,
      ],
    );
  }

  Widget _ambientGlow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  Widget _absensiCard(BuildContext context, _DashboardData data) {
    if (data.user == null || data.user!.idCapster.isEmpty) return const SizedBox();
    
    final idCapster = data.user!.idCapster;
    final absensiList = data.absensiHariIni.where((a) => a.idCapster == idCapster).toList();
    final today = DateFormatter.formatDateKey(DateTime.now());
    
    AbsensiModel? currentAbsensi;
    if (absensiList.isNotEmpty) {
      currentAbsensi = absensiList.first;
    }

    final hasCheckedIn = currentAbsensi != null;
    final hasCheckedOut = currentAbsensi?.waktuCheckOut != null && currentAbsensi!.waktuCheckOut!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absensi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Jangan lupa check-in saat mulai kerja.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasCheckedIn)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _prosesCheckIn(data.user!.idCapster, data.user!.name),
                icon: const Icon(Icons.login),
                label: const Text('Check In Sekarang'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              ),
            )
          else if (!hasCheckedOut)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Check In: ${currentAbsensi.waktuCheckIn}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tealDark)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _prosesCheckOut(currentAbsensi!),
                    icon: const Icon(Icons.logout),
                    label: const Text('Check Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Terima kasih sudah bekerja hari ini!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text('Check In: ${currentAbsensi.waktuCheckIn} • Check Out: ${currentAbsensi.waktuCheckOut}', 
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _prosesCheckIn(String idCapster, String namaCapster) async {
    try {
      final now = DateTime.now();
      final waktuCheckIn = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final today = DateFormatter.formatDateKey(now);
      
      final model = AbsensiModel(
        idAbsensi: 'ABS${now.millisecondsSinceEpoch}',
        tanggal: today,
        idCapster: idCapster,
        namaCapster: namaCapster,
        waktuCheckIn: waktuCheckIn,
      );
      
      await FirebaseService.instance.saveAbsensi(model);
      setState(() {
        _future = _load();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil Check-In')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _prosesCheckOut(AbsensiModel currentAbsensi) async {
    try {
      final now = DateTime.now();
      final waktuCheckOut = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      final model = AbsensiModel(
        idAbsensi: currentAbsensi.idAbsensi,
        tanggal: currentAbsensi.tanggal,
        idCapster: currentAbsensi.idCapster,
        namaCapster: currentAbsensi.namaCapster,
        waktuCheckIn: currentAbsensi.waktuCheckIn,
        waktuCheckOut: waktuCheckOut,
        idCabang: currentAbsensi.idCabang,
      );
      
      await FirebaseService.instance.saveAbsensi(model);
      setState(() {
        _future = _load();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil Check-Out')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Widget _primaryBalance(_DashboardData data) {
    final activeCabang = data.cabangs.firstWhere(
      (c) => c.idCabang == FirebaseService.instance.activeCabang,
      orElse: () => data.cabangs.isNotEmpty ? data.cabangs.first : CabangModel(idCabang: '', namaCabang: 'Utama', alamat: ''),
    );
    final isMultiBranch = data.user?.role == UserRole.pemilik || data.user?.role == UserRole.admin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.cut_rounded,
              color: Colors.white.withValues(alpha: 0.1),
              size: 110,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
            
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'GARDEN FINANCE',
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (isMultiBranch) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activeCabang.namaCabang.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.user == null
                              ? 'Admin Dashboard'
                              : '${data.user!.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.user?.role.label.toUpperCase() ?? 'LIVE', 
                      style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.0)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'PENDAPATAN BULAN INI',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(data.totalPendapatan),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
        );
  }

  Widget _dailyReportSection(BuildContext context, _DashboardData data) {
    final dateStr = DateFormatter.formatDateKey(_selectedDate);
    final dailyPendapatan = data.semuaPendapatan.where((p) => p.tanggal == dateStr).toList();
    final role = data.user?.role ?? UserRole.admin;
    final isPersonalView = role == UserRole.capster || role == UserRole.adminHarian;

    final displayedPendapatan = isPersonalView 
        ? dailyPendapatan.where((p) => p.idCapster == data.user?.idCapster).toList()
        : dailyPendapatan;

    var totalKotor = 0;
    var totalCustomer = 0;
    for (var p in displayedPendapatan) {
      totalKotor += p.pendapatan;
      totalCustomer += p.totalCustomer;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSectionTitle(
          title: 'Laporan Harian',
          subtitle: 'Kinerja harian interaktif',
          action: TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null && picked != _selectedDate) {
                final oldMonth = DateFormatter.formatMonthKey(_selectedDate);
                final newMonth = DateFormatter.formatMonthKey(picked);
                setState(() {
                  _selectedDate = picked;
                  if (oldMonth != newMonth) {
                    _future = _load();
                  }
                });
              }
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(DateFormatter.formatDate(_selectedDate)),
          ),
        ),
        const SizedBox(height: 12),
        if (displayedPendapatan.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: AppTheme.radiusLarge,
              border: Border.all(color: AppColors.line),
            ),
            child: const Center(
              child: Text(
                'Belum ada data pendapatan untuk hari ini.',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: AppTheme.radiusLarge,
              border: Border.all(color: AppColors.line),
              boxShadow: AppTheme.softShadow,
            ),
            child: ClipRRect(
              borderRadius: AppTheme.radiusLarge,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(AppColors.teal.withValues(alpha: 0.08)),
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(label: Text('Nama Capster', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark))),
                    DataColumn(label: Text('RG/RC', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark)), numeric: true),
                    DataColumn(label: Text('CS', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark)), numeric: true),
                    DataColumn(label: Text('CU', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark)), numeric: true),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark)), numeric: true),
                    DataColumn(label: Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark)), numeric: true),
                  ],
                  rows: [
                    for (var p in displayedPendapatan)
                      DataRow(
                        cells: [
                          DataCell(Text(p.namaCapster, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal))),
                          DataCell(Text('${p.jumlahLayanan['RC'] ?? p.jumlahLayanan['RG'] ?? 0}')),
                          DataCell(Text('${p.cs}')),
                          DataCell(Text('${p.cu}')),
                          DataCell(Text('${p.totalCustomer}', style: const TextStyle(fontWeight: FontWeight.w800))),
                          DataCell(Text(CurrencyFormatter.format(p.pendapatan), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal))),
                        ],
                      ),
                    // Total Row
                    if (!isPersonalView && displayedPendapatan.length > 1)
                      DataRow(
                        color: WidgetStatePropertyAll(AppColors.brass.withValues(alpha: 0.1)),
                        cells: [
                          const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.charcoal))),
                          DataCell(Text('${displayedPendapatan.fold(0, (sum, p) => sum + (p.jumlahLayanan['RC'] ?? p.jumlahLayanan['RG'] ?? 0))}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.charcoal))),
                          DataCell(Text('${displayedPendapatan.fold(0, (sum, p) => sum + p.cs)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.charcoal))),
                          DataCell(Text('${displayedPendapatan.fold(0, (sum, p) => sum + p.cu)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.charcoal))),
                          DataCell(Text('$totalCustomer', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.charcoal))),
                          DataCell(Text(CurrencyFormatter.format(totalKotor), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.charcoal))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _monthlyReportSection(BuildContext context, _DashboardData data) {
    if (data.laporanBulanan.isEmpty) return const SizedBox.shrink();
    
    final role = data.user?.role ?? UserRole.admin;
    final isPersonalView = role == UserRole.capster || role == UserRole.adminHarian;

    final totalKotor = data.laporanBulanan.fold(0, (sum, item) => sum + item.pendapatanKotor);
    final totalBersih = data.laporanBulanan.fold(0, (sum, item) => sum + item.pendapatanBersih);
    final totalCapster = data.laporanBulanan.fold(0, (sum, item) => sum + item.bagianCapster);
    final totalPondok = data.laporanBulanan.fold(0, (sum, item) => sum + item.bagianPondok);
    final totalKasbonAll = data.laporanBulanan.fold(0, (sum, item) => sum + item.totalKasbon);
    final totalSisaAll = data.laporanBulanan.fold(0, (sum, item) => sum + item.sisaDiterimaCapster);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSectionTitle(
          title: 'Laporan Bulanan',
          subtitle: 'Kinerja bulan ${DateFormatter.displayMonth(DateFormatter.formatMonthKey(_selectedDate))}',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppTheme.radiusLarge,
            border: Border.all(color: AppColors.line),
            boxShadow: AppTheme.softShadow,
          ),
          child: ClipRRect(
            borderRadius: AppTheme.radiusLarge,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(AppColors.blue.withValues(alpha: 0.08)),
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('Nama Capster', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy))),
                  DataColumn(label: Text('Pendapatan\nKotor', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                  DataColumn(label: Text('Beban\nOperasional', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                  DataColumn(label: Text('Pendapatan\nBersih', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                  DataColumn(label: Text('Bagian\nCapster', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                  DataColumn(label: Text('Potongan\nKasbon', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                  DataColumn(label: Text('Sisa\nDiterima', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                  DataColumn(label: Text('Bagian\nPondok', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)), numeric: true),
                ],
                rows: [
                  for (var lap in data.laporanBulanan)
                    DataRow(
                      cells: [
                        DataCell(Text(lap.namaCapster, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal))),
                        DataCell(Text(CurrencyFormatter.format(lap.pendapatanKotor))),
                        DataCell(Text(CurrencyFormatter.format(lap.operasionalPerCapster), style: const TextStyle(color: AppColors.danger))),
                        DataCell(Text(CurrencyFormatter.format(lap.pendapatanBersih), style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text(CurrencyFormatter.format(lap.bagianCapster), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brass))),
                        DataCell(Text(CurrencyFormatter.format(lap.totalKasbon), style: const TextStyle(color: AppColors.danger))),
                        DataCell(Text(CurrencyFormatter.format(lap.sisaDiterimaCapster), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brass))),
                        DataCell(Text(CurrencyFormatter.format(lap.bagianPondok), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal))),
                      ],
                    ),
                  // Total Row
                  if (!isPersonalView && data.laporanBulanan.length > 1)
                    DataRow(
                      color: WidgetStatePropertyAll(AppColors.blue.withValues(alpha: 0.1)),
                      cells: [
                        const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))),
                        DataCell(Text(CurrencyFormatter.format(totalKotor), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))),
                        DataCell(Text('-', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))),
                        DataCell(Text(CurrencyFormatter.format(totalBersih), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))),
                        DataCell(Text(CurrencyFormatter.format(totalCapster), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brass))),
                        DataCell(Text(CurrencyFormatter.format(totalKasbonAll), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.danger))),
                        DataCell(Text(CurrencyFormatter.format(totalSisaAll), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brass))),
                        DataCell(Text(CurrencyFormatter.format(totalPondok), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.teal))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.totalPendapatan,
    required this.totalOperasional,
    required this.jumlahCapsterAktif,
    required this.totalCustomerBulanan,
    required this.totalBagianCapster,
    required this.totalBagianPondok,
    required this.user,
    required this.cabangs,
    required this.semuaPendapatan,
    required this.semuaCapster,
    required this.laporanBulanan,
    required this.absensiHariIni,
  });

  final int totalPendapatan;
  final int totalOperasional;
  final int jumlahCapsterAktif;
  final int totalCustomerBulanan;
  final int totalBagianCapster;
  final int totalBagianPondok;
  final AppUser? user;
  final List<CabangModel> cabangs;
  final List<PendapatanHarianModel> semuaPendapatan;
  final List<CapsterModel> semuaCapster;
  final List<LaporanBulananModel> laporanBulanan;
  final List<AbsensiModel> absensiHariIni;
}
