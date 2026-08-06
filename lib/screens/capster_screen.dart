import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/capster_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class CapsterScreen extends StatefulWidget {
  const CapsterScreen({super.key});

  static const routeName = '/capster';

  @override
  State<CapsterScreen> createState() => _CapsterScreenState();
}

class _CapsterScreenState extends State<CapsterScreen> {
  late Future<List<CapsterModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance.getCapsters();
  }

  void _refresh() {
    setState(() {
      _future = FirebaseService.instance.getCapsters();
    });
  }

  Future<void> _showForm({CapsterModel? data}) async {
    final pageContext = context;
    final formKey = GlobalKey<FormState>();
    final nama = TextEditingController(text: data?.namaCapster ?? '');
    final noHp = TextEditingController(text: data?.noHp ?? '');
    var status = data?.status ?? 'aktif';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(data == null ? 'Tambah Capster' : 'Ubah Capster'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nama,
                    label: 'Nama Capster',
                    validator: (value) =>
                        Validators.required(value, 'Nama capster'),
                  ),
                  CustomTextField(controller: noHp, label: 'No. HP'),
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
                child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext);
                LoadingDialog.show(pageContext);
                try {
                  final model = CapsterModel(
                    idCapster:
                        data?.idCapster ?? 'C${Uuid().v4().substring(0, 8)}',
                    namaCapster: nama.text.trim(),
                    noHp: noHp.text.trim(),
                    status: status,
                  );
                  if (data == null) {
                    await FirebaseService.instance.saveCapster(model);
                  } else {
                    await FirebaseService.instance.updateCapster(model);
                  }
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                        content: Text('Data capster berhasil disimpan')),
                  );
                  _refresh();
                } catch (error) {
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan capster: $error')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    nama.dispose();
    noHp.dispose();
  }

  Future<void> _nonaktifkan(CapsterModel data) async {
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance
          .updateCapster(data.copyWith(status: 'nonaktif'));
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capster berhasil dinonaktifkan')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menonaktifkan capster: $error')),
      );
    }
  }

  Future<void> _hapus(CapsterModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Capster',
      message:
          'Data ${data.namaCapster} akan dihapus dari Cloud Firestore. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteCapster(data.idCapster);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capster berhasil dihapus')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus capster: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: CapsterScreen.routeName,
      appBar: AppBar(title: const Text('Data Capster')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: FutureBuilder<List<CapsterModel>>(
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
                  title: 'Data Capster',
                  subtitle:
                      'Kelola capster aktif dan nonaktif untuk perhitungan pembagian hasil.',
                  icon: Icons.people_alt_outlined,
                );
              }
              if (data.isEmpty) {
                return const EmptyState(message: 'Belum ada data capster');
              }
              final item = data[index - 1];
              return _capsterCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _capsterCard(CapsterModel item) {
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
              child: const Icon(Icons.content_cut, color: AppColors.brass),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaCapster,
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.noHp.isEmpty ? 'No. HP belum diisi' : item.noHp,
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
}
