import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garden_barbershop_finance/app.dart';
import 'package:garden_barbershop_finance/models/capster_model.dart';
import 'package:garden_barbershop_finance/models/operasional_model.dart';
import 'package:garden_barbershop_finance/models/pendapatan_harian_model.dart';
import 'package:garden_barbershop_finance/screens/akun_pengguna_screen.dart';
import 'package:garden_barbershop_finance/screens/buku_kas_screen.dart';
import 'package:garden_barbershop_finance/screens/capster_screen.dart';
import 'package:garden_barbershop_finance/screens/dashboard_screen.dart';
import 'package:garden_barbershop_finance/screens/laporan_screen.dart';
import 'package:garden_barbershop_finance/screens/layanan_screen.dart';
import 'package:garden_barbershop_finance/screens/operasional_screen.dart';
import 'package:garden_barbershop_finance/screens/pendapatan_harian_screen.dart';
import 'package:garden_barbershop_finance/services/calculation_service.dart';
import 'package:garden_barbershop_finance/services/firebase_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirebaseService.instance.useDummyModeForTesting();
  });

  testWidgets('menampilkan halaman login', (WidgetTester tester) async {
    await tester.pumpWidget(const GardenFinanceApp());

    expect(find.text('Garden Barbershop Finance'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('login admin berhasil menuju dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GardenFinanceApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Menu Utama'), findsOneWidget);
  });

  testWidgets('semua halaman utama dapat dibuka', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'username': 'admin',
      'name': 'Admin Garden',
      'role': 'admin',
    });
    final pages = [
      const DashboardScreen(),
      const AkunPenggunaScreen(),
      const CapsterScreen(),
      const LayananScreen(),
      const PendapatanHarianScreen(),
      const BukuKasScreen(),
      const OperasionalScreen(),
      const LaporanScreen(),
    ];

    for (final page in pages) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pump();
      expect(find.byType(page.runtimeType), findsOneWidget);
    }
  });

  test('perhitungan pembagian hasil sesuai rumus Garden Barbershop', () {
    final laporan = CalculationService().generateLaporanBulanan(
      bulan: '2026-05',
      capsterAktif: const [
        CapsterModel(
          idCapster: 'C001',
          namaCapster: 'Muhamad Diva Syarri',
          noHp: '',
          status: 'aktif',
        ),
        CapsterModel(
          idCapster: 'C002',
          namaCapster: 'Umar Fauzi',
          noHp: '',
          status: 'aktif',
        ),
        CapsterModel(
          idCapster: 'C003',
          namaCapster: 'Abdul Mujib',
          noHp: '',
          status: 'aktif',
        ),
      ],
      pendapatan: const [
        PendapatanHarianModel(
          idPendapatan: 'P001',
          tanggal: '2026-05-31',
          idCapster: 'C001',
          namaCapster: 'Muhamad Diva Syarri',
          jumlahLayanan: {},
          pendapatan: 1809000,
          cs: 0,
          cu: 0,
          totalCustomer: 0,
        ),
      ],
      operasional: const [
        OperasionalModel(
          idOperasional: 'O001',
          bulan: '2026-05',
          namaBiaya: 'Total Operasional',
          akun: 'Operasional',
          nominal: 1579620,
          keterangan: '',
        ),
      ],
    );

    final diva = laporan.first;
    expect(diva.operasionalPerCapster, 526540);
    expect(diva.pendapatanBersih, 1282460);
    expect(diva.bagianCapster, 641230);
    expect(diva.bagianPondok, 641230);
  });
}
