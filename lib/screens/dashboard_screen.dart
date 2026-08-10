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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final user = await AuthService().currentUser();
    final bulan = DateFormatter.formatMonthKey(DateTime.now());
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
        totalBagianPondok:
            ownLaporan.fold(0, (total, item) => total + item.bagianPondok),
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
    return ResponsiveScaffold(
      currentRoute: DashboardScreen.routeName,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [

          const NotificationBell(),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              tooltip: 'Refresh data',
              onPressed: () {
                setState(() {
                  _future = _load();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
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
                              title: personalView
                                  ? 'Akun Capster'
                                  : 'Capster Aktif',
                              value: personalView
                                  ? (data.user?.name ?? '-')
                                  : '${data.jumlahCapsterAktif} orang',
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
                  PremiumSectionTitle(
                    title: 'Menu Utama',
                    subtitle: 'Akses fitur yang paling sering dipakai',
                    action: TextButton.icon(
                      onPressed: () => setState(() => _future = _load()),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._mainActions(context, role),
                  const SizedBox(height: 20),
                  PremiumSectionTitle(
                    title: 'Kelola Data',
                    subtitle: 'Menu administrasi dan laporan',
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
      padding: const EdgeInsets.all(24),
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
              size: 140,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GARDEN FINANCE',
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.user == null
                              ? 'Admin Dashboard'
                              : '${data.user!.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.user?.role.label.toUpperCase() ?? 'LIVE', 
                      style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
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

  List<Widget> _mainActions(BuildContext context, UserRole role) {
    final actions = <_ActionData>[];
    if (role == UserRole.admin || role == UserRole.adminHarian) {
      actions.add(_ActionData(
          'Input Harian',
          'Catat transaksi',
          Icons.payments_rounded,
          PendapatanHarianScreen.routeName,
          AppColors.teal));
    }
    if (role == UserRole.admin || role == UserRole.pemilik) {
      actions.add(_ActionData(
          'Buku Kas',
          'Penerimaan & keluar',
          Icons.account_balance_wallet_rounded,
          BukuKasScreen.routeName,
          AppColors.blue));
      actions.add(_ActionData(
          'Operasional',
          'Biaya bulanan',
          Icons.receipt_long_rounded,
          OperasionalScreen.routeName,
          AppColors.brass));
    }
    actions.add(_ActionData(
        role == UserRole.capster ? 'Laporan Saya' : 'Laporan',
        'Pembagian hasil',
        Icons.table_chart_rounded,
        LaporanScreen.routeName,
        AppColors.emerald));

    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 720
              ? (constraints.maxWidth - 36) / 4
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final action in actions)
                SizedBox(
                  width: width,
                  child: _quickActionCard(context, action),
                ),
            ],
          );
        },
      ),
    ];
  }

  Widget _quickActionCard(BuildContext context, _ActionData action) {
    return Material(
      color: AppColors.paper,
      borderRadius: AppTheme.radiusMedium,
      child: InkWell(
        borderRadius: AppTheme.radiusMedium,
        onTap: () => Navigator.pushNamed(context, action.route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppTheme.radiusMedium,
            border: Border.all(color: AppColors.line),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.tint, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w900,
                    fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryAction(BuildContext context, String title, IconData icon,
      String route, double width) {
    return SizedBox(
      width: width,
      child: MobileInfoTile(
        title: title,
        subtitle: 'Buka dan kelola $title',
        icon: icon,
        onTap: () => Navigator.pushNamed(context, route),
        tint: AppColors.tealDark,
      ),
    );
  }

  List<Widget> _secondaryActions(
      BuildContext context, UserRole role, double width) {
    if (role == UserRole.admin) {
      return [
        _secondaryAction(context, 'Data Capster', Icons.people_alt_rounded,
            CapsterScreen.routeName, width),
        _secondaryAction(context, 'Akun Pengguna',
            Icons.manage_accounts_rounded, AkunPenggunaScreen.routeName, width),
        _secondaryAction(context, 'Data Layanan', Icons.design_services_rounded,
            LayananScreen.routeName, width),
        _secondaryAction(context, 'Laporan Hasil', Icons.table_chart_rounded,
            LaporanScreen.routeName, width),
      ];
    }
    if (role == UserRole.adminHarian) {
      return [
        _secondaryAction(context, 'Input Pendapatan', Icons.payments_rounded,
            PendapatanHarianScreen.routeName, width),
        _secondaryAction(context, 'Laporan Saya', Icons.table_chart_rounded,
            LaporanScreen.routeName, width),
      ];
    }
    if (role == UserRole.pemilik) {
      return [
        _secondaryAction(context, 'Laporan Hasil', Icons.table_chart_rounded,
            LaporanScreen.routeName, width)
      ];
    }
    return [
      _secondaryAction(context, 'Laporan Saya', Icons.table_chart_rounded,
          LaporanScreen.routeName, width)
    ];
  }
}

class _ActionData {
  const _ActionData(
      this.title, this.subtitle, this.icon, this.route, this.tint);

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color tint;
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
