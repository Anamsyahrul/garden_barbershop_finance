import 'package:flutter/material.dart';

import '../screens/akun_pengguna_screen.dart';
import '../screens/buku_kas_screen.dart';
import '../screens/capster_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/laporan_screen.dart';
import '../screens/layanan_screen.dart';
import '../screens/login_screen.dart';
import '../screens/operasional_screen.dart';
import '../screens/pendapatan_harian_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: AuthService().currentUser(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final role = user?.role ?? UserRole.admin;
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
              children: [
                _DrawerHero(user: user, role: role),
                const SizedBox(height: 14),
                _item(context, Icons.dashboard_rounded, 'Dashboard',
                    DashboardScreen.routeName),
                if (role == UserRole.admin) ...[
                  _item(context, Icons.people_alt_rounded, 'Data Capster',
                      CapsterScreen.routeName),
                  _item(context, Icons.manage_accounts_rounded, 'Akun Pengguna',
                      AkunPenggunaScreen.routeName),
                  _item(context, Icons.design_services_rounded, 'Data Layanan',
                      LayananScreen.routeName),
                  _item(context, Icons.payments_rounded, 'Pendapatan Harian',
                      PendapatanHarianScreen.routeName),
                  _item(context, Icons.account_balance_wallet_rounded,
                      'Buku Kas Umum', BukuKasScreen.routeName),
                  _item(context, Icons.receipt_long_rounded, 'Operasional',
                      OperasionalScreen.routeName),
                ],
                if (role == UserRole.adminHarian) ...[
                  _item(context, Icons.payments_rounded, 'Pendapatan Harian',
                      PendapatanHarianScreen.routeName),
                ],
                if (role == UserRole.pemilik) ...[
                  _item(context, Icons.account_balance_wallet_rounded,
                      'Buku Kas Umum', BukuKasScreen.routeName),
                  _item(context, Icons.receipt_long_rounded, 'Operasional',
                      OperasionalScreen.routeName),
                ],
                _item(context, Icons.bar_chart_rounded,
                    'Laporan Pembagian Hasil', LaporanScreen.routeName),
                const Divider(),
                _logoutItem(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item(
      BuildContext context, IconData icon, String title, String route) {
    final selected = ModalRoute.of(context)?.settings.name == route;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.mint,
        tileColor: selected ? AppColors.mint : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.14)
                : AppColors.panel,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: selected ? AppColors.tealDark : AppColors.charcoalSoft,
            size: 21,
          ),
        ),
        title: Text(title),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.tealDark, size: 18)
            : null,
        onTap: () => Navigator.pushReplacementNamed(context, route),
      ),
    );
  }

  Widget _logoutItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.logout_rounded,
              color: AppColors.danger, size: 21),
        ),
        title: const Text('Keluar'),
        onTap: () async {
          await AuthService().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (_) => false,
          );
        },
      ),
    );
  }
}

class _DrawerHero extends StatelessWidget {
  const _DrawerHero({required this.user, required this.role});

  final AppUser? user;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -30,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white.withValues(alpha: 0.10),
              size: 118,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(size: 52),
              const SizedBox(height: 16),
              const Text(
                'Garden Barbershop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user == null
                    ? 'Finance Control'
                    : '${user!.name} • ${role.label}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.26), width: 1.3),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
