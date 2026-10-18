import 'dart:convert';
import '../models/operasional_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../services/firebase_service.dart';
import 'migration_data.dart';

class MigrationTool {
  static Future<void> execute() async {
    try {
      final data = jsonDecode(migrationDataJson);
      
      final pendapatanList = data['pendapatan'] as List;
      final operasionalList = data['operasional'] as List;

      // Delete August data and onwards
      try {
        final existingPendapatan = await FirebaseService.instance.getPendapatanHarian();
        for (var p in existingPendapatan) {
          if (p.tanggal.startsWith('2026-08') || p.tanggal.startsWith('2026-09')) {
            await FirebaseService.instance.deletePendapatanHarian(p);
          }
        }
        
        final existingOp = await FirebaseService.instance.getOperasionalByMonth('Agustus 2026');
        for (var o in existingOp) {
          await FirebaseService.instance.deleteOperasional(o);
        }
        final existingOpSep = await FirebaseService.instance.getOperasionalByMonth('September 2026');
        for (var o in existingOpSep) {
          await FirebaseService.instance.deleteOperasional(o);
        }
      } catch (e) {
        print('Error deleting August data: $e');
      }

      // Import Pendapatan
      for (var item in pendapatanList) {
        final map = item as Map<String, dynamic>;
        final model = PendapatanHarianModel(
          idPendapatan: map['idPendapatan'],
          tanggal: map['tanggal'],
          idCapster: map['idCapster'],
          namaCapster: map['namaCapster'],
          jumlahLayanan: {
            'SN': map['SN'] as int? ?? 0,
            'RC': map['RC'] as int? ?? 0,
            'PC': map['PC'] as int? ?? 0,
            'GC': map['GC'] as int? ?? 0,
            'CJ': map['CJ'] as int? ?? 0,
            'KR': map['KR'] as int? ?? 0,
            'CH': map['CH'] as int? ?? 0,
            'HS': map['HS'] as int? ?? 0,
            'PR': map['PR'] as int? ?? 0,
            'KM': map['KM'] as int? ?? 0,
          },
          pendapatan: map['pendapatan'],
          cs: map['cs'],
          cu: map['cu'],
          totalCustomer: map['totalCustomer'],
        );
        await FirebaseService.instance.savePendapatanHarian(model);
      }

      // Import Operasional
      for (var item in operasionalList) {
        final map = item as Map<String, dynamic>;
        final model = OperasionalModel(
          idOperasional: map['idOperasional'],
          bulan: map['bulan'],
          namaBiaya: map['namaBiaya'],
          akun: map['akun'],
          nominal: map['nominal'],
          keterangan: map['keterangan'],
        );
        await FirebaseService.instance.saveOperasional(model);
      }
      
      print('Migration successfully uploaded to Firestore!');
    } catch (e) {
      print('Migration error: $e');
      rethrow;
    }
  }
}
