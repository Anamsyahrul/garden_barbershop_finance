import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  final List<UserRole> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService().currentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data!.role;
        if (allowedRoles.contains(role)) return child;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Akses tidak tersedia untuk role ini')),
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
