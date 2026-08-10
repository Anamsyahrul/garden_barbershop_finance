import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/operasional_model.dart';
import '../services/calculation_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/rupiah_input_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class OperasionalScreen extends StatefulWidget {
  const OperasionalScreen({super.key});

  static const routeName = '/operasional';

  @override
  State<OperasionalScreen> createState() => _OperasionalScreenState();
}

class _OperasionalScreenState extends State<OperasionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bulan =
      TextEditingController(text: DateFormatter.formatMonth(DateTime.now()));
  final _namaBiaya = TextEditingController();
  final _nominal = TextEditingController();
  final _keterangan = TextEditingController();
  late Future<List<OperasionalModel>> _future;
  var _akun = 'Listrik';
  var _totalOperasional = 0;

  static const akunOperasional = [
    'Listrik',
    'Wifi',
    'Kebersihan',
    'Air',
    'Sewa Toko',
    'Harga Pokok Penjualan',
  ];

  @override
  void initState() {
    super.initState();
    _future = FirebaseService.instance
        .getOperasionalByMonth(DateFormatter.toStorageMonth(_bulan.text));
    _loadTotal();
  }

  @override
  void dispose() {
    _bulan.dispose();
    _namaBiaya.dispose();
    _nominal.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  void _refreshList() {
    setState(() {
      _future = FirebaseService.instance
          .getOperasionalByMonth(DateFormatter.toStorageMonth(_bulan.text));
    });
  }

  Future<void> _loadTotal() async {
    final data = await FirebaseService.instance
        .getOperasionalByMonth(DateFormatter.toStorageMonth(_bulan.text));
    final total = CalculationService().hitungTotalOperasional(data);
    if (mounted) {
      setState(() {
        _totalOperasional = total;
        _future = Future.value(data);
      });
    }
  }

  Future<void> _pilihBulan() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (picked != null) {
      _bulan.text = DateFormatter.formatMonth(picked);
      await _loadTotal();
    }
  }

  void _clearForm() {
    _namaBiaya.clear();
    _nominal.clear();
    _keterangan.clear();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    LoadingDialog.show(context);
    try {
      final model = OperasionalModel(
        idOperasional: 'O${Uuid().v4().substring(0, 8)}',
        bulan: DateFormatter.toStorageMonth(_bulan.text),
        namaBiaya: _namaBiaya.text.trim(),
        akun: _akun,
        nominal: CurrencyFormatter.parse(_nominal.text),
        keterangan: _keterangan.text.trim(),
      );
      await FirebaseService.instance.saveOperasional(model);
      await FirebaseService.instance.addNotification(
        title: 'Pengeluaran Dicatat',
        message: 'Biaya operasional baru ( ${model.namaBiaya} ) sebesar ${CurrencyFormatter.format(model.nominal)} telah dicatat.',
        type: 'expense',
      );
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biaya operasional berhasil disimpan')),
      );
      _clearForm();
      await _loadTotal();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan operasional: $error')),
      );
    }
  }

  Future<void> _hapus(OperasionalModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Operasional',
      message:
          'Biaya "${data.namaBiaya}" akan dihapus dari Cloud Firestore. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteOperasional(data.idOperasional);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biaya operasional berhasil dihapus')),
      );
      await _loadTotal();
      _refreshList();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus operasional: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: OperasionalScreen.routeName,
      appBar: AppBar(title: const Text('Operasional')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            const AppPageHeader(
              title: 'Biaya Operasional',
              subtitle:
                  'Catat biaya bulanan yang menjadi dasar pembagian beban capster.',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'Input Biaya',
              subtitle: 'Pilih bulan, akun biaya, dan nominal operasional.',
              icon: Icons.add_card_outlined,
              children: [
                TextFormField(
                  controller: _bulan,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Bulan',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: _pilihBulan,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _namaBiaya,
                  label: 'Nama Biaya',
                  validator: (value) =>
                      Validators.required(value, 'Nama biaya'),
                ),
                DropdownButtonFormField<String>(
                  value: _akun,
                  decoration: const InputDecoration(
                    labelText: 'Akun',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: akunOperasional
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _akun = value ?? akunOperasional.first),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _nominal,
                  label: 'Nominal',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  validator: (value) => Validators.number(value, 'Nominal'),
                ),
                CustomTextField(controller: _keterangan, label: 'Keterangan'),
                _totalOperasionalCard(),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Operasional'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title:
                  'Daftar Operasional ${DateFormatter.displayMonth(_bulan.text)}',
              subtitle: 'Hapus biaya jika terjadi kesalahan input.',
              icon: Icons.list_alt_outlined,
              children: [
                FutureBuilder<List<OperasionalModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const EmptyState(
                          message:
                              'Belum ada biaya operasional pada bulan ini');
                    }
                    return Column(
                      children: [
                        for (var i = data.length - 1; i >= 0; i--) ...[
                          _operasionalCard(data[i]),
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

  Widget _totalOperasionalCard() {
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
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Total Operasional ${DateFormatter.displayMonth(_bulan.text)}',
                  style: const TextStyle(
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
                  CurrencyFormatter.format(_totalOperasional),
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Perbarui total',
                icon: const Icon(Icons.refresh),
                onPressed: _loadTotal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _operasionalCard(OperasionalModel item) {
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
              color: AppColors.brass.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.receipt_outlined, color: AppColors.charcoal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBiaya,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormatter.displayMonth(item.bulan)} • ${item.akun}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  CurrencyFormatter.format(item.nominal),
                  style: const TextStyle(
                    color: AppColors.tealDark,
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
