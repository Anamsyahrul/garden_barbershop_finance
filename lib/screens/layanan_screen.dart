import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/layanan_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/rupiah_input_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  static const routeName = '/layanan';

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> {
  late Future<List<LayananModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance.getLayanan();
  }

  void _refresh() {
    setState(() {
      _future = FirebaseService.instance.getLayanan();
    });
  }

  Future<void> _showForm({LayananModel? data}) async {
    final pageContext = context;
    final formKey = GlobalKey<FormState>();
    final kode = TextEditingController(text: data?.kodeLayanan ?? '');
    final nama = TextEditingController(text: data?.namaLayanan ?? '');
    final harga = TextEditingController(
      text: data == null ? '' : CurrencyFormatter.format(data.harga),
    );
    final kategori = TextEditingController(text: data?.kategori ?? '');
    var status = data?.status ?? 'aktif';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(data == null ? 'Tambah Layanan' : 'Ubah Layanan'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: kode,
                    label: 'Kode Layanan',
                    validator: (value) =>
                        Validators.required(value, 'Kode layanan'),
                  ),
                  CustomTextField(
                    controller: nama,
                    label: 'Nama Layanan',
                    validator: (value) =>
                        Validators.required(value, 'Nama layanan'),
                  ),
                  CustomTextField(
                    controller: harga,
                    label: 'Harga',
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    validator: (value) => Validators.number(value, 'Harga'),
                  ),
                  CustomTextField(controller: kategori, label: 'Kategori'),
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
                  final model = LayananModel(
                    idLayanan:
                        data?.idLayanan ?? 'L${Uuid().v4().substring(0, 8)}',
                    kodeLayanan: kode.text.trim().toUpperCase(),
                    namaLayanan: nama.text.trim(),
                    harga: CurrencyFormatter.parse(harga.text),
                    kategori: kategori.text.trim(),
                    status: status,
                  );
                  if (data == null) {
                    await FirebaseService.instance.saveLayanan(model);
                  } else {
                    await FirebaseService.instance.updateLayanan(model);
                  }
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                        content: Text('Data layanan berhasil disimpan')),
                  );
                  _refresh();
                } catch (error) {
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan layanan: $error')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    kode.dispose();
    nama.dispose();
    harga.dispose();
    kategori.dispose();
  }

  Future<void> _nonaktifkan(LayananModel data) async {
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance
          .updateLayanan(data.copyWith(status: 'nonaktif'));
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan berhasil dinonaktifkan')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menonaktifkan layanan: $error')),
      );
    }
  }

  Future<void> _hapus(LayananModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Layanan',
      message:
          'Layanan ${data.namaLayanan} akan dihapus dari Cloud Firestore. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteLayanan(data.idLayanan);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan berhasil dihapus')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus layanan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Layanan')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: FutureBuilder<List<LayananModel>>(
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
                  title: 'Data Layanan',
                  subtitle:
                      'Kelola jenis layanan, tarif, kategori, dan status layanan.',
                  icon: Icons.design_services_outlined,
                );
              }
              if (data.isEmpty) {
                return const EmptyState(message: 'Belum ada data layanan');
              }
              final item = data[index - 1];
              return _layananCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _layananCard(LayananModel item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.kodeLayanan,
                style: const TextStyle(
                  color: AppColors.brass,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaLayanan,
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${CurrencyFormatter.format(item.harga)} • ${item.kategori.isEmpty ? 'Tanpa kategori' : item.kategori}',
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
