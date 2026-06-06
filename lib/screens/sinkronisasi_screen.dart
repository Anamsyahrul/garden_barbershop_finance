import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_widgets.dart';

class SinkronisasiScreen extends StatefulWidget {
  const SinkronisasiScreen({super.key});

  static const routeName = '/sinkronisasi';

  @override
  State<SinkronisasiScreen> createState() => _SinkronisasiScreenState();
}

class _SinkronisasiScreenState extends State<SinkronisasiScreen> {
  var _loading = false;
  var _message = 'Belum ada proses sinkronisasi.';

  Future<void> _testKoneksi() async {
    setState(() {
      _loading = true;
      _message = 'Menguji koneksi...';
    });
    try {
      await FirebaseService.instance.init();
      final dummy = FirebaseService.instance.dummyMode;
      setState(() {
        _message = dummy
            ? 'Konfigurasi Firebase belum diisi. Aplikasi berjalan dengan dummy data.'
            : 'Koneksi Firebase berhasil.';
      });
    } catch (error) {
      setState(() => _message = 'Koneksi gagal: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
      _message = 'Memuat ulang data dari Firebase...';
    });
    try {
      final capster = await FirebaseService.instance.getCapsterAktif();
      final layanan = await FirebaseService.instance.getLayananAktif();
      setState(() {
        _message =
            'Refresh berhasil. Capster aktif: ${capster.length}, layanan aktif: ${layanan.length}.';
      });
    } catch (error) {
      setState(() => _message = 'Refresh gagal: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sinkronisasi')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppPageHeader(
            title: 'Sinkronisasi',
            subtitle:
                'Periksa koneksi API dan refresh data dari Cloud Firestore.',
            icon: Icons.sync,
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: 'Status Firebase',
            subtitle:
                'Aplikasi akan memakai dummy data jika konfigurasi Firebase belum valid.',
            icon: Icons.cloud_sync_outlined,
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_loading) const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
                ),
                child: Text(
                  _message,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _testKoneksi,
            icon: const Icon(Icons.cloud_done),
            label: const Text('Test Koneksi'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data dari Firestore'),
          ),
        ],
      ),
    );
  }
}
