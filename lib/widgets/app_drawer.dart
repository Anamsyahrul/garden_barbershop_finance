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
import '../screens/sinkronisasi_screen.dart';
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
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    border: Border(
                      bottom: BorderSide(color: AppColors.line),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BrandMark(size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Garden Barbershop',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user == null
                            ? 'Finance Control'
                            : '${user.name} • ${role.label}',
                        style: const TextStyle(
                          color: AppColors.tealDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _item(context, Icons.dashboard, 'Dashboard',
                    DashboardScreen.routeName),
                if (role == UserRole.admin) ...[
                  _item(context, Icons.people, 'Data Capster',
                      CapsterScreen.routeName),
                  _item(context, Icons.manage_accounts, 'Akun Pengguna',
                      AkunPenggunaScreen.routeName),
                  _item(context, Icons.design_services, 'Data Layanan',
                      LayananScreen.routeName),
                  _item(context, Icons.payments, 'Pendapatan Harian',
                      PendapatanHarianScreen.routeName),
                  _item(context, Icons.account_balance_wallet, 'Buku Kas Umum',
                      BukuKasScreen.routeName),
                  _item(context, Icons.receipt_long, 'Operasional',
                      OperasionalScreen.routeName),
                  _item(context, Icons.sync, 'Sinkronisasi',
                      SinkronisasiScreen.routeName),
                ],
                if (role == UserRole.adminHarian) ...[
                  _item(context, Icons.payments, 'Pendapatan Harian',
                      PendapatanHarianScreen.routeName),
                ],
                if (role == UserRole.pemilik) ...[
                  _item(context, Icons.account_balance_wallet, 'Buku Kas Umum',
                      BukuKasScreen.routeName),
                  _item(context, Icons.receipt_long, 'Operasional',
                      OperasionalScreen.routeName),
                ],
                _item(context, Icons.table_chart, 'Laporan Pembagian Hasil',
                    LaporanScreen.routeName),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.mint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading:
            Icon(icon, color: selected ? AppColors.tealDark : AppColors.teal),
        title: Text(title),
        onTap: () => Navigator.pushReplacementNamed(context, route),
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
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.teal, width: 1.5),
      ),
      child: const Icon(Icons.content_cut, color: AppColors.tealDark, size: 28),
    );
  }
}
