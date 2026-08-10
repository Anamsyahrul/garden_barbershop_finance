import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/buku_kas_screen.dart';
import 'screens/akun_pengguna_screen.dart';
import 'screens/capster_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/layanan_screen.dart';
import 'screens/login_screen.dart';
import 'screens/operasional_screen.dart';
import 'screens/pendapatan_harian_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/neraca_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/role_guard.dart';

class GardenFinanceApp extends StatelessWidget {
  const GardenFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Garden Barbershop Finance',
      theme: AppTheme.light(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        AkunPenggunaScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin],
              child: AkunPenggunaScreen(),
            ),
        CapsterScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin],
              child: CapsterScreen(),
            ),
        LayananScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin],
              child: LayananScreen(),
            ),
        PendapatanHarianScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin, UserRole.adminHarian],
              child: PendapatanHarianScreen(),
            ),
        BukuKasScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin, UserRole.pemilik],
              child: BukuKasScreen(),
            ),
        OperasionalScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin, UserRole.pemilik],
              child: OperasionalScreen(),
            ),
        LaporanScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [
                UserRole.admin,
                UserRole.adminHarian,
                UserRole.capster,
                UserRole.pemilik
              ],
              child: LaporanScreen(),
            ),
        NeracaScreen.routeName: (_) => const RoleGuard(
              allowedRoles: [UserRole.admin, UserRole.pemilik],
              child: NeracaScreen(),
            ),
        NotificationScreen.routeName: (_) => const NotificationScreen(),
      },
    );
  }
}
