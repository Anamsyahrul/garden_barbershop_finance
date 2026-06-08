import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/buku_kas_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/rupiah_input_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class BukuKasScreen extends StatefulWidget {
  const BukuKasScreen({super.key});

  static const routeName = '/buku-kas';

  @override
  State<BukuKasScreen> createState() => _BukuKasScreenState();
}

class _BukuKasScreenState extends State<BukuKasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tanggal =
      TextEditingController(text: DateFormatter.formatDate(DateTime.now()));
  final _uraian = TextEditingController();
  final _penerimaan = TextEditingController();
  final _pengeluaran = TextEditingController();
  final _keterangan = TextEditingController();
  late Future<List<BukuKasModel>> _future;
  var _akun = akunBukuKas.first;
  var _saldoPreview = 0;

  static const akunBukuKas = [
    'Pendapatan Usaha',
    'Pendapatan Lainnya',
    'Harga Pokok Penjualan',
    'Gaji Karyawan',
    'Listrik',
    'Sewa Toko',
    'Wifi',
    'Kebersihan',
    'Air',
    'Cukur Gratis Member',
  ];

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance.getBukuKas();
    _updateSaldoPreview();
  }

  @override
  void dispose() {
    _tanggal.dispose();
    _uraian.dispose();
    _penerimaan.dispose();
    _pengeluaran.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = FirebaseService.instance.getBukuKas();
    });
  }

  Future<void> _updateSaldoPreview() async {
    final lastSaldo = await FirebaseService.instance.getLastSaldo();
    final saldo = lastSaldo +
        CurrencyFormatter.parse(_penerimaan.text) -
        CurrencyFormatter.parse(_pengeluaran.text);
    if (mounted) setState(() => _saldoPreview = saldo);
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (picked != null) _tanggal.text = DateFormatter.formatDate(picked);
  }

  void _clearForm() {
    _uraian.clear();
    _penerimaan.clear();
    _pengeluaran.clear();
    _keterangan.clear();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final penerimaan = CurrencyFormatter.parse(_penerimaan.text);
    final pengeluaran = CurrencyFormatter.parse(_pengeluaran.text);
    if (penerimaan > 0 && pengeluaran > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Isi salah satu: penerimaan atau pengeluaran')),
      );
      return;
    }
    LoadingDialog.show(context);
    try {
      final lastSaldo = await FirebaseService.instance.getLastSaldo();
      final saldo = lastSaldo + penerimaan - pengeluaran;
      final model = BukuKasModel(
        idKas: 'K${Uuid().v4().substring(0, 8)}',
        tanggal: _tanggal.text,
        uraian: _uraian.text.trim(),
        akun: _akun,
        penerimaan: penerimaan,
        pengeluaran: pengeluaran,
        saldo: saldo,
        keterangan: _keterangan.text.trim(),
      );
      await FirebaseService.instance.saveBukuKas(model);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku kas umum berhasil disimpan')),
      );
      _clearForm();
      await _updateSaldoPreview();
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan buku kas: $error')),
      );
    }
  }

  Future<void> _hapus(BukuKasModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Buku Kas',
      message:
          'Transaksi "${data.uraian}" akan dihapus dari Cloud Firestore. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteBukuKas(data.idKas);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data buku kas berhasil dihapus')),
      );
      await _updateSaldoPreview();
      _refresh();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus buku kas: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Kas Umum')),
      drawer: const AppDrawer(),
      bottomNavigationBar:
          const AppBottomNav(currentRoute: BukuKasScreen.routeName),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            const AppPageHeader(
              title: 'Buku Kas Umum',
              subtitle:
                  'Catat penerimaan, pengeluaran, akun, dan saldo kas Garden Barbershop.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'Input Transaksi Kas',
              subtitle:
                  'Akun Pendapatan Usaha berasal dari bagian pondok pada laporan pembagian hasil.',
              icon: Icons.edit_note_outlined,
              children: [
                TextFormField(
                  controller: _tanggal,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pilihTanggal,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _uraian,
                  label: 'Uraian',
                  validator: (value) => Validators.required(value, 'Uraian'),
                ),
                DropdownButtonFormField<String>(
                  value: _akun,
                  decoration: const InputDecoration(
                    labelText: 'Akun',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: akunBukuKas
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _akun = value ?? akunBukuKas.first),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _penerimaan,
                  label: 'Penerimaan',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  onChanged: (_) => _updateSaldoPreview(),
                  validator: (value) =>
                      Validators.number(value, 'Penerimaan', required: false),
                ),
                CustomTextField(
                  controller: _pengeluaran,
                  label: 'Pengeluaran',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  onChanged: (_) => _updateSaldoPreview(),
                  validator: (value) =>
                      Validators.number(value, 'Pengeluaran', required: false),
                ),
                CustomTextField(controller: _keterangan, label: 'Keterangan'),
                _saldoPreviewCard(),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Buku Kas'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'Riwayat Buku Kas',
              subtitle:
                  'Data yang sudah tersimpan dapat dihapus jika terjadi salah input.',
              icon: Icons.history_outlined,
              children: [
                FutureBuilder<List<BukuKasModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const EmptyState(
                          message: 'Belum ada riwayat buku kas');
                    }
                    return Column(
                      children: [
                        for (var i = data.length - 1; i >= 0; i--) ...[
                          _kasCard(data[i]),
                          if (i > 0) const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _saldoPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.savings_outlined, color: AppColors.teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Perkiraan Saldo Setelah Transaksi',
                  style: TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  CurrencyFormatter.format(_saldoPreview),
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Perbarui saldo',
                icon: const Icon(Icons.refresh),
                onPressed: _updateSaldoPreview,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kasCard(BukuKasModel item) {
    final isPenerimaan = item.penerimaan > 0;
    final nominal = isPenerimaan ? item.penerimaan : item.pengeluaran;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPenerimaan
                  ? AppColors.teal.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPenerimaan ? Icons.south_west : Icons.north_east,
              color: isPenerimaan ? AppColors.teal : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.uraian,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.tanggal} • ${item.akun}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  CurrencyFormatter.format(nominal),
                  style: TextStyle(
                    color:
                        isPenerimaan ? AppColors.tealDark : Colors.red.shade700,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _hapus(item),
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}
