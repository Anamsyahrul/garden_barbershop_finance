import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_scaffold.dart';
import '../utils/currency_formatter.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  static const routeName = '/pengaturan';

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  double _persentase = 50.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPengaturan();
  }

  Future<void> _loadPengaturan() async {
    setState(() => _isLoading = true);
    try {
      final persentase = await FirebaseService.instance.getPersentaseCapster();
      _persentase = (persentase * 100).roundToDouble();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePengaturan() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseService.instance.savePersentaseCapster(_persentase.toInt());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan bagi hasil berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: PengaturanScreen.routeName,
      appBar: AppBar(title: const Text('Pengaturan Bagi Hasil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSliderCard(),
                const SizedBox(height: 20),
                _buildSimulationCard(),
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: _savePengaturan,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Pengaturan'),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Mekanisme Bagi Hasil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tentukan berapa persen bagian keuntungan yang akan didapatkan oleh Capster (pekerja) setelah dipotong biaya operasional.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Persentase Capster',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.charcoal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_persentase.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.tealDark,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.teal,
              inactiveTrackColor: AppColors.line,
              thumbColor: AppColors.teal,
              overlayColor: AppColors.teal.withValues(alpha: 0.1),
              trackHeight: 8,
              valueIndicatorTextStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: _persentase,
              min: 10,
              max: 90,
              divisions: 80,
              label: '${_persentase.toInt()}%',
              onChanged: (value) {
                setState(() {
                  _persentase = value;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capster: ${_persentase.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tealDark),
              ),
              Text(
                'Pondok: ${100 - _persentase.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brassDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationCard() {
    // Simulasi statis untuk mempermudah penjelasan
    const simulasiKotor = 2000000; // 2 Juta
    const simulasiOperasional = 400000; // 400 Ribu
    const bersih = simulasiKotor - simulasiOperasional;
    final bagianCapster = (bersih * (_persentase / 100)).round();
    final bagianPondok = bersih - bagianCapster;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.brassDark),
              SizedBox(width: 8),
              Text(
                'Contoh Simulasi Pembagian',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _simulasiRow('Total Pendapatan Capster (Kotor)', CurrencyFormatter.format(simulasiKotor)),
          const SizedBox(height: 8),
          _simulasiRow('- Potongan Biaya Operasional', CurrencyFormatter.format(simulasiOperasional), isDeduction: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),
          _simulasiRow('Pendapatan Bersih', CurrencyFormatter.format(bersih), isBold: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _hasilAkhirCard(
                  title: 'Diterima Capster',
                  subtitle: '(${_persentase.toInt()}%)',
                  amount: CurrencyFormatter.format(bagianCapster),
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _hasilAkhirCard(
                  title: 'Bagian Pondok',
                  subtitle: '(${100 - _persentase.toInt()}%)',
                  amount: CurrencyFormatter.format(bagianPondok),
                  color: AppColors.brass,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simulasiRow(String label, String value, {bool isDeduction = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? AppColors.charcoal : AppColors.muted,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: isBold ? 14 : 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: isDeduction ? AppColors.danger : AppColors.charcoal,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontSize: isBold ? 15 : 14,
          ),
        ),
      ],
    );
  }

  Widget _hasilAkhirCard({
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: color == AppColors.brass ? AppColors.brassDark : AppColors.tealDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
