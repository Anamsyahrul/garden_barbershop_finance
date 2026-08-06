import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class AkunPenggunaScreen extends StatefulWidget {
  const AkunPenggunaScreen({super.key});

  static const routeName = '/akun-pengguna';

  @override
  State<AkunPenggunaScreen> createState() => _AkunPenggunaScreenState();
}

class _AkunPenggunaScreenState extends State<AkunPenggunaScreen> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance.getUsers();
  }

  void _refresh() {
    setState(() {
      _future = FirebaseService.instance.getUsers();
    });
  }

  Future<void> _showForm({UserModel? data}) async {
    final pageContext = context;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: data?.name ?? '');
    final username = TextEditingController(text: data?.username ?? '');
    final password = TextEditingController(text: data?.password ?? '');
    var role = data?.role ?? UserRole.capster;
    var status = data?.status ?? 'aktif';
    final capsters = await FirebaseService.instance.getCapsterAktif();
    var selectedCapsterId =
        capsters.any((item) => item.idCapster == data?.idCapster)
            ? data?.idCapster
            : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(data == null ? 'Tambah Akun' : 'Ubah Akun'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: name,
                    label: 'Nama Pengguna',
                    validator: (value) =>
                        Validators.required(value, 'Nama pengguna'),
                  ),
                  CustomTextField(
                    controller: username,
                    label: 'Username',
                    validator: (value) =>
                        Validators.required(value, 'Username'),
                  ),
                  CustomTextField(
                    controller: password,
                    label: 'Password',
                    validator: (value) =>
                        Validators.required(value, 'Password'),
                  ),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                          value: UserRole.admin, child: Text('Admin')),
                      DropdownMenuItem(
                          value: UserRole.adminHarian,
                          child: Text('Admin Harian')),
                      DropdownMenuItem(
                          value: UserRole.capster, child: Text('Capster')),
                      DropdownMenuItem(
                          value: UserRole.pemilik, child: Text('Pemilik')),
                    ],
                    onChanged: (value) => setDialogState(() {
                      role = value ?? UserRole.capster;
                      if (role != UserRole.capster &&
                          role != UserRole.adminHarian) {
                        selectedCapsterId = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (role == UserRole.capster ||
                      role == UserRole.adminHarian) ...[
                    DropdownButtonFormField<String>(
                      value: selectedCapsterId,
                      decoration: const InputDecoration(
                        labelText: 'Nama Capster',
                        prefixIcon: Icon(Icons.content_cut),
                      ),
                      items: capsters
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.idCapster,
                              child: Text(item.namaCapster),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedCapsterId = value),
                      validator: (value) => (role == UserRole.capster ||
                                  role == UserRole.adminHarian) &&
                              value == null
                          ? 'Nama capster wajib dipilih'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                          value: 'nonaktif', child: Text('Nonaktif')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => status = value ?? 'aktif'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final normalizedUsername = username.text.trim().toLowerCase();
                final existingUsers = await FirebaseService.instance.getUsers();
                final usernameUsed = existingUsers.any(
                  (item) =>
                      item.username.toLowerCase() == normalizedUsername &&
                      item.idUser != data?.idUser,
                );
                if (usernameUsed) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Username sudah digunakan')),
                  );
                  return;
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                LoadingDialog.show(pageContext);
                try {
                  final model = UserModel(
                    idUser: data?.idUser ?? 'U${Uuid().v4().substring(0, 8)}',
                    username: normalizedUsername,
                    password: password.text.trim(),
                    name: name.text.trim(),
                    role: role,
                    status: status,
                    idCapster:
                        role == UserRole.capster || role == UserRole.adminHarian
                            ? selectedCapsterId ?? ''
                            : '',
                  );
                  if (data == null) {
                    await FirebaseService.instance.saveUser(model);
                  } else {
                    await FirebaseService.instance.updateUser(model);
                  }
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                        content: Text('Akun pengguna berhasil disimpan')),
                  );
                  _refresh();
                } catch (error) {
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan akun: $error')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    username.dispose();
    password.dispose();
  }

  Future<void> _nonaktifkan(UserModel data) async {
    if (_isPrimaryAdmin(data)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun admin utama tidak dapat dinonaktifkan'),
        ),
      );
      return;
    }
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance
          .updateUser(data.copyWith(status: 'nonaktif'));
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dinonaktifkan')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menonaktifkan akun: $error')),
      );
    }
  }

  Future<void> _hapus(UserModel data) async {
    if (_isPrimaryAdmin(data)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun admin utama tidak dapat dihapus')),
      );
      return;
    }
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Akun',
      message:
          'Akun ${data.username} akan dihapus dari Cloud Firestore. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteUser(data.idUser);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dihapus')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus akun: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: AkunPenggunaScreen.routeName,
      appBar: AppBar(title: const Text('Akun Pengguna')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.isEmpty ? 2 : data.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const AppPageHeader(
                  title: 'Akun Pengguna',
                  subtitle:
                      'Admin dapat membuat akun admin harian, capster, dan pemilik.',
                  icon: Icons.manage_accounts_outlined,
                );
              }
              if (data.isEmpty) {
                return const EmptyState(message: 'Belum ada akun pengguna');
              }
              return _userCard(data[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _userCard(UserModel item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.role == UserRole.pemilik
                    ? Icons.storefront
                    : item.role == UserRole.admin
                        ? Icons.admin_panel_settings
                        : item.role == UserRole.adminHarian
                            ? Icons.verified_user
                            : Icons.content_cut,
                color: AppColors.brass,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _subtitle(item),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  StatusChip(label: item.status, active: item.aktif),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showForm(data: item);
                if (value == 'nonaktif') _nonaktifkan(item);
                if (value == 'hapus') _hapus(item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Ubah')),
                PopupMenuItem(value: 'nonaktif', child: Text('Nonaktifkan')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'hapus', child: Text('Hapus')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(UserModel item) {
    final capsterText =
        (item.role == UserRole.capster || item.role == UserRole.adminHarian) &&
                item.idCapster.isNotEmpty
            ? ' • ${item.idCapster}'
            : '';
    return '${item.username} • ${item.role.label}$capsterText';
  }

  bool _isPrimaryAdmin(UserModel data) {
    return data.role == UserRole.admin &&
        data.username.toLowerCase() == 'admin';
  }
}
