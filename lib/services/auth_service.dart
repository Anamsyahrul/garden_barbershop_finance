import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';
import 'firebase_service.dart';

export '../models/user_role.dart';

class AppUser {
  const AppUser({
    required this.username,
    required this.name,
    required this.role,
    required this.idCapster,
  });

  final String username;
  final String name;
  final UserRole role;
  final String idCapster;
}

class AuthService {
  static const _keyLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';
  static const _keyName = 'name';
  static const _keyRole = 'role';
  static const _keyIdCapster = 'id_capster';

  static const _users = {
    'admin': _Credential(
      password: 'admin123',
      name: 'Admin Garden',
      role: UserRole.admin,
    ),
    'diva': _Credential(
      password: 'capster123',
      name: 'Muhamad Diva Syarri',
      role: UserRole.capster,
      idCapster: 'C001',
    ),
    'senior': _Credential(
      password: 'senior123',
      name: 'Capster Senior',
      role: UserRole.adminHarian,
      idCapster: 'C002',
    ),
    'pemilik': _Credential(
      password: 'pemilik123',
      name: 'Pemilik Pondok',
      role: UserRole.pemilik,
    ),
  };

  Future<bool> login(String username, String password) async {
    final normalizedUsername = username.trim().toLowerCase();
    final firebaseUser = await FirebaseService.instance
        .findUserByUsername(normalizedUsername);
    if (firebaseUser != null) {
      if (firebaseUser.password != password) return false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyUsername, normalizedUsername);
      await prefs.setString(_keyName, firebaseUser.name);
      await prefs.setString(_keyRole, firebaseUser.role.name);
      await prefs.setString(_keyIdCapster, firebaseUser.idCapster);
      return true;
    }

    final user = _users[normalizedUsername];
    if (user == null || user.password != password) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUsername, normalizedUsername);
    await prefs.setString(_keyName, user.name);
    await prefs.setString(_keyRole, user.role.name);
    await prefs.setString(_keyIdCapster, user.idCapster);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyIdCapster);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (!loggedIn) return null;
    final username = prefs.getString(_keyUsername) ?? '';
    final name = prefs.getString(_keyName) ?? '';
    final idCapster = prefs.getString(_keyIdCapster) ?? '';
    final roleName = prefs.getString(_keyRole) ?? UserRole.admin.name;
    final role = UserRole.values.firstWhere(
      (item) => item.name == roleName,
      orElse: () => UserRole.admin,
    );
    return AppUser(
        username: username, name: name, role: role, idCapster: idCapster);
  }
}

class _Credential {
  const _Credential({
    required this.password,
    required this.name,
    required this.role,
    this.idCapster = '',
  });

  final String password;
  final String name;
  final UserRole role;
  final String idCapster;
}
