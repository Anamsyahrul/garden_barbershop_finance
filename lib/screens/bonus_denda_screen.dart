import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/capster_model.dart';
import '../models/bonus_denda_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/rupiah_input_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_page_widgets.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_dialog.dart';

class BonusDendaScreen extends StatefulWidget {
  const BonusDendaScreen({super.key});

  static const routeName = '/bonus-denda';

  @override
  State<BonusDendaScreen> createState() => _BonusDendaScreenState();
}

class _BonusDendaScreenState extends State<BonusDendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bulan =
      TextEditingController(text: DateFormatter.formatMonth(DateTime.now()));
  final _nominalBonus = TextEditingController();
  final _nominalDenda = TextEditingController();
  final _keterangan = TextEditingController();
  
  late Future<List<BonusDendaModel>> _future;
  List<CapsterModel> _capsters = [];
  String? _selectedCapsterId;

  String get _currentMonthKey {
    return DateFormatter.toStorageMonth(_bulan.text);
  }

  @override
  void initState() {
    super.initState();
    _loadCapsters();
    _future = FirebaseService.instance.getBonusDendaByMonth(_currentMonthKey);
  }

  @override
  void dispose() {
    _bulan.dispose();
    _nominalBonus.dispose();
    _nominalDenda.dispose();
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
      _future = FirebaseService.instance.getBonusDendaByMonth(_currentMonthKey);
    });
  }

  Future<void> _pilihBulan() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      _bulan.text = DateFormatter.formatMonth(picked);
      _refreshList();
    }
  }

  void _clearForm() {
    _nominalBonus.clear();
    _nominalDenda.clear();
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
    
    final bonus = CurrencyFormatter.parse(_nominalBonus.text);
    final denda = CurrencyFormatter.parse(_nominalDenda.text);
    if (bonus == 0 && denda == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal bonus atau denda harus diisi')),
      );
      return;
    }

    final capster = _capsters.firstWhere((c) => c.idCapster == _selectedCapsterId);
    
    LoadingDialog.show(context);
    try {
      final model = BonusDendaModel(
        idBonusDenda: 'BD${const Uuid().v4().substring(0, 8)}',
        bulan: _currentMonthKey,
        idCapster: capster.idCapster,
        namaCapster: capster.namaCapster,
        nominalBonus: bonus,
        nominalDenda: denda,
        keterangan: _keterangan.text.trim(),
      );
      await FirebaseService.instance.saveBonusDenda(model);
      
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bonus/Denda berhasil disimpan')),
      );
      _clearForm();
      _refreshList();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $error')),
      );
    }
  }

  Future<void> _hapus(BonusDendaModel data) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Bonus/Denda',
      message:
          'Data "${data.namaCapster}" akan dihapus. Lanjutkan?',
    );
    if (!confirmed) return;
    if (!mounted) return;
    LoadingDialog.show(context);
    try {
      await FirebaseService.instance.deleteBonusDenda(data);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dihapus')),
      );
      _refreshList();
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: BonusDendaScreen.routeName,
      appBar: AppBar(title: const Text('Bonus & Denda Capster')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            const AppPageHeader(
              title: 'Bonus / Denda',
              subtitle: 'Catat bonus tambahan atau denda pemotongan pada laporan akhir.',
              icon: Icons.monetization_on_outlined,
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'Input Bonus/Denda',
              subtitle: 'Pilih bulan, capster, dan isi salah satu nominal.',
              icon: Icons.add_card_outlined,
              children: [
                TextFormField(
                  controller: _bulan,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Bulan (Pilih Tanggal)',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: _pilihBulan,
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
                              value: c.idCapster,
                              child: Text(c.namaCapster),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCapsterId = val;
                      });
                    },
                    validator: (val) => Validators.required(val, 'Capster'),
                  )
                else
                  const Text('Memuat data capster...'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _nominalBonus,
                        label: 'Bonus',
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _nominalDenda,
                        label: 'Denda',
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _keterangan,
                  label: 'Keterangan / Alasan',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _simpan,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan Data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<BonusDendaModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AppSectionCard(
                    title: 'Daftar Bonus/Denda',
                    icon: Icons.list_alt_outlined,
                    children: [
                      Center(
                        child: Text(
                          'Gagal memuat: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  );
                }

                final list = snapshot.data ?? [];
                
                final totalBonus = list.fold(0, (sum, i) => sum + i.nominalBonus);
                final totalDenda = list.fold(0, (sum, i) => sum + i.nominalDenda);

                return AppSectionCard(
                  title: 'Daftar Bonus/Denda (${_bulan.text})',
                  icon: Icons.list_alt_outlined,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+ ${CurrencyFormatter.format(totalBonus)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '- ${CurrencyFormatter.format(totalDenda)}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    if (list.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Belum ada bonus/denda di bulan ini',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.namaCapster,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.keterangan.isNotEmpty)
                                  Text(
                                    item.keterangan,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                Row(
                                  children: [
                                    if (item.nominalBonus > 0)
                                      Text(
                                        '+${CurrencyFormatter.format(item.nominalBonus)}',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (item.nominalBonus > 0 && item.nominalDenda > 0)
                                      const SizedBox(width: 8),
                                    if (item.nominalDenda > 0)
                                      Text(
                                        '-${CurrencyFormatter.format(item.nominalDenda)}',
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                              onPressed: () => _hapus(item),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
