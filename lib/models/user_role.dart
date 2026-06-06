enum UserRole {
  admin,
  adminHarian,
  capster,
  pemilik,
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.adminHarian:
        return 'Admin Harian';
      case UserRole.capster:
        return 'Capster';
      case UserRole.pemilik:
        return 'Pemilik';
    }
  }
}
