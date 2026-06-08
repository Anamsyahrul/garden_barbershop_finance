import 'package:flutter/material.dart';

import '../models/buku_kas_model.dart';
import '../models/laporan_bulanan_model.dart';
import '../services/calculation_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/loading_dialog.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  static const routeName = '/laporan';

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _bulan =
      TextEditingController(text: DateFormatter.formatMonth(DateTime.now()));
  List<LaporanBulananModel> _laporan = [];
  var _loading = false;

  @override
  void dispose() {
    _bulan.dispose();
    super.dispose();
  }

  Future<void> _pilihBulan() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );
    if (picked != null) _bulan.text = DateFormatter.formatMonth(picked);
  }

  Future<void> _hitung() async {
    setState(() => _loading = true);
    try {
      final firebase = FirebaseService.instance;
      final user = await AuthService().currentUser();
      final capster = await firebase.getCapsterAktif();
      final pendapatan = await firebase.getPendapatanByMonth(_bulan.text);
      final operasional = await firebase.getOperasionalByMonth(_bulan.text);
      var laporan = CalculationService().generateLaporanBulanan(
        bulan: _bulan.text,
        capsterAktif: capster,
        pendapatan: pendapatan,
        operasional: operasional,
      );
      if (user?.role == UserRole.capster ||
          user?.role == UserRole.adminHarian) {
        if (user!.idCapster.isEmpty) {
          laporan = [];
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Akun capster belum dikaitkan ke data capster')),
          );
        } else {
          laporan = laporan
              .where((item) => item.idCapster == user.idCapster)
              .toList();
        }
      }
      setState(() => _laporan = laporan);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghitung laporan: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simpan() async {
    if (_laporan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hitung laporan terlebih dahulu')),
      );
      return;
    }
    final user = await AuthService().currentUser();
    if (user?.role == UserRole.capster || user?.role == UserRole.adminHarian) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role ini hanya dapat melihat laporan terkait'),
        ),
      );
      return;
    }
    LoadingDialog.show(context,
        message: 'Menyimpan laporan ke Cloud Firestore...');
    try {
      final firebase = FirebaseService.instance;
      await firebase.saveLaporanBulanan(_laporan);
      await _simpanPendapatanUsahaPondok(firebase);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Laporan tersimpan. Bagian pondok otomatis masuk ke kas umum',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan laporan: $error')),
      );
    }
  }

  Future<void> _simpanPendapatanUsahaPondok(
    FirebaseService firebase,
  ) async {
    final totalBagianPondok =
        _laporan.fold(0, (total, item) => total + item.bagianPondok);
    if (totalBagianPondok <= 0) return;

    final idKas = 'K-PONDOK-${_bulan.text}';
    final tanggal = _tanggalAkhirBulan(_bulan.text);
    final saldoSebelumnya = await firebase.getSaldoSebelumKas(tanggal, idKas);
    final model = BukuKasModel(
      idKas: idKas,
      tanggal: tanggal,
      uraian: 'Pendapatan usaha pondok bulan ${_bulan.text}',
      akun: 'Pendapatan Usaha',
      penerimaan: totalBagianPondok,
      pengeluaran: 0,
      saldo: saldoSebelumnya + totalBagianPondok,
      keterangan: 'Otomatis dari bagian pondok pada laporan pembagian hasil',
    );
    await firebase.upsertBukuKas(model);
  }

  String _tanggalAkhirBulan(String bulan) {
    final parts = bulan.split('-');
    if (parts.length != 2) return DateFormatter.formatDate(DateTime.now());
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) {
      return DateFormatter.formatDate(DateTime.now());
    }
    return DateFormatter.formatDate(DateTime(year, month + 1, 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Pembagian Hasil')),
      drawer: const AppDrawer(),
      bottomNavigationBar:
          const AppBottomNav(currentRoute: LaporanScreen.routeName),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        children: [
          const AppPageHeader(
            title: 'Laporan Pembagian Hasil',
            subtitle:
                'Hitung pendapatan bersih, bagian capster, dan bagian pondok per bulan.',
            icon: Icons.table_chart_outlined,
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: 'Filter Laporan',
            subtitle: 'Pilih bulan laporan sebelum menghitung pembagian hasil.',
            icon: Icons.calendar_month_outlined,
            children: [
              TextFormField(
                controller: _bulan,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Bulan',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pilihBulan,
              ),
              const SizedBox(width: 12),
              const SizedBox(height: 12),
              ResponsiveActionRow(
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : _hitung,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Hitung Laporan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _simpan,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan Laporan'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading && _laporan.isEmpty)
            const EmptyState(
              message:
                  'Belum ada laporan. Pilih bulan dan tekan Hitung Laporan.',
              icon: Icons.query_stats_outlined,
            ),
          if (_laporan.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.linen),
                    columns: const [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Nama Capster')),
                      DataColumn(label: Text('Pendapatan Kotor')),
                      DataColumn(label: Text('Operasional/Capster')),
                      DataColumn(label: Text('Pendapatan Bersih')),
                      DataColumn(label: Text('Bagian Capster')),
                      DataColumn(label: Text('Bagian Pondok')),
                    ],
                    rows: [
                      for (var i = 0; i < _laporan.length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(Text(_laporan[i].namaCapster)),
                            DataCell(Text(CurrencyFormatter.format(
                                _laporan[i].pendapatanKotor))),
                            DataCell(Text(CurrencyFormatter.format(
                                _laporan[i].operasionalPerCapster))),
                            DataCell(Text(CurrencyFormatter.format(
                                _laporan[i].pendapatanBersih))),
                            DataCell(Text(CurrencyFormatter.format(
                                _laporan[i].bagianCapster))),
                            DataCell(Text(CurrencyFormatter.format(
                                _laporan[i].bagianPondok))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (_laporan.isNotEmpty) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 720
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                final totalCapster = _laporan.fold(
                    0, (total, item) => total + item.bagianCapster);
                final totalPondok = _laporan.fold(
                    0, (total, item) => total + item.bagianPondok);
                final totalPendapatan = _laporan.fold(
                    0, (total, item) => total + item.pendapatanKotor);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard('Total Pendapatan', totalPendapatan,
                        Icons.payments_outlined, width),
                    _summaryCard('Total Bagian Capster', totalCapster,
                        Icons.people_alt_outlined, width),
                    _summaryCard('Total Bagian Pondok', totalPondok,
                        Icons.storefront_outlined, width),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int value, IconData icon, double width) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(value),
                      style: const TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
