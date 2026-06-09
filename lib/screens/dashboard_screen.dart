import 'package:flutter/material.dart';

import '../services/calculation_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_widgets.dart';
import 'akun_pengguna_screen.dart';
import 'buku_kas_screen.dart';
import 'capster_screen.dart';
import 'laporan_screen.dart';
import 'layanan_screen.dart';
import 'operasional_screen.dart';
import 'pendapatan_harian_screen.dart';
import 'sinkronisasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final user = await AuthService().currentUser();
    final bulan = DateFormatter.formatMonth(DateTime.now());
    final firebase = FirebaseService.instance;
    final calc = CalculationService();
    final capster = await firebase.getCapsterAktif();
    final pendapatan = await firebase.getPendapatanByMonth(bulan);
    final operasional = await firebase.getOperasionalByMonth(bulan);
    final laporan = calc.generateLaporanBulanan(
      bulan: bulan,
      capsterAktif: capster,
      pendapatan: pendapatan,
      operasional: operasional,
    );
    if ((user?.role == UserRole.capster ||
            user?.role == UserRole.adminHarian) &&
        user!.idCapster.isNotEmpty) {
      final ownPendapatan = pendapatan
          .where((item) => item.idCapster == user.idCapster)
          .fold(0, (total, item) => total + item.pendapatan);
      final ownLaporan =
          laporan.where((item) => item.idCapster == user.idCapster).toList();
      return _DashboardData(
        totalPendapatan: ownPendapatan,
        totalOperasional:
            ownLaporan.isEmpty ? 0 : ownLaporan.first.operasionalPerCapster,
        jumlahCapsterAktif: 1,
        totalBagianCapster:
            ownLaporan.fold(0, (total, item) => total + item.bagianCapster),
        totalBagianPondok: 0,
        user: user,
      );
    }
    return _DashboardData(
      totalPendapatan:
          pendapatan.fold(0, (total, item) => total + item.pendapatan),
      totalOperasional: calc.hitungTotalOperasional(operasional),
      jumlahCapsterAktif: capster.length,
      totalBagianCapster:
          laporan.fold(0, (total, item) => total + item.bagianCapster),
      totalBagianPondok:
          laporan.fold(0, (total, item) => total + item.bagianPondok),
      user: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(),
      bottomNavigationBar:
          const AppBottomNav(currentRoute: DashboardScreen.routeName),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load();
          });
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              children: [
                _primaryBalance(data),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 24) / 3
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
                            value:
                                CurrencyFormatter.format(data.totalOperasional),
                            icon: Icons.receipt_long_outlined,
                            tint: AppColors.brass,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: CompactMetricCard(
                            title:
                                personalView ? 'Akun Capster' : 'Capster Aktif',
                            value: personalView
                                ? (data.user?.name ?? '-')
                                : '${data.jumlahCapsterAktif} orang',
                            icon: Icons.people_alt_outlined,
                            tint: AppColors.teal,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: CompactMetricCard(
                            title:
                                personalView ? 'Bagian Saya' : 'Bagian Pondok',
                            value: CurrencyFormatter.format(
                              personalView
                                  ? data.totalBagianCapster
                                  : data.totalBagianPondok,
                            ),
                            icon: Icons.storefront_outlined,
                            tint: AppColors.charcoalSoft,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Menu Utama',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = _load();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (role == UserRole.admin) ...[
                  _quickAction(
                    context,
                    title: 'Pendapatan Harian',
                    subtitle: 'Input layanan capster',
                    icon: Icons.payments_outlined,
                    route: PendapatanHarianScreen.routeName,
                    tint: AppColors.teal,
                  ),
                  const SizedBox(height: 8),
                  _quickAction(
                    context,
                    title: 'Buku Kas Umum',
                    subtitle: 'Catat penerimaan dan pengeluaran',
                    icon: Icons.account_balance_wallet_outlined,
                    route: BukuKasScreen.routeName,
                    tint: AppColors.brass,
                  ),
                  const SizedBox(height: 8),
                  _quickAction(
                    context,
                    title: 'Operasional',
                    subtitle: 'Input biaya bulanan',
                    icon: Icons.receipt_long_outlined,
                    route: OperasionalScreen.routeName,
                    tint: AppColors.charcoalSoft,
                  ),
                ],
                if (role == UserRole.adminHarian) ...[
                  _quickAction(
                    context,
                    title: 'Pendapatan Harian',
                    subtitle: 'Input transaksi harian capster',
                    icon: Icons.payments_outlined,
                    route: PendapatanHarianScreen.routeName,
                    tint: AppColors.teal,
                  ),
                  const SizedBox(height: 8),
                  _quickAction(
                    context,
                    title: 'Laporan Saya',
                    subtitle: 'Lihat rekap capster terkait',
                    icon: Icons.table_chart_outlined,
                    route: LaporanScreen.routeName,
                    tint: AppColors.brass,
                  ),
                ],
                if (role == UserRole.pemilik) ...[
                  _quickAction(
                    context,
                    title: 'Laporan Pembagian Hasil',
                    subtitle: 'Pantau hasil capster dan pondok',
                    icon: Icons.table_chart_outlined,
                    route: LaporanScreen.routeName,
                    tint: AppColors.teal,
                  ),
                  const SizedBox(height: 8),
                  _quickAction(
                    context,
                    title: 'Buku Kas Umum',
                    subtitle: 'Lihat catatan kas',
                    icon: Icons.account_balance_wallet_outlined,
                    route: BukuKasScreen.routeName,
                    tint: AppColors.brass,
                  ),
                  const SizedBox(height: 8),
                  _quickAction(
                    context,
                    title: 'Operasional',
                    subtitle: 'Lihat biaya bulanan',
                    icon: Icons.receipt_long_outlined,
                    route: OperasionalScreen.routeName,
                    tint: AppColors.charcoalSoft,
                  ),
                ],
                if (role == UserRole.capster)
                  _quickAction(
                    context,
                    title: 'Laporan Saya',
                    subtitle: 'Lihat rekap dan bagian capster',
                    icon: Icons.table_chart_outlined,
                    route: LaporanScreen.routeName,
                    tint: AppColors.teal,
                  ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _secondaryActions(context, role, width),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _primaryBalance(_DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.content_cut,
                      color: AppColors.tealDark, size: 21),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Garden Barbershop Finance',
                    style: TextStyle(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {
                      _future = _load();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.user == null
                  ? 'Dashboard'
                  : '${data.user!.name} • ${data.user!.role.label}',
              style: const TextStyle(
                color: AppColors.tealDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Total Pendapatan Bulan Ini',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(data.totalPendapatan),
              style: const TextStyle(
                color: AppColors.charcoal,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: AppColors.tealDark, size: 20),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Bagian capster',
                      style: TextStyle(
                        color: AppColors.tealDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(data.totalBagianCapster),
                    style: const TextStyle(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required Color tint,
  }) {
    return MobileInfoTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      tint: tint,
      onTap: () => Navigator.pushNamed(context, route),
      trailing: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _secondaryAction(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _menuIcon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _secondaryActions(
    BuildContext context,
    UserRole role,
    double width,
  ) {
    if (role == UserRole.admin) {
      return [
        _secondaryAction(context, 'Data Capster', Icons.people_alt_outlined,
            CapsterScreen.routeName, width),
        _secondaryAction(
            context,
            'Akun Pengguna',
            Icons.manage_accounts_outlined,
            AkunPenggunaScreen.routeName,
            width),
        _secondaryAction(context, 'Data Layanan',
            Icons.design_services_outlined, LayananScreen.routeName, width),
        _secondaryAction(context, 'Laporan Hasil', Icons.table_chart_outlined,
            LaporanScreen.routeName, width),
        _secondaryAction(context, 'Sinkronisasi', Icons.sync,
            SinkronisasiScreen.routeName, width),
      ];
    }
    if (role == UserRole.adminHarian) {
      return [
        _secondaryAction(context, 'Input Pendapatan', Icons.payments_outlined,
            PendapatanHarianScreen.routeName, width),
        _secondaryAction(context, 'Laporan Saya', Icons.table_chart_outlined,
            LaporanScreen.routeName, width),
      ];
    }
    if (role == UserRole.pemilik) {
      return [
        _secondaryAction(context, 'Laporan Hasil', Icons.table_chart_outlined,
            LaporanScreen.routeName, width),
      ];
    }
    return [
      _secondaryAction(context, 'Laporan Saya', Icons.table_chart_outlined,
          LaporanScreen.routeName, width),
    ];
  }

  Widget _menuIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.brass, size: 21),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.totalPendapatan,
    required this.totalOperasional,
    required this.jumlahCapsterAktif,
    required this.totalBagianCapster,
    required this.totalBagianPondok,
    required this.user,
  });

  final int totalPendapatan;
  final int totalOperasional;
  final int jumlahCapsterAktif;
  final int totalBagianCapster;
  final int totalBagianPondok;
  final AppUser? user;
}
