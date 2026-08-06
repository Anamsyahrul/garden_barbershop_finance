import 'package:flutter/material.dart';

import '../screens/buku_kas_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/laporan_screen.dart';
import '../screens/operasional_screen.dart';
import '../screens/pendapatan_harian_screen.dart';
import '../services/auth_service.dart';

class NavItem {
  const NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class NavigationHelper {
  static List<NavItem> itemsForRole(UserRole role) {
    final home = const NavItem(
      route: DashboardScreen.routeName,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Home',
    );
    final laporan = const NavItem(
      route: LaporanScreen.routeName,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Laporan',
    );
    if (role == UserRole.capster) {
      return [home, laporan];
    }
    if (role == UserRole.adminHarian) {
      return [
        home,
        const NavItem(
          route: PendapatanHarianScreen.routeName,
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          label: 'Input',
        ),
        laporan,
      ];
    }
    if (role == UserRole.pemilik) {
      return [
        home,
        const NavItem(
          route: BukuKasScreen.routeName,
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
          label: 'Kas',
        ),
        const NavItem(
          route: OperasionalScreen.routeName,
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          label: 'Ops',
        ),
        laporan,
      ];
    }
    return [
      home,
      const NavItem(
        route: PendapatanHarianScreen.routeName,
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
        label: 'Input',
      ),
      const NavItem(
        route: BukuKasScreen.routeName,
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        label: 'Kas',
      ),
      const NavItem(
        route: OperasionalScreen.routeName,
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'Ops',
      ),
      laporan,
    ];
  }
}
