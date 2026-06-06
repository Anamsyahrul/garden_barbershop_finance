import 'package:flutter/material.dart';

import '../screens/buku_kas_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/laporan_screen.dart';
import '../screens/operasional_screen.dart';
import '../screens/pendapatan_harian_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  int _currentIndex(List<_NavItem> items) {
    final index = items.indexWhere((item) => item.route == currentRoute);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService().currentUser(),
      builder: (context, snapshot) {
        final role = snapshot.data?.role ?? UserRole.admin;
        final items = _itemsForRole(role);
        return NavigationBar(
          height: 64,
          selectedIndex: _currentIndex(items),
          backgroundColor: AppColors.paper,
          indicatorColor: AppColors.mint,
          elevation: 3,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            final route = items[index].route;
            if (route == currentRoute) return;
            Navigator.pushReplacementNamed(context, route);
          },
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        );
      },
    );
  }

  List<_NavItem> _itemsForRole(UserRole role) {
    final home = _NavItem(
      route: DashboardScreen.routeName,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Home',
    );
    final laporan = _NavItem(
      route: LaporanScreen.routeName,
      icon: Icons.table_chart_outlined,
      selectedIcon: Icons.table_chart,
      label: 'Laporan',
    );
    if (role == UserRole.capster) {
      return [home, laporan];
    }
    if (role == UserRole.adminHarian) {
      return [
        home,
        _NavItem(
          route: PendapatanHarianScreen.routeName,
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments,
          label: 'Input',
        ),
        laporan,
      ];
    }
    if (role == UserRole.pemilik) {
      return [
        home,
        _NavItem(
          route: BukuKasScreen.routeName,
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          label: 'Kas',
        ),
        _NavItem(
          route: OperasionalScreen.routeName,
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Ops',
        ),
        laporan,
      ];
    }
    return [
      home,
      _NavItem(
        route: PendapatanHarianScreen.routeName,
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        label: 'Input',
      ),
      _NavItem(
        route: BukuKasScreen.routeName,
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: 'Kas',
      ),
      _NavItem(
        route: OperasionalScreen.routeName,
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Ops',
      ),
      laporan,
    ];
  }
}

class _NavItem {
  const _NavItem({
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
