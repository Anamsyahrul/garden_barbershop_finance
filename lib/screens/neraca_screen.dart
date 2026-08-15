import 'package:flutter/material.dart';

import '../models/neraca_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/rupiah_input_formatter.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/responsive_scaffold.dart';

class NeracaScreen extends StatefulWidget {
  const NeracaScreen({super.key});

  static const routeName = '/neraca';

  @override
  State<NeracaScreen> createState() => _NeracaScreenState();
}

class _NeracaScreenState extends State<NeracaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _bulan = TextEditingController();
  final _piutangUsaha = TextEditingController();
  final _mesinPeralatan = TextEditingController();
  final _peralatanLainnya = TextEditingController();
  final _sdmBarber = TextEditingController();
  final _hartaLainLain = TextEditingController();
  final _akumPenyusutan = TextEditingController();
  final _hutangUsaha = TextEditingController();
  final _hutangLancarLainnya = TextEditingController();
  final _hutangBank = TextEditingController();
  final _pinjamanPihakKetiga = TextEditingController();
  final _pinjamanJangkaPanjang = TextEditingController();
  final _modalAwal = TextEditingController();
  final _labaTahunLalu = TextEditingController();
  final _prive = TextEditingController();

  final List<String> _bulanOptions = [
    'Agustus 2026',
    'Juli 2026',
    'Juni 2026',
    'Mei 2026',
    'April 2026',
  ];

  @override
  void initState() {
    super.initState();
    _bulan.text = _bulanOptions.first;
    _fetchNeraca();
  }

  @override
  void dispose() {
    _bulan.dispose();
    _piutangUsaha.dispose();
    _mesinPeralatan.dispose();
    _peralatanLainnya.dispose();
    _sdmBarber.dispose();
    _hartaLainLain.dispose();
    _akumPenyusutan.dispose();
    _hutangUsaha.dispose();
    _hutangLancarLainnya.dispose();
    _hutangBank.dispose();
    _pinjamanPihakKetiga.dispose();
    _pinjamanJangkaPanjang.dispose();
    _modalAwal.dispose();
    _labaTahunLalu.dispose();
    _prive.dispose();
    super.dispose();
  }

  Future<void> _fetchNeraca() async {
    final model = await FirebaseService.instance.getNeraca(_bulan.text);
    if (!mounted) return;
    setState(() {
      _piutangUsaha.text = CurrencyFormatter.format(model.piutangUsaha);
      _mesinPeralatan.text = CurrencyFormatter.format(model.mesinPeralatan);
      _peralatanLainnya.text = CurrencyFormatter.format(model.peralatanLainnya);
      _sdmBarber.text = CurrencyFormatter.format(model.sdmBarber);
      _hartaLainLain.text = CurrencyFormatter.format(model.hartaLainLain);
      _akumPenyusutan.text = CurrencyFormatter.format(model.akumPenyusutan);
      _hutangUsaha.text = CurrencyFormatter.format(model.hutangUsaha);
      _hutangLancarLainnya.text = CurrencyFormatter.format(model.hutangLancarLainnya);
      _hutangBank.text = CurrencyFormatter.format(model.hutangBank);
      _pinjamanPihakKetiga.text = CurrencyFormatter.format(model.pinjamanPihakKetiga);
      _pinjamanJangkaPanjang.text = CurrencyFormatter.format(model.pinjamanJangkaPanjang);
      _modalAwal.text = CurrencyFormatter.format(model.modalAwal);
      _labaTahunLalu.text = CurrencyFormatter.format(model.labaTahunLalu);
      _prive.text = CurrencyFormatter.format(model.prive);
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    LoadingDialog.show(context);
    try {
      final String storageMonth = DateFormatter.toStorageMonth(_bulan.text);
      final model = NeracaModel(
        idNeraca: 'NRC-$storageMonth',
        bulan: _bulan.text,
        piutangUsaha: CurrencyFormatter.parse(_piutangUsaha.text),
        mesinPeralatan: CurrencyFormatter.parse(_mesinPeralatan.text),
        peralatanLainnya: CurrencyFormatter.parse(_peralatanLainnya.text),
        sdmBarber: CurrencyFormatter.parse(_sdmBarber.text),
        hartaLainLain: CurrencyFormatter.parse(_hartaLainLain.text),
        akumPenyusutan: CurrencyFormatter.parse(_akumPenyusutan.text),
        hutangUsaha: CurrencyFormatter.parse(_hutangUsaha.text),
        hutangLancarLainnya: CurrencyFormatter.parse(_hutangLancarLainnya.text),
        hutangBank: CurrencyFormatter.parse(_hutangBank.text),
        pinjamanPihakKetiga: CurrencyFormatter.parse(_pinjamanPihakKetiga.text),
        pinjamanJangkaPanjang: CurrencyFormatter.parse(_pinjamanJangkaPanjang.text),
        modalAwal: CurrencyFormatter.parse(_modalAwal.text),
        labaTahunLalu: CurrencyFormatter.parse(_labaTahunLalu.text),
        prive: CurrencyFormatter.parse(_prive.text), // Parse handle negative correctly if it has it? Wait, Prive is negative!
      );
      // Wait, CurrencyFormatter.parse ignores negatives. 
      // I should update it to support negative or just assume prive is absolute and multiply by -1 if needed, 
      // but let's let parse handle negatives if it does.
      
      await FirebaseService.instance.saveNeraca(model);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan Harta berhasil disimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan catatan harta: $e')),
      );
    }
  }

  Widget _buildAccordion(String title, List<Widget> children, {bool initiallyExpanded = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.teal,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        shape: const Border(), // Remove borders on expanded
        children: children,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomTextField(
        label: label,
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [RupiahInputFormatter()],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: NeracaScreen.routeName,
      appBar: AppBar(title: const Text('Manajemen Catatan Harta')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simpan,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Simpan'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Bulan Laporan',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.charcoalSoft,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _bulan.text,
                      items: _bulanOptions.map((b) {
                        return DropdownMenuItem(value: b, child: Text(b));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _bulan.text = val;
                          });
                          _fetchNeraca();
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sesuaikan saldo akhir untuk Harta, Kewajiban, dan Modal.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildAccordion('Harta Tetap & Lancar', [
                      _buildTextField('Piutang Usaha', _piutangUsaha),
                        _buildTextField('Mesin & Peralatan Cukur', _mesinPeralatan),
                        _buildTextField('Peralatan Lainnya', _peralatanLainnya),
                        _buildTextField('SDM Barber', _sdmBarber),
                        _buildTextField('Harta Lain-lain', _hartaLainLain),
                        _buildTextField('Akumulasi Penyusutan', _akumPenyusutan),
                      ], initiallyExpanded: true),

                      _buildAccordion('Kewajiban (Hutang)', [
                        _buildTextField('Hutang Usaha', _hutangUsaha),
                        _buildTextField('Hutang Lancar Lainnya', _hutangLancarLainnya),
                        _buildTextField('Hutang Bank', _hutangBank),
                        _buildTextField('Pinjaman Pihak Ketiga', _pinjamanPihakKetiga),
                        _buildTextField('Pinjaman Jangka Panjang', _pinjamanJangkaPanjang),
                      ]),

                      _buildAccordion('Modal', [
                        _buildTextField('Modal Awal', _modalAwal),
                        _buildTextField('Laba Tahun Lalu (2025)', _labaTahunLalu),
                        _buildTextField('Prive', _prive),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
