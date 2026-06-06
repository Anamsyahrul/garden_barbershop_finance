import 'user_role.dart';

class UserModel {
  const UserModel({
    required this.idUser,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    required this.status,
    required this.idCapster,
  });

  final String idUser;
  final String username;
  final String password;
  final String name;
  final UserRole role;
  final String status;
  final String idCapster;

  bool get aktif => status.toLowerCase() == 'aktif';

  factory UserModel.fromRow(List<dynamic> row) {
    return UserModel(
      idUser: row.isNotEmpty ? row[0].toString() : '',
      username: row.length > 1 ? row[1].toString() : '',
      password: row.length > 2 ? row[2].toString() : '',
      name: row.length > 3 ? row[3].toString() : '',
      role: _parseRole(row.length > 4 ? row[4].toString() : ''),
      status: row.length > 5 ? row[5].toString() : 'aktif',
      idCapster: row.length > 6 ? row[6].toString() : '',
    );
  }

  List<dynamic> toRow() => [
        idUser,
        username.toLowerCase(),
        password,
        name,
        role.name,
        status,
        idCapster,
      ];

  UserModel copyWith({
    String? idUser,
    String? username,
    String? password,
    String? name,
    UserRole? role,
    String? status,
    String? idCapster,
  }) {
    return UserModel(
      idUser: idUser ?? this.idUser,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      idCapster: idCapster ?? this.idCapster,
    );
  }

  static UserRole _parseRole(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return UserRole.values.firstWhere(
      (role) =>
          role.name.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '') ==
          normalized,
      orElse: () => UserRole.capster,
    );
  }
}
