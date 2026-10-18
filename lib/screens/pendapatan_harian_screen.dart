import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/capster_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../services/calculation_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/loading_dialog.dart';
import '../services/export_service.dart';
import 'penjualan_produk_tab.dart';

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
    final primaryServices = ['RC', 'PC', 'GC', 'HS', 'KM', 'PR'];
    return _controllers.entries
        .where((entry) => primaryServices.contains(entry.key.toUpperCase()))
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

  void _refreshPendapatan() {
    setState(() {
      _pendapatanFuture = FirebaseService.instance.getPendapatanHarian();
    });
  }

  void _clearForm() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
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
      await FirebaseService.instance.addNotification(
        title: 'Setoran Masuk!',
        message: '${_selectedCapster!.namaCapster} telah memasukkan setoran harian sebesar ${CurrencyFormatter.format(totalPendapatan)}.',
        type: 'income',
      );
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

  Future<void> _exportCsv() async {
    LoadingDialog.show(context);
    try {
      final data = await FirebaseService.instance.getPendapatanHarian();
      final List<List<String>> rows = [
        ['ID Pendapatan', 'Tanggal', 'Nama Capster', 'Pendapatan', 'Customer Santri', 'Customer Umum', 'Total Customer', ...PendapatanHarianModel.kodeLayanan],
      ];
      
      for (var item in data) {
        rows.add([
          item.idPendapatan,
          DateFormatter.displayDate(item.tanggal),
          item.namaCapster,
          item.pendapatan.toString(),
          item.cs.toString(),
          item.cu.toString(),
          item.totalCustomer.toString(),
          ...PendapatanHarianModel.kodeLayanan.map((kode) => (item.jumlahLayanan[kode] ?? 0).toString()),
        ]);
      }
      
      if (!mounted) return;
      LoadingDialog.hide(context);
      
      final fileName = 'Pendapatan_Harian_${DateFormatter.formatDate(DateTime.now()).replaceAll(' ', '_')}';
      await ExportService.exportToCsv(fileName: fileName, data: rows);
      
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor CSV: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ResponsiveScaffold(
        currentRoute: PendapatanHarianScreen.routeName,
        appBar: AppBar(
          title: const Text('Pendapatan Harian'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export ke Excel (CSV)',
              onPressed: _exportCsv,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Layanan Capster'),
              Tab(text: 'Penjualan Produk'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLayananTab(),
            const PenjualanProdukTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLayananTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simpan,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Simpan'),
      ),
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
                    Column(
                      children: PendapatanHarianModel.kodeLayanan.map((kode) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _serviceInput(kode),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _totalSummary(),
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
    return const SizedBox.shrink();
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
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.teal, size: 20),
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
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _serviceInput(String kode) {
    final nama = _namaLayanan[kode] ?? kode;
    final controller = _controllers[kode]!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kode: $kode',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.line)),
              color: AppColors.panel,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _counterButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final current = _parseNumber(controller.text);
                    if (current > 0) {
                      controller.text = (current - 1) == 0 ? '' : (current - 1).toString();
                      _hitungTotal();
                    }
                  },
                ),
                SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.tealDark,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: AppColors.muted),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (_) => _hitungTotal(),
                  ),
                ),
                _counterButton(
                  icon: Icons.add,
                  onPressed: () {
                    final current = _parseNumber(controller.text);
                    controller.text = (current + 1).toString();
                    _hitungTotal();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.tealDark),
        ),
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
