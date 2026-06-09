import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/capster_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../services/calculation_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/loading_dialog.dart';

class PendapatanHarianScreen extends StatefulWidget {
  const PendapatanHarianScreen({super.key});

  static const routeName = '/pendapatan-harian';

  @override
  State<PendapatanHarianScreen> createState() => _PendapatanHarianScreenState();
}

class _PendapatanHarianScreenState extends State<PendapatanHarianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalController =
      TextEditingController(text: DateFormatter.formatDate(DateTime.now()));
  final _csController = TextEditingController();
  final _cuController = TextEditingController();
  final _controllers = {
    for (final kode in PendapatanHarianModel.kodeLayanan)
      kode: TextEditingController(),
  };
  CapsterModel? _selectedCapster;
  int _totalPendapatan = 0;
  late Future<List<CapsterModel>> _capsterFuture;
  late Future<List<PendapatanHarianModel>> _pendapatanFuture;

  static const _namaLayanan = {
    'SN': 'Santri',
    'RC': 'Reguler Haircut',
    'PC': 'Premium Cut',
    'GC': 'Garden Cut',
    'CJ': 'Cukur Jenggot/Kumis',
    'KR': 'Keramas',
    'CH': 'Coloring Hair',
    'HS': 'Home Service',
    'PR': 'Perming',
    'KM': 'Kartu Member / Cukur Gratis Member',
  };

  @override
  void initState() {
    super.initState();
    _capsterFuture = FirebaseService.instance.getCapsterAktif();
    _pendapatanFuture = FirebaseService.instance.getPendapatanHarian();
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _csController.dispose();
    _cuController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _parseNumber(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  String _formatCount(int value) => value == 0 ? '' : value.toString();

  int get _customerSantri => _parseNumber(_controllers['SN']?.text ?? '0');

  int get _customerUmum {
    return _controllers.entries
        .where((entry) => entry.key != 'SN')
        .fold(0, (total, entry) => total + _parseNumber(entry.value.text));
  }

  int get _totalCustomer => _customerSantri + _customerUmum;

  int get _totalItemLayanan {
    return _controllers.values
        .fold(0, (total, controller) => total + _parseNumber(controller.text));
  }

  Map<String, int> _jumlahLayanan() {
    return {
      for (final entry in _controllers.entries)
        entry.key: _parseNumber(entry.value.text),
    };
  }

  void _syncCustomerControllers() {
    final cs = _formatCount(_customerSantri);
    final cu = _formatCount(_customerUmum);
    if (_csController.text != cs) {
      _csController.text = cs;
    }
    if (_cuController.text != cu) {
      _cuController.text = cu;
    }
  }

  void _refreshPendapatan() {
    setState(() {
      _pendapatanFuture = FirebaseService.instance.getPendapatanHarian();
    });
  }

  void _clearForm() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _csController.clear();
    _cuController.clear();
    setState(() => _totalPendapatan = 0);
  }

  Future<int> _calculateTotal() async {
    final layanan = await FirebaseService.instance.getLayananAktif();
    return CalculationService()
        .hitungPendapatanHarian(_jumlahLayanan(), layanan);
  }

  Future<void> _hitungTotal() async {
    try {
      final total = await _calculateTotal();
      if (!mounted) return;
      setState(() => _totalPendapatan = total);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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
      _tanggalController.text = DateFormatter.formatDate(picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCapster == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capster wajib dipilih')),
      );
      return;
    }
    LoadingDialog.show(context);
    try {
      final totalPendapatan = await _calculateTotal();
      setState(() => _totalPendapatan = totalPendapatan);
      _syncCustomerControllers();
      final cs = _customerSantri;
      final cu = _customerUmum;
      final model = PendapatanHarianModel(
        idPendapatan: 'P${Uuid().v4().substring(0, 8)}',
        tanggal: DateFormatter.toStorageDate(_tanggalController.text),
        idCapster: _selectedCapster!.idCapster,
        namaCapster: _selectedCapster!.namaCapster,
        jumlahLayanan: _jumlahLayanan(),
        pendapatan: totalPendapatan,
        cs: cs,
        cu: cu,
        totalCustomer: cs + cu,
      );
      await FirebaseService.instance.savePendapatanHarian(model);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendapatan harian berhasil disimpan')),
      );
      _clearForm();
      _refreshPendapatan();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pendapatan: $error')),
      );
    }
  }

  Future<void> _hapus(PendapatanHarianModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Pendapatan Harian',
      message:
          'Transaksi ${data.namaCapster} tanggal ${DateFormatter.displayDate(data.tanggal)} akan dihapus. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deletePendapatanHarian(data);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendapatan harian berhasil dihapus')),
      );
      _refreshPendapatan();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pendapatan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendapatan Harian')),
      drawer: const AppDrawer(),
      bottomNavigationBar:
          const AppBottomNav(currentRoute: PendapatanHarianScreen.routeName),
      body: FutureBuilder<List<CapsterModel>>(
        future: _capsterFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final capsters = snapshot.data!;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              children: [
                _header(),
                const SizedBox(height: 16),
                _sectionCard(
                  icon: Icons.event_note,
                  title: 'Data Transaksi',
                  subtitle:
                      'Pilih tanggal transaksi dan capster yang melayani.',
                  children: [
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Transaksi',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _pilihTanggal,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CapsterModel>(
                      value: _selectedCapster,
                      decoration: const InputDecoration(
                        labelText: 'Nama Capster',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: capsters
                          .map((item) => DropdownMenuItem(
                              value: item, child: Text(item.namaCapster)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCapster = value),
                      validator: (value) =>
                          value == null ? 'Capster wajib dipilih' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.content_cut,
                  title: 'Jumlah Layanan',
                  subtitle:
                      'Isi jumlah layanan yang dikerjakan pada transaksi harian.',
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth >= 640
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              PendapatanHarianModel.kodeLayanan.map((kode) {
                            return SizedBox(
                              width: itemWidth,
                              child: _serviceInput(kode),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.groups_2_outlined,
                  title: 'Jumlah Customer',
                  subtitle:
                      'Customer Santri dihitung dari layanan Santri. Layanan lainnya masuk Customer Umum.',
                  children: [
                    ResponsiveActionRow(
                      children: [
                        TextFormField(
                          controller: _csController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Customer Santri',
                            hintText: 'Otomatis',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          validator: (value) => Validators.number(
                              value, 'Customer Santri',
                              required: false),
                        ),
                        TextFormField(
                          controller: _cuController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Customer Umum',
                            hintText: 'Otomatis',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) => Validators.number(
                              value, 'Customer Umum',
                              required: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _customerSummary(),
                  ],
                ),
                const SizedBox(height: 14),
                _totalSummary(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Pendapatan Harian'),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  icon: Icons.history_outlined,
                  title: 'Riwayat Pendapatan',
                  subtitle:
                      'Transaksi yang salah input dapat dihapus dari Cloud Firestore.',
                  children: [
                    FutureBuilder<List<PendapatanHarianModel>>(
                      future: _pendapatanFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final data = snapshot.data!;
                        if (data.isEmpty) {
                          return const EmptyState(
                              message: 'Belum ada riwayat pendapatan');
                        }
                        return Column(
                          children: [
                            for (var i = data.length - 1; i >= 0; i--) ...[
                              _pendapatanCard(data[i]),
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
          );
        },
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.receipt_long, color: AppColors.teal, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Input Pendapatan Harian',
                  style: TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Catat layanan capster dan customer harian Garden Barbershop.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _serviceInput(String kode) {
    final nama = _namaLayanan[kode] ?? kode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brass.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  kode,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _controllers[kode],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Jumlah',
              hintText: 'Kosong = 0',
              prefixIcon: Icon(Icons.add_circle_outline),
            ),
            validator: (value) =>
                Validators.number(value, nama, required: false),
            onChanged: (_) {
              setState(_syncCustomerControllers);
              _hitungTotal();
            },
          ),
        ],
      ),
    );
  }

  Widget _customerSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_outlined, color: AppColors.teal),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total Customer',
              style: TextStyle(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$_totalCustomer orang',
            style: const TextStyle(
              color: AppColors.tealDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: AppColors.brass),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ringkasan Transaksi',
                  style: TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hitung ulang pendapatan',
                onPressed: _hitungTotal,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Divider(height: 20),
          _summaryRow('Total Item Layanan', '$_totalItemLayanan layanan'),
          const SizedBox(height: 8),
          _summaryRow('Total Customer', '$_totalCustomer orang'),
          const SizedBox(height: 8),
          _summaryRow(
            'Total Pendapatan',
            CurrencyFormatter.format(_totalPendapatan),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.tealDark : AppColors.charcoal,
            fontWeight: FontWeight.w900,
            fontSize: highlight ? 18 : 15,
          ),
        ),
      ],
    );
  }

  Widget _pendapatanCard(PendapatanHarianModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
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
                const Icon(Icons.payments_outlined, color: AppColors.charcoal),
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
                  '${DateFormatter.displayDate(item.tanggal)} • Customer ${item.totalCustomer} orang',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  CurrencyFormatter.format(item.pendapatan),
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
