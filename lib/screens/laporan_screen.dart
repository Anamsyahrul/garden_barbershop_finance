import 'package:flutter/material.dart';

import '../models/buku_kas_model.dart';
import '../models/laporan_bulanan_model.dart';
import '../services/calculation_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/loading_dialog.dart';
import '../models/operasional_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../services/pdf_generator_service.dart';

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
      final bulanKey = DateFormatter.toStorageMonth(_bulan.text);
      final capster = await firebase.getCapsterAktif();
      final pendapatan = await firebase.getPendapatanByMonth(bulanKey);
      final operasional = await firebase.getOperasionalByMonth(bulanKey);
      final kasbon = await firebase.getKasbonByMonth(bulanKey);
      var laporan = CalculationService().generateLaporanBulanan(
        bulan: bulanKey,
        capsterAktif: capster,
        pendapatan: pendapatan,
        operasional: operasional,
        kasbon: kasbon,
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


  Future<void> _exportPdf() async {
    final user = await AuthService().currentUser();
    if (user?.role == UserRole.capster || user?.role == UserRole.adminHarian) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur Ekspor PDF hanya untuk Admin & Pemilik')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final firebase = FirebaseService.instance;
      final bulanKey = DateFormatter.toStorageMonth(_bulan.text);
      final capster = await firebase.getCapsterAktif();
      final pendapatan = await firebase.getPendapatanByMonth(bulanKey);
      final operasional = await firebase.getOperasionalByMonth(bulanKey);
      final bukuKas = await firebase.getBukuKas(); // Tampilkan seluruh riwayat
      final semuaLaporan = await firebase.getSemuaLaporanBulanan();
      final semuaPendapatan = await firebase.getPendapatanHarian();
      
      final laporan = CalculationService().generateLaporanBulanan(
        bulan: bulanKey,
        capsterAktif: capster,
        pendapatan: pendapatan,
        operasional: operasional,
      );

      await PdfGeneratorService.generateAndPrintLaporan(
        bulan: _bulan.text,
        capster: capster,
        operasional: operasional,
        pendapatan: pendapatan,
        bukuKas: bukuKas,
        semuaLaporan: semuaLaporan,
        semuaPendapatan: semuaPendapatan,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: LaporanScreen.routeName,
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
        actions: [
          IconButton(
            tooltip: 'Cetak / Ekspor PDF',
            onPressed: _loading ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            color: AppColors.brass,
          ),
          const SizedBox(width: 8),
        ],
      ),
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
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _hitung,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Hitung Laporan'),
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
                      DataColumn(label: Text('Potongan Kasbon')),
                      DataColumn(label: Text('Sisa Diterima')),
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
                                _laporan[i].totalKasbon))),
                            DataCell(Text(CurrencyFormatter.format(
                                _laporan[i].sisaDiterimaCapster))),
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
