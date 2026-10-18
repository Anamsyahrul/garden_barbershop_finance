import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/produk_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/rupiah_input_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class InventarisScreen extends StatefulWidget {
  const InventarisScreen({super.key});

  static const routeName = '/inventaris';

  @override
  State<InventarisScreen> createState() => _InventarisScreenState();
}

class _InventarisScreenState extends State<InventarisScreen> {
  late Future<List<ProdukModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance.getProduk();
  }

  void _refresh() {
    setState(() {
      _future = FirebaseService.instance.getProduk();
    });
  }

  Future<void> _showForm({ProdukModel? data}) async {
    final pageContext = context;
    final formKey = GlobalKey<FormState>();
    final nama = TextEditingController(text: data?.namaProduk ?? '');
    final hargaBeli = TextEditingController(
        text: data != null ? CurrencyFormatter.format(data.hargaBeli) : '');
    final hargaJual = TextEditingController(
        text: data != null ? CurrencyFormatter.format(data.hargaJual) : '');
    final stok = TextEditingController(text: data?.stok.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(data == null ? 'Tambah Produk' : 'Ubah Produk'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nama,
                    label: 'Nama Produk (Pomade, dll)',
                    validator: (value) =>
                        Validators.required(value, 'Nama produk'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: hargaBeli,
                    label: 'Harga Modal / Beli',
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    validator: (value) =>
                        Validators.required(value, 'Harga Modal'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: hargaJual,
                    label: 'Harga Jual',
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    validator: (value) =>
                        Validators.required(value, 'Harga Jual'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: stok,
                    label: 'Jumlah Stok Awal',
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.required(value, 'Stok'),
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
                  final model = ProdukModel(
                    idProduk: data?.idProduk ??
                        'PRD-${const Uuid().v4().substring(0, 8)}',
                    namaProduk: nama.text.trim(),
                    hargaBeli: CurrencyFormatter.parse(hargaBeli.text),
                    hargaJual: CurrencyFormatter.parse(hargaJual.text),
                    stok: int.tryParse(stok.text) ?? 0,
                  );
                  await FirebaseService.instance.saveProduk(model);
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(content: Text('Produk berhasil disimpan')),
                  );
                  _refresh();
                } catch (error) {
                  if (!mounted) return;
                  LoadingDialog.hide(pageContext);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan: $error')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapus(ProdukModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Produk',
      message: 'Anda yakin ingin menghapus "${data.namaProduk}"?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteProduk(data);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk dihapus')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: InventarisScreen.routeName,
      appBar: AppBar(title: const Text('Inventaris / Produk')),
      body: FutureBuilder<List<ProdukModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }

          final list = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.isEmpty ? 1 : list.length,
            itemBuilder: (context, index) {
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Belum ada data produk', style: TextStyle(fontSize: 16)),
                  ),
                );
              }

              final item = list[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(item.namaProduk, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Stok: ${item.stok} | Harga Jual: ${CurrencyFormatter.format(item.hargaJual)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showForm(data: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _hapus(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
