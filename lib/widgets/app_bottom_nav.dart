import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  int _currentIndex(List<NavItem> items) {
    final index = items.indexWhere((item) => item.route == currentRoute);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService().currentUser(),
      builder: (context, snapshot) {
        final role = snapshot.data?.role ?? UserRole.admin;
        final items = NavigationHelper.itemsForRole(role);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: NavigationBar(
                height: 66,
                selectedIndex: _currentIndex(items),
                backgroundColor: AppColors.paper,
                indicatorColor: AppColors.mint,
                elevation: 0,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
