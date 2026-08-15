import 'package:garden_barbershop_finance/services/firebase_service.dart';
import 'package:garden_barbershop_finance/utils/date_formatter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.instance.init();
  
  String targetMonthKey = DateFormatter.toStorageMonth('Juli 2026');
  
  final neraca = await FirebaseService.instance.getNeraca('Juli 2026');
  final bukuKas = await FirebaseService.instance.getBukuKas();
  
  int kas = 0;
  final bukuKasUpToMonth = bukuKas.where((b) {
    final bMonth = DateFormatter.toStorageMonth(b.tanggal);
    return bMonth.compareTo(targetMonthKey) <= 0;
  }).toList();
  if (bukuKasUpToMonth.isNotEmpty) {
    kas = bukuKasUpToMonth.last.saldo;
  }
  
  print("KAS = \$kas");
  print("PIUTANG = \${neraca.piutangUsaha}");
  print("PRIVE = \${neraca.prive}");
}
