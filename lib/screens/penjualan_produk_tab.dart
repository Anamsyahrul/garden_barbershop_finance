import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/produk_model.dart';
import '../models/penjualan_produk_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/custom_text_field.dart';

class PenjualanProdukTab extends StatefulWidget {
  const PenjualanProdukTab({super.key});

  @override
  State<PenjualanProdukTab> createState() => _PenjualanProdukTabState();
}

class _PenjualanProdukTabState extends State<PenjualanProdukTab> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalController =
      TextEditingController(text: DateFormatter.formatDate(DateTime.now()));
  final _qtyController = TextEditingController(text: '1');

  ProdukModel? _selectedProduk;
  late Future<List<ProdukModel>> _produkFuture;
  late Future<List<PenjualanProdukModel>> _penjualanFuture;

  @override
  void initState() {
    super.initState();
    _produkFuture = FirebaseService.instance.getProduk();
    _refreshPenjualan();
  }

  void _refreshPenjualan() {
    final date = DateFormatter.toStorageDate(_tanggalController.text);
    _penjualanFuture = FirebaseService.instance.getPenjualanProdukByDate(date);
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormatter.formatDate(picked);
        _refreshPenjualan();
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk yang terjual')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    if (qty > _selectedProduk!.stok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak mencukupi')),
      );
      return;
    }

    LoadingDialog.show(context);
    try {
      final model = PenjualanProdukModel(
        idPenjualan: 'JL${const Uuid().v4().substring(0, 8)}',
        tanggal: DateFormatter.toStorageDate(_tanggalController.text),
        idProduk: _selectedProduk!.idProduk,
        namaProduk: _selectedProduk!.namaProduk,
        qty: qty,
        hargaJual: _selectedProduk!.hargaJual,
        total: qty * _selectedProduk!.hargaJual,
      );
      
      await FirebaseService.instance.savePenjualanProduk(model);
      
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penjualan produk dicatat')),
      );
      
      _qtyController.text = '1';
      setState(() {
        _selectedProduk = null;
        _produkFuture = FirebaseService.instance.getProduk();
        _refreshPenjualan();
      });
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencatat: $e')),
      );
    }
  }

  Future<void> _hapus(PenjualanProdukModel item) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Penjualan',
      message: 'Hapus penjualan ${item.namaProduk} sejumlah ${item.qty}?',
    );
    if (!confirmed) return;
    if (!mounted) return;

    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deletePenjualanProduk(item);
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() {
        _produkFuture = FirebaseService.instance.getProduk();
        _refreshPenjualan();
      });
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<List<ProdukModel>>(
          future: _produkFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final produks = snapshot.data!;
            return Form(
              key: _formKey,
              child: _sectionCard(
                icon: Icons.inventory,
                title: 'Jual Produk',
                subtitle: 'Pilih produk yang terjual di hari tersebut.',
                children: [
                  TextFormField(
                    controller: _tanggalController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Penjualan',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _pilihTanggal,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProdukModel>(
                    value: _selectedProduk,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Produk',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    items: produks
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.namaProduk} (Stok: ${p.stok}) - ${CurrencyFormatter.format(p.hargaJual)}'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedProduk = val);
                    },
                    validator: (val) => val == null ? 'Produk harus dipilih' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _qtyController,
                    label: 'Jumlah (Qty)',
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Isi jumlah' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _simpan,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Penjualan Produk'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _sectionCard(
          icon: Icons.receipt_long,
          title: 'Riwayat Penjualan Produk',
          subtitle: 'Menampilkan penjualan pada tanggal yang dipilih.',
          children: [
            FutureBuilder<List<PenjualanProdukModel>>(
              future: _penjualanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Belum ada penjualan produk', style: TextStyle(color: AppColors.muted))),
                  );
                }
                
                final totalHariIni = items.fold(0, (sum, i) => sum + i.total);

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Terjual', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.format(totalHariIni),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.namaProduk, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item.qty} x ${CurrencyFormatter.format(item.hargaJual)} = ${CurrencyFormatter.format(item.total)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              onPressed: () => _hapus(item),
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
