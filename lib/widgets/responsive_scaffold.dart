import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'app_bottom_nav.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.currentRoute,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.extendBody = false,
  });

  final String currentRoute;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop/Tablet layout
          return Scaffold(
            appBar: appBar,
            extendBody: extendBody,
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                _SideNavigation(currentRoute: currentRoute),
                Expanded(
                  child: body,
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          appBar: appBar,
          extendBody: extendBody,
          drawer: const AppDrawer(),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: AppBottomNav(currentRoute: currentRoute),
          body: body,
        );
      },
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService().currentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final role = user?.role ?? UserRole.admin;
        final items = NavigationHelper.itemsForRole(role);

        return Container(
          width: 260,
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border(right: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  children: [
                    _BrandMark(size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Garden Barbershop',
                      style: TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user == null ? 'Finance Control' : '${user.name} • ${role.label}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...items.map((item) => _item(context, item)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _logoutItem(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(BuildContext context, NavItem item) {
    final selected = item.route == currentRoute;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.mint,
        tileColor: selected ? AppColors.mint : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          selected ? item.selectedIcon : item.icon,
          color: selected ? AppColors.tealDark : AppColors.charcoalSoft,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? AppColors.tealDark : AppColors.charcoalSoft,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (!selected) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
      ),
    );
  }

  Widget _logoutItem(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
      ),
      title: const Text(
        'Keluar',
        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
      ),
      onTap: () async {
        await AuthService().logout();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
