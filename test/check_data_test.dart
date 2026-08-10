import 'package:flutter_test/flutter_test.dart';
import 'package:garden_barbershop_finance/services/firebase_service.dart';

void main() {
  test('Check Firestore Data', () async {
    final service = FirebaseService.instance;
    await service.init();
    final bk = await service.getBukuKas();
    print('Buku Kas Count: ${bk.length}');
    final sl = await service.getSemuaLaporanBulanan();
    print('Semua Laporan Count: ${sl.length}');
  });
}
