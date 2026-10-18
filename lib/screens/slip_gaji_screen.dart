import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/capster_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/responsive_scaffold.dart';

class SlipGajiArgs {
  final CapsterModel capster;
  SlipGajiArgs({required this.capster});
}

class SlipGajiScreen extends StatefulWidget {
  const SlipGajiScreen({super.key, this.capster});
  static const routeName = '/slip-gaji';

  final CapsterModel? capster;

  @override
  State<SlipGajiScreen> createState() => _SlipGajiScreenState();
}

class _SlipGajiScreenState extends State<SlipGajiScreen> {
  CapsterModel? _selectedCapster;
  List<CapsterModel> _allCapsters = [];
  bool _initialized = false;
  DateTime _selectedMonth = DateTime.now();

  bool _isLoading = true;
  String? _errorMessage;
  double _persentaseCapster = 0.5;
  int _totalKomisi = 0;
  int _totalOmzet = 0;
  int _totalBonus = 0;
  int _totalDenda = 0;
  int _totalKasbon = 0;

  @override
  void initState() {
    super.initState();
    if (widget.capster != null) {
      _selectedCapster = widget.capster;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (_selectedCapster == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is SlipGajiArgs) {
          _selectedCapster = args.capster;
        } else if (args is CapsterModel) {
          _selectedCapster = args;
        }
      }
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = FirebaseService.instance;
      final capsters = await db.getCapsters();
      _allCapsters = capsters;

      if (_selectedCapster == null && capsters.isNotEmpty) {
        _selectedCapster = capsters.firstWhere(
          (c) => c.aktif,
          orElse: () => capsters.first,
        );
      } else if (_selectedCapster != null && capsters.isNotEmpty) {
        _selectedCapster = capsters.firstWhere(
          (c) => c.idCapster == _selectedCapster!.idCapster,
          orElse: () => _selectedCapster!,
        );
      }

      await _calculateGaji();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data slip gaji: $e';
        });
      }
    }
  }

  Future<void> _calculateGaji() async {
    if (_selectedCapster == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseService.instance;
      final bulanStr = DateFormatter.formatMonthKey(_selectedMonth);

      // 1. Ambil persentase bagi hasil
      final pct = await db.getPersentaseCapster();

      // 2. Ambil Omzet Harian
      final harian = await db.getPendapatanHarian();
      int omzet = 0;
      for (var p in harian) {
        final pMonth = DateFormatter.toStorageMonth(p.tanggal);
        if (p.idCapster == _selectedCapster!.idCapster && pMonth == bulanStr) {
          omzet += p.pendapatan;
        }
      }

      // 3. Ambil Bonus & Denda
      final bdList = await db.getBonusDendaByMonth(bulanStr);
      int bonus = 0;
      int denda = 0;
      for (var bd in bdList) {
        if (bd.idCapster == _selectedCapster!.idCapster) {
          bonus += bd.nominalBonus;
          denda += bd.nominalDenda;
        }
      }

      // 4. Ambil Kasbon
      final kasbonList = await db.getKasbonByMonth(bulanStr);
      int kasbon = 0;
      for (var k in kasbonList) {
        if (k.idCapster == _selectedCapster!.idCapster && k.status == 'approved') {
          kasbon += k.nominal;
        }
      }

      if (mounted) {
        setState(() {
          _persentaseCapster = pct;
          _totalOmzet = omzet;
          _totalKomisi = (omzet * pct).round();
          _totalBonus = bonus;
          _totalDenda = denda;
          _totalKasbon = kasbon;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan kalkulasi: $e';
        });
      }
    }
  }

  void _pilihBulan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Bulan Penggajian',
    );
    if (picked != null) {
      setState(() => _selectedMonth = picked);
      _calculateGaji();
    }
  }

  void _bukaPratinjauPdf() {
    if (_selectedCapster == null) return;
    final bulanLabel = DateFormatter.formatMonth(_selectedMonth);
    final takeHomePay = _totalKomisi + _totalBonus - _totalDenda - _totalKasbon;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlipGajiPdfPreviewScreen(
          bulan: bulanLabel,
          capster: _selectedCapster!,
          omzet: _totalOmzet,
          persen: (_persentaseCapster * 100).toInt(),
          gajiPokok: _totalKomisi,
          bonus: _totalBonus,
          denda: _totalDenda,
          kasbon: _totalKasbon,
          gajiBersih: takeHomePay,
        ),
      ),
    );
  }

  Future<void> _bagikanLangsung() async {
    if (_selectedCapster == null) return;
    final bulanLabel = DateFormatter.formatMonth(_selectedMonth);
    final takeHomePay = _totalKomisi + _totalBonus - _totalDenda - _totalKasbon;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan file slip gaji PDF...')),
    );

    try {
      await PdfGeneratorService.generateSlipGajiPdf(
        bulan: bulanLabel,
        capster: _selectedCapster!,
        omzet: _totalOmzet,
        persen: (_persentaseCapster * 100).toInt(),
        gajiPokok: _totalKomisi,
        bonus: _totalBonus,
        denda: _totalDenda,
        kasbon: _totalKasbon,
        gajiBersih: takeHomePay,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bulanLabel = DateFormatter.formatMonth(_selectedMonth);
    final takeHomePay = _totalKomisi + _totalBonus - _totalDenda - _totalKasbon;

    final hasSelected = _selectedCapster != null &&
        _allCapsters.any((c) => c.idCapster == _selectedCapster!.idCapster);

    final dropdownItems = <DropdownMenuItem<String>>[
      if (!hasSelected && _selectedCapster != null)
        DropdownMenuItem<String>(
          value: _selectedCapster!.idCapster,
          child: Text(
            'Capster: ${_selectedCapster!.namaCapster}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ..._allCapsters.map((c) {
        return DropdownMenuItem<String>(
          value: c.idCapster,
          child: Text(
            'Capster: ${c.namaCapster}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
      }),
    ];

    return ResponsiveScaffold(
      currentRoute: SlipGajiScreen.routeName,
      appBar: AppBar(
        title: const Text('Slip Gaji Capster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedCapster == null
                  ? const Center(
                      child: Text('Tidak ada data capster yang ditemukan.'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Filter Bar: Dropdown Capster & Bulan
                          Card(
                            elevation: 0,
                            color: AppColors.panel,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.line),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCapster!.idCapster,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.teal),
                                        items: dropdownItems,
                                        onChanged: (newId) {
                                          if (newId != null && newId != _selectedCapster!.idCapster) {
                                            setState(() {
                                              _selectedCapster = _allCapsters.firstWhere(
                                                (c) => c.idCapster == newId,
                                                orElse: () => _selectedCapster!,
                                              );
                                            });
                                            _calculateGaji();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      side: const BorderSide(color: AppColors.brass),
                                    ),
                                    icon: const Icon(Icons.calendar_month, size: 16, color: AppColors.brassDark),
                                    label: Text(bulanLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                    onPressed: _pilihBulan,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tampilan Desain Slip Gaji
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(color: AppColors.line),
                            ),
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'GARDEN BARBERSHOP',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.teal,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'SLIP GAJI KARYAWAN',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.charcoal,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Periode: $bulanLabel',
                                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 32, thickness: 1.5),

                                // Capster Info Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.panel,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Nama Capster', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                          Text(
                                            _selectedCapster!.namaCapster,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Bagi Hasil', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                          Text(
                                            '${(_persentaseCapster * 100).toInt()}%',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brassDark),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  'PENDAPATAN & KOMISI',
                                  style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                _buildRowItem('Total Omzet Layanan', CurrencyFormatter.format(_totalOmzet), bold: false),
                                _buildRowItem('Komisi Bagi Hasil (${(_persentaseCapster * 100).toInt()}%)', CurrencyFormatter.format(_totalKomisi), bold: true),
                                if (_totalBonus > 0)
                                  _buildRowItem('Bonus / Apresiasi', CurrencyFormatter.format(_totalBonus), isPlus: true),

                                const SizedBox(height: 16),
                                const Text(
                                  'POTONGAN',
                                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                if (_totalDenda > 0)
                                  _buildRowItem('Denda Kedisiplinan', CurrencyFormatter.format(_totalDenda), isMinus: true),
                                if (_totalKasbon > 0)
                                  _buildRowItem('Potongan Kasbon', CurrencyFormatter.format(_totalKasbon), isMinus: true),
                                if (_totalDenda == 0 && _totalKasbon == 0)
                                  _buildRowItem('Tidak ada potongan', 'Rp 0', bold: false),

                                const Divider(height: 36, thickness: 1.5),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.mint.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.mint),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('TAKE HOME PAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.navy)),
                                          Text('Total Gaji Bersih', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                                        ],
                                      ),
                                      Text(
                                        CurrencyFormatter.format(takeHomePay),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navy),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tombol Aksi
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.visibility, color: Colors.white),
                            label: const Text(
                              'Pratinjau & Cetak Slip Gaji (PDF)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                            ),
                            onPressed: _bukaPratinjauPdf,
                          ),
                          const SizedBox(height: 10),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: AppColors.teal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.share, color: AppColors.teal),
                            label: const Text(
                              'Bagikan Langsung ke WhatsApp / File',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal, fontSize: 14),
                            ),
                            onPressed: _bagikanLangsung,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildRowItem(String label, String value, {bool bold = false, bool isMinus = false, bool isPlus = false}) {
    Color valColor = AppColors.charcoal;
    if (isMinus) valColor = AppColors.danger;
    if (isPlus) valColor = AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: AppColors.charcoalSoft, fontSize: 13)),
          Text(
            isMinus ? '- $value' : isPlus ? '+ $value' : value,
            style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: valColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class SlipGajiPdfPreviewScreen extends StatelessWidget {
  const SlipGajiPdfPreviewScreen({
    super.key,
    required this.bulan,
    required this.capster,
    required this.omzet,
    required this.persen,
    required this.gajiPokok,
    required this.bonus,
    required this.denda,
    required this.kasbon,
    required this.gajiBersih,
  });

  final String bulan;
  final CapsterModel capster;
  final int omzet;
  final int persen;
  final int gajiPokok;
  final int bonus;
  final int denda;
  final int kasbon;
  final int gajiBersih;

  @override
  Widget build(BuildContext context) {
    final filename = 'Slip_Gaji_${capster.namaCapster.replaceAll(' ', '_')}_$bulan.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text('Slip Gaji - ${capster.namaCapster}'),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => PdfGeneratorService.buildSlipGajiPdfBytes(
          bulan: bulan,
          capster: capster,
          omzet: omzet,
          persen: persen,
          gajiPokok: gajiPokok,
          bonus: bonus,
          denda: denda,
          kasbon: kasbon,
          gajiBersih: gajiBersih,
        ),
        pdfFileName: filename,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
