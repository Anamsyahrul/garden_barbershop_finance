import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/capster_model.dart';
import '../models/kasbon_model.dart';
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

class KasbonScreen extends StatefulWidget {
  const KasbonScreen({super.key});

  static const routeName = '/kasbon';

  @override
  State<KasbonScreen> createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tanggal =
      TextEditingController(text: DateFormatter.formatDate(DateTime.now()));
  final _nominal = TextEditingController();
  final _keterangan = TextEditingController();
  
  late Future<List<KasbonModel>> _future;
  List<CapsterModel> _capsters = [];
  String? _selectedCapsterId;
  int _totalKasbon = 0;

  String get _currentMonthKey {
    final dateKey = DateFormatter.toStorageDate(_tanggal.text);
    if (dateKey.length >= 7) return dateKey.substring(0, 7);
    return dateKey;
  }

  @override
  void initState() {
    super.initState();
    _loadCapsters();
    _future = FirebaseService.instance.getKasbonByMonth(_currentMonthKey);
    _loadTotal();
  }

  @override
  void dispose() {
    _tanggal.dispose();
    _nominal.dispose();
    _keterangan.dispose();
    super.dispose();
  }
  
  Future<void> _loadCapsters() async {
    final capsters = await FirebaseService.instance.getCapsterAktif();
    if (mounted) {
      setState(() {
        _capsters = capsters;
        if (_capsters.isNotEmpty) {
          _selectedCapsterId = _capsters.first.idCapster;
        }
      });
    }
  }

  void _refreshList() {
    setState(() {
      _future = FirebaseService.instance.getKasbonByMonth(_currentMonthKey);
    });
  }

  Future<void> _loadTotal() async {
    final data = await FirebaseService.instance.getKasbonByMonth(_currentMonthKey);
    final total = data.fold(0, (sum, item) => sum + item.nominal);
    if (mounted) {
      setState(() {
        _totalKasbon = total;
        _future = Future.value(data);
      });
    }
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
      _tanggal.text = DateFormatter.formatDate(picked);
      await _loadTotal();
    }
  }

  void _clearForm() {
    _nominal.clear();
    _keterangan.clear();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCapsterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih capster terlebih dahulu')),
      );
      return;
    }
    
    final capster = _capsters.firstWhere((c) => c.idCapster == _selectedCapsterId);
    
    LoadingDialog.show(context);
    try {
      final model = KasbonModel(
        idKasbon: 'K${Uuid().v4().substring(0, 8)}',
        tanggal: DateFormatter.toStorageDate(_tanggal.text),
        idCapster: capster.idCapster,
        namaCapster: capster.namaCapster,
        nominal: CurrencyFormatter.parse(_nominal.text),
        keterangan: _keterangan.text.trim(),
      );
      await FirebaseService.instance.saveKasbon(model);
      await FirebaseService.instance.addNotification(
        title: 'Kasbon Dicatat',
        message: 'Kasbon untuk ${model.namaCapster} sebesar ${CurrencyFormatter.format(model.nominal)} telah dicatat.',
        type: 'expense',
      );
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kasbon berhasil disimpan')),
      );
      _clearForm();
      await _loadTotal();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan kasbon: $error')),
      );
    }
  }

  Future<void> _hapus(KasbonModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Kasbon',
      message:
          'Kasbon "${data.namaCapster}" sebesar ${CurrencyFormatter.format(data.nominal)} akan dihapus. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteKasbon(data);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kasbon berhasil dihapus')),
      );
      await _loadTotal();
      _refreshList();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus kasbon: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: KasbonScreen.routeName,
      appBar: AppBar(title: const Text('Kasbon Karyawan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            const AppPageHeader(
              title: 'Kasbon Capster',
              subtitle:
                  'Catat pengambilan uang muka (kasbon) yang akan memotong bagian akhir capster.',
              icon: Icons.money_off_outlined,
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'Input Kasbon',
              subtitle: 'Pilih tanggal, capster, dan nominal.',
              icon: Icons.add_card_outlined,
              children: [
                TextFormField(
                  controller: _tanggal,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: _pilihTanggal,
                ),
                const SizedBox(height: 12),
                if (_capsters.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCapsterId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Capster',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: _capsters
                        .map((c) => DropdownMenuItem(
                            value: c.idCapster, child: Text(c.namaCapster)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCapsterId = value),
                  ),
                if (_capsters.isEmpty)
                   const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text('Tidak ada capster aktif', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _nominal,
                  label: 'Nominal',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  validator: (value) => Validators.number(value, 'Nominal'),
                ),
                CustomTextField(controller: _keterangan, label: 'Keterangan (Opsional)'),
                _totalKasbonCard(),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _capsters.isEmpty ? null : _simpan,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Kasbon'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title:
                  'Riwayat Kasbon Bulan Ini',
              subtitle: 'Hapus data jika terjadi kesalahan input.',
              icon: Icons.list_alt_outlined,
              children: [
                FutureBuilder<List<KasbonModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const EmptyState(
                          message:
                              'Belum ada kasbon pada bulan ini');
                    }
                    return Column(
                      children: [
                        for (var i = data.length - 1; i >= 0; i--) ...[
                          _kasbonCard(data[i]),
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

  Widget _totalKasbonCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Total Kasbon Bulan Ini',
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
                  CurrencyFormatter.format(_totalKasbon),
                  style: const TextStyle(
                    color: AppColors.danger,
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

  Widget _kasbonCard(KasbonModel item) {
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
              color: AppColors.danger.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.money_off_outlined, color: AppColors.danger),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormatter.displayDate(item.tanggal)} • ${item.keterangan}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  CurrencyFormatter.format(item.nominal),
                  style: const TextStyle(
                    color: AppColors.danger,
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
