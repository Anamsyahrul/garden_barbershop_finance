import 'package:flutter/material.dart';

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
    final pendapatan = await firebase.getPendapatanByMonth(bulan);
    final operasional = await firebase.getOperasionalByMonth(bulan);
    final kasbon = await firebase.getKasbonByMonth(bulan);
    final laporan = calc.generateLaporanBulanan(
      bulan: bulan,
      capsterAktif: capster,
      pendapatan: pendapatan,
      operasional: operasional,
      kasbon: kasbon,
    );
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
        semuaPendapatan: pendapatan,
        semuaCapster: capster,
        laporanBulanan: ownLaporan,
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
      semuaPendapatan: pendapatan,
      semuaCapster: capster,
      laporanBulanan: laporan,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: DashboardScreen.routeName,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [
          Padding(
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

  Widget _primaryBalance(_DashboardData data) {
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
                        const Text(
                          'GARDEN FINANCE',
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
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
    required this.semuaPendapatan,
    required this.semuaCapster,
    required this.laporanBulanan,
  });

  final int totalPendapatan;
  final int totalOperasional;
  final int jumlahCapsterAktif;
  final int totalCustomerBulanan;
  final int totalBagianCapster;
  final int totalBagianPondok;
  final AppUser? user;
  final List<PendapatanHarianModel> semuaPendapatan;
  final List<CapsterModel> semuaCapster;
  final List<LaporanBulananModel> laporanBulanan;
}
