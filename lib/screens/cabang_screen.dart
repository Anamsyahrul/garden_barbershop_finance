import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/cabang_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class CabangScreen extends StatefulWidget {
  const CabangScreen({super.key});

  static const routeName = '/cabang';

  @override
  State<CabangScreen> createState() => _CabangScreenState();
}

class _CabangScreenState extends State<CabangScreen> {
  late Future<List<CabangModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance.getSemuaCabang();
  }

  void _refresh() {
    setState(() {
      _future = FirebaseService.instance.getSemuaCabang();
    });
  }

  Future<void> _showForm({CabangModel? data}) async {
    final pageContext = context;
    final formKey = GlobalKey<FormState>();
    final nama = TextEditingController(text: data?.namaCabang ?? '');
    final alamat = TextEditingController(text: data?.alamat ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(data == null ? 'Tambah Cabang' : 'Ubah Cabang'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nama,
                    label: 'Nama Cabang',
                    validator: (value) =>
                        Validators.required(value, 'Nama cabang'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: alamat,
                    label: 'Alamat',
                    validator: (value) =>
                        Validators.required(value, 'Alamat'),
                    maxLines: 3,
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
                  final model = CabangModel(
                    idCabang:
                        data?.idCabang ?? 'CBG-${const Uuid().v4().substring(0, 8)}',
                    namaCabang: nama.text.trim(),
                    alamat: alamat.text.trim(),
                  );
                  if (data == null) {
                    await FirebaseService.instance.saveCabang(model);
                  } else {
                    await FirebaseService.instance.updateCabang(model);
                  }
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                        content: Text('Data cabang berhasil disimpan')),
                  );
                  _refresh();
                } catch (error) {
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan cabang: $error')),
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
    alamat.dispose();
  }

  Future<void> _hapus(CabangModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Cabang',
      message:
          'Data ${data.namaCabang} akan dihapus dari sistem. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteCabang(data.idCabang);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cabang berhasil dihapus')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus cabang: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: CabangScreen.routeName,
      appBar: AppBar(title: const Text('Data Cabang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: FutureBuilder<List<CabangModel>>(
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
                  title: 'Data Cabang',
                  subtitle:
                      'Kelola daftar cabang barbershop Anda.',
                  icon: Icons.store_rounded,
                );
              }
              if (data.isEmpty) {
                return const EmptyState(message: 'Belum ada data cabang');
              }
              final item = data[index - 1];
              return _cabangCard(item);
            },
          );
        },
      ),
    );
  }

Widget _cabangCard(CabangModel item) {
    final isActive = item.idCabang == FirebaseService.instance.activeCabang;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isActive ? AppColors.teal : Colors.transparent, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!isActive) {
            FirebaseService.instance.setActiveCabang(item.idCabang);
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.teal.withValues(alpha: 0.1) : AppColors.panel,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store, color: isActive ? AppColors.tealDark : AppColors.brass),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaCabang,
                      style: TextStyle(
                        color: isActive ? AppColors.tealDark : AppColors.charcoal,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.alamat,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                TextButton.icon(
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                  label: const Text('Pantau'),
                  onPressed: () {
                    FirebaseService.instance.setActiveCabang(item.idCabang);
                    Navigator.pop(context);
                  },
                ),
              if (isActive)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Sedang dipantau', style: TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _showForm(data: item);
                  if (value == 'hapus') _hapus(item);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
