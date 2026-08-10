import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/laporan_bulanan_model.dart';
import '../models/operasional_model.dart';
import '../models/pendapatan_harian_model.dart';
import '../models/buku_kas_model.dart';
import '../models/capster_model.dart';
import '../models/neraca_model.dart';
import '../services/firebase_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class PdfGeneratorService {
  static Future<void> generateAndPrintLaporan({
    required String bulan,
    required List<CapsterModel> capster,
    required List<PendapatanHarianModel> pendapatan,
    required List<OperasionalModel> operasional,
    required List<BukuKasModel> bukuKas,
    required List<LaporanBulananModel> semuaLaporan,
    required List<PendapatanHarianModel> semuaPendapatan,
  }) async {
    final pdf = pw.Document();

    // Prepare chart data for Pelanggan
    Map<String, Map<String, int>> customerStats = {};
    for (var p in semuaPendapatan) {
      final dateStr = DateFormatter.toStorageDate(p.tanggal);
      if (dateStr.length >= 7) {
        final m = dateStr.substring(0, 7); // Extract YYYY-MM
        if (!customerStats.containsKey(m)) {
          customerStats[m] = {'cs': 0, 'cu': 0, 'total': 0};
        }
        customerStats[m]!['cs'] = (customerStats[m]!['cs'] ?? 0) + p.cs;
        customerStats[m]!['cu'] = (customerStats[m]!['cu'] ?? 0) + p.cu;
        customerStats[m]!['total'] = (customerStats[m]!['total'] ?? 0) + p.totalCustomer;
      }
    }
    
    // Sort and get last 6 months
    final sortedMonths = customerStats.keys.toList()..sort();
    final chartMonths = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    double maxPelanggan = 10;
    for (var m in chartMonths) {
      if (customerStats[m]!['total']! > maxPelanggan) {
        maxPelanggan = customerStats[m]!['total']!.toDouble();
      }
    }
    // Round up to nearest 100 for better scale
    maxPelanggan = ((maxPelanggan / 100).ceil() * 100).toDouble();

    final customerColors = {
      'cs': PdfColors.blueGrey600,
      'cu': PdfColors.orange200,
      'total': PdfColors.green400,
    };

    final tealColor = PdfColor.fromHex('#1E3D38'); // Dark Green
    final goldColor = PdfColor.fromHex('#B59A55'); // Gold
    final bgGrey = PdfColor.fromHex('#F4F4F4');
    final headerGrey = PdfColor.fromHex('#E0E0E0');
    final borderGrey = PdfColor.fromHex('#CCCCCC');

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/branding/garden_gold_logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    // Calculations
    int totalPendapatanUsaha = pendapatan.fold(0, (sum, item) => sum + item.pendapatan);
    int totalPendapatanLain = 0; 
    int totalPendapatan = totalPendapatanUsaha + totalPendapatanLain;

    int totalHpp = 0; // Not tracked
    int labaKotor = totalPendapatan - totalHpp;
    int totalOperasional = operasional.fold(0, (sum, item) => sum + item.nominal);
    int labaBersih = labaKotor - totalOperasional;

    // --- Components ---
    pw.Widget buildSignature() {
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Brebes, 1 ${bulan.split(' ').first} 2026', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Pengelola Unit Bisnis PP Bustanul Arifin', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Garden Barbershop', style: pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 50),
            pw.Text("Ni'am Abdalla Naofal, S.H., M.H.", style: pw.TextStyle(fontSize: 10, decoration: pw.TextDecoration.underline)),
          ],
        ),
      );
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 40, right: 40, top: 40, bottom: 80),
      buildBackground: (context) {
        if (context.pageNumber == 1) return pw.SizedBox(); // No footer on cover
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              pw.Positioned(
                bottom: 10,
                right: 0,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: tealColor,
                  child: pw.Text(
                    context.pageNumber.toString().padLeft(2, '0'),
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // --- PAGE 1: COVER ---
    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    top: 0, left: 0, right: 0,
                    child: pw.Container(height: 30, color: tealColor),
                  ),
                  pw.Positioned(
                    top: 30, left: 0, right: 0,
                    child: pw.Container(height: 10, color: goldColor),
                  ),
                  pw.Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: pw.Container(height: 40, color: tealColor),
                  ),
                  pw.Positioned(
                    bottom: 40, left: 0, right: 0,
                    child: pw.Container(height: 15, color: goldColor),
                  ),
                ],
              ),
            );
          }
        ),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(50),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Spacer(),
                if (logoImage != null)
                  pw.Image(logoImage, width: 200)
                else
                  pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: goldColor)),
                pw.SizedBox(height: 50),
                pw.Text('LAPORAN', style: pw.TextStyle(fontSize: 42, fontWeight: pw.FontWeight.bold, color: tealColor, letterSpacing: 2)),
                pw.Text('KEUANGAN', style: pw.TextStyle(fontSize: 42, fontWeight: pw.FontWeight.bold, color: tealColor, letterSpacing: 2)),
                pw.SizedBox(height: 20),
                pw.Text('PERIODE ${bulan.toUpperCase()}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: tealColor)),
                pw.SizedBox(height: 60),
                pw.Text('LABA UNTUNG', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 5),
                pw.Text('LABA BERSIH DARI TAHUN 2026', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 5),
                pw.Text('BUKU KAS UMUM', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 5),
                pw.Text('NERACA (CATATAN HARTA)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 5),
                pw.Text('ANALISIS PELANGGAN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor, fontStyle: pw.FontStyle.italic)),
                pw.Spacer(),
                pw.Divider(color: goldColor, thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor)),
                pw.Text('Unit Bisnis Pondok Pesantren Bustanul Arifin', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: tealColor)),
                pw.Text('Jalan Eyang Purwa No. 47, Bangbayang, Bantarkawung, Brebes Jawa Tengah', style: pw.TextStyle(fontSize: 9, color: tealColor)),
                pw.SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );

    // --- PAGE 2: LABA UNTUNG ---
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('LABA UNTUNG', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN LABA UNTUNG', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('GARDEN BARBERSHOP PUSAT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('PERIODE ${bulan.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Table Header
              pw.Container(
                color: headerGrey,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Keterangan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('Saldo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ],
                ),
              ),
              // Pendapatan Section
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(color: bgGrey, border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Pendapatan', style: const pw.TextStyle(fontSize: 12)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, top: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Pendapatan Usaha', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(CurrencyFormatter.format(totalPendapatanUsaha), style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, top: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Pendapatan Lainnya', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(CurrencyFormatter.format(totalPendapatanLain), style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Pendapatan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(CurrencyFormatter.format(totalPendapatan), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              // Biaya Atas Pendapatan Section
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(color: bgGrey, border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Biaya Atas Pendapatan', style: const pw.TextStyle(fontSize: 12)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, top: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Harga Pokok Penjualan', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(CurrencyFormatter.format(totalHpp), style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Biaya Atas Pendapatan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(CurrencyFormatter.format(totalHpp), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              // Laba Kotor
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Laba Kotor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(CurrencyFormatter.format(labaKotor), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              // Biaya Administrasi dan Umum Section
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(color: bgGrey, border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Biaya Administrasi dan Umum', style: const pw.TextStyle(fontSize: 12)),
                    for (var op in operasional)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, top: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(op.namaBiaya, style: const pw.TextStyle(fontSize: 12)),
                            pw.Text(CurrencyFormatter.format(op.nominal), style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Biaya Administrasi dan Umum', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(CurrencyFormatter.format(totalOperasional), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              // Laba Bersih
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderGrey))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Laba Bersih', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(CurrencyFormatter.format(labaBersih), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              pw.Spacer(),
              buildSignature(),
            ],
          );
        },
      ),
    );

    // Menyiapkan data historis untuk grafik laba bersih
    final Map<String, int> labaPerBulan = {};
    for (var lap in semuaLaporan) {
      if (lap.namaCapster == 'Total Semua' || lap.idCapster == 'C000') {
        labaPerBulan[lap.bulan] = lap.pendapatanBersih; // atau bagianPondok
      }
    }
    // Gabungkan dengan bulan berjalan (jika belum ada/ingin overwrite dengan yang dihitung live)
    final bulanBerjalan = DateFormatter.toStorageMonth(bulan);
    labaPerBulan[bulanBerjalan] = labaBersih;

    final sortedBulan = labaPerBulan.keys.toList()..sort();
    final List<String> xAxisLabels = [];
    final List<pw.PointChartValue> chartData = [];
    
    // Ambil maksimal 6 bulan terakhir
    final startIdx = (sortedBulan.length > 6) ? sortedBulan.length - 6 : 0;
    for (int i = startIdx; i < sortedBulan.length; i++) {
      xAxisLabels.add(DateFormatter.displayMonth(sortedBulan[i]).split(' ').first);
      chartData.add(pw.PointChartValue(i - startIdx.toDouble(), labaPerBulan[sortedBulan[i]]!.toDouble()));
    }

    double maxY = 1000.0;
    if (chartData.isNotEmpty) {
      maxY = chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (maxY < 1000) maxY = 1000.0;
    }

    // --- PAGE 3: GRAFIK LABA BERSIH ---
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('LABA BERSIH DARI PERIODE KE PERIODE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 30),
              
              pw.Container(
                height: 300,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(
                      List<String>.generate(chartData.length, (index) => xAxisLabels[index]),
                      marginStart: 30,
                      marginEnd: 30,
                      ticks: true,
                    ),
                    yAxis: pw.FixedAxis(
                      [0, maxY * 0.25, maxY * 0.5, maxY * 0.75, maxY],
                      format: (v) => 'Rp${(v / 1000000).toStringAsFixed(1)}Jt',
                    ),
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: tealColor,
                      width: 25,
                      data: List<pw.PointChartValue>.generate(
                        chartData.length,
                        (i) => pw.PointChartValue(i.toDouble(), chartData[i].y),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Keterangan Detail di bawah grafik
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < sortedBulan.length; i++)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 150,
                              child: pw.Text(
                                '${DateFormatter.displayMonth(sortedBulan[i]).toUpperCase()}:',
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(labaPerBulan[sortedBulan[i]]!),
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ]
                ),
              ),

              pw.Spacer(),
              buildSignature(),
            ],
          );
        },
      ),
    );

    // --- PAGE 4: BUKU KAS UMUM ---
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) {
          return [
            pw.Center(
              child: pw.Text('BUKU KAS UMUM', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: tealColor)),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BUKU KAS UMUM BESAR (KHUSUS PENGELOLA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                  pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                  pw.Text('PERIODE ${bulan.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['No', 'Tanggal', 'Uraian', 'Penerimaan', 'Pengeluaran', 'Saldo'],
              data: [
                for (var i = 0; i < bukuKas.length; i++)
                  [
                    (i + 1).toString(),
                    DateFormatter.displayDate(bukuKas[i].tanggal),
                    bukuKas[i].uraian,
                    bukuKas[i].penerimaan > 0 ? CurrencyFormatter.format(bukuKas[i].penerimaan) : '',
                    bukuKas[i].pengeluaran > 0 ? CurrencyFormatter.format(bukuKas[i].pengeluaran) : '',
                    CurrencyFormatter.format(bukuKas[i].saldo),
                  ]
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: tealColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              oddRowDecoration: pw.BoxDecoration(color: bgGrey),
            ),
            pw.SizedBox(height: 30),
            buildSignature(),
          ];
        },
      ),
    );

    // --- PAGE 5: NERACA ---
    // Fetch Neraca Snapshot from Firebase (atau dari default jika kosong)
    final neraca = await FirebaseService.instance.getNeraca(bulan);
    
    // Kas diambil langsung dari Saldo Akhir Buku Kas bulan tersebut
    int kas = bukuKas.isNotEmpty ? bukuKas.last.saldo : 0;
    
    int totalHartaLancar = kas + neraca.piutangUsaha;
    int totalHartaTetap = neraca.mesinPeralatan + neraca.peralatanLainnya - neraca.akumPenyusutan;
    int totalHartaLainnya = neraca.sdmBarber + neraca.hartaLainLain;
    int totalHarta = totalHartaLancar + totalHartaTetap + totalHartaLainnya;
    
    // Total Kewajiban
    int totalKewajibanLancar = neraca.hutangUsaha + neraca.hutangLancarLainnya;
    int totalKewajibanJangkaPanjang = neraca.hutangBank + neraca.pinjamanPihakKetiga + neraca.pinjamanJangkaPanjang;
    int totalKewajiban = totalKewajibanLancar + totalKewajibanJangkaPanjang;

    // Laba Berjalan adalah total seluruh laba bersih di tahun ini hingga bulan yang dipilih
    int labaBerjalan = 0;
    for (var v in labaPerBulan.values) {
      labaBerjalan += v;
    }
    
    // Agar balance secara otomatis pada pencatatan single-entry
    int labaDitahan = totalHarta - (totalKewajiban + neraca.modalAwal + neraca.labaTahunLalu + labaBerjalan + neraca.prive);

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('NERACA (CATATAN HARTA)', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NERACA (CATATAN HARTA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('PERIODE ${bulan.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Kiri: Harta
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildNeracaTable('Harta Lancar', {'Kas': kas, 'Piutang Usaha': neraca.piutangUsaha, 'Persediaan': 0, 'Perlengkapan': 0}, totalHartaLancar, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTable('Harta Tetap', {'Mesin dan Peralatan Cukur': neraca.mesinPeralatan, 'Peralatan Lainnya': neraca.peralatanLainnya, 'Akum. Penyusutan': neraca.akumPenyusutan}, totalHartaTetap, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTable('Harta Lainnya', {'SDM Barber': neraca.sdmBarber, 'Harta Lainnya': neraca.hartaLainLain}, totalHartaLainnya, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTotalRow('Total Harta/Aktiva/Aset', totalHarta, tealColor, borderGrey),
                      ]
                    )
                  ),
                  pw.SizedBox(width: 20),
                  // Kanan: Kewajiban & Modal
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildNeracaTable('Kewajiban Lancar', {'Hutang Usaha': neraca.hutangUsaha, 'Hutang Lancar Lainnya': neraca.hutangLancarLainnya}, totalKewajibanLancar, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTable('Kewajiban Jangka Panjang', {'Hutang Bank': neraca.hutangBank, 'Pinjaman Pihak Ketiga': neraca.pinjamanPihakKetiga, 'Pinjaman Jangka Panjang': neraca.pinjamanJangkaPanjang}, totalKewajibanJangkaPanjang, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTable('Modal', {'Modal Awal': neraca.modalAwal, 'Laba Tahun Lalu': neraca.labaTahunLalu, 'Laba Berjalan': labaBerjalan, 'Laba Ditahan': labaDitahan, 'Prive': neraca.prive}, totalHarta, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTotalRow('Total Harta/Pasiva', totalHarta, tealColor, borderGrey),
                      ]
                    )
                  ),
                ]
              ),
              pw.Spacer(),
              buildSignature(),
            ],
          );
        },
      ),
    );

    // --- PAGE 6: ANALISIS PELANGGAN ---
    int totalSantri = pendapatan.fold(0, (sum, item) => sum + item.cs);
    int totalUmum = pendapatan.fold(0, (sum, item) => sum + item.cu);
    int totalPelanggan = totalSantri + totalUmum;
    int hariKerja = pendapatan.map((e) => e.tanggal.split('T').first).toSet().length;
    int rataRata = hariKerja > 0 ? (totalPelanggan / hariKerja).round() : 0;
    
    double pSantri = totalPelanggan > 0 ? (totalSantri / totalPelanggan) : 0;
    double pUmum = totalPelanggan > 0 ? (totalUmum / totalPelanggan) : 0;

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('ANALISIS PELANGGAN', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('JUMLAH PELANGGAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('PERIODE ${bulan.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Pelanggan', 'Jumlah Pelanggan'],
                data: [
                  ['1', 'Pelanggan Santri', totalSantri.toString()],
                  ['2', 'Pelanggan Umum', totalUmum.toString()],
                  ['', 'Total', totalPelanggan.toString()],
                  ['', 'Dibagi Hari Kerja', hariKerja.toString()],
                  ['', 'Rata-rata Jumlah Customer Per Hari', rataRata.toString()],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: tealColor),
                cellStyle: const pw.TextStyle(fontSize: 10),
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              ),
              pw.SizedBox(height: 20),
              
              // Pie Chart
              pw.Center(
                child: pw.Text('PERSENTASE PELANGGAN BULAN ${bulan.toUpperCase()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.SizedBox(
                height: 150,
                child: pw.Chart(
                  grid: pw.PieGrid(),
                  datasets: [
                    pw.PieDataSet(
                      value: pSantri,
                      color: goldColor,
                      legend: 'Pelanggan Santri (${(pSantri*100).toStringAsFixed(1)}%)',
                    ),
                    pw.PieDataSet(
                      value: pUmum,
                      color: tealColor,
                      legend: 'Pelanggan Umum (${(pUmum*100).toStringAsFixed(1)}%)',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Line Chart: Jumlah Pelanggan Dari Periode Ke Periode
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey)),
                child: pw.Column(
                  children: [
                    pw.Text('JUMLAH PELANGGAN DARI PERIODE KE PERIODE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(width: 10, height: 2, color: PdfColors.blueGrey600),
                        pw.SizedBox(width: 5),
                        pw.Text('Pelanggan Santri', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(width: 15),
                        pw.Container(width: 10, height: 2, color: PdfColors.orange200),
                        pw.SizedBox(width: 5),
                        pw.Text('Pelanggan Umum', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(width: 15),
                        pw.Container(width: 6, height: 6, decoration: const pw.BoxDecoration(color: PdfColors.green400, shape: pw.BoxShape.circle)),
                        pw.SizedBox(width: 5),
                        pw.Text('Total Pelanggan', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      height: 150,
                      child: pw.Chart(
                        grid: pw.CartesianGrid(
                          xAxis: pw.FixedAxis.fromStrings(
                            List<String>.generate(chartMonths.length, (index) => DateFormatter.displayMonth(chartMonths[index]).split(' ').first),
                            marginStart: 20,
                            marginEnd: 20,
                            ticks: true,
                          ),
                          yAxis: pw.FixedAxis(
                            [0, maxPelanggan * 0.25, maxPelanggan * 0.5, maxPelanggan * 0.75, maxPelanggan],
                            format: (v) => v.toInt().toString(),
                          ),
                        ),
                        datasets: [
                          pw.LineDataSet(
                            color: PdfColors.blueGrey600,
                            isCurved: false,
                            data: List<pw.PointChartValue>.generate(
                              chartMonths.length,
                              (i) => pw.PointChartValue(i.toDouble(), customerStats[chartMonths[i]]!['cs']!.toDouble()),
                            ),
                          ),
                          pw.LineDataSet(
                            color: PdfColors.orange200,
                            isCurved: false,
                            data: List<pw.PointChartValue>.generate(
                              chartMonths.length,
                              (i) => pw.PointChartValue(i.toDouble(), customerStats[chartMonths[i]]!['cu']!.toDouble()),
                            ),
                          ),
                          pw.LineDataSet(
                            color: PdfColors.green400,
                            isCurved: false,
                            drawPoints: true,
                            pointSize: 3,
                            pointColor: PdfColors.green400,
                            data: List<pw.PointChartValue>.generate(
                              chartMonths.length,
                              (i) => pw.PointChartValue(i.toDouble(), customerStats[chartMonths[i]]!['total']!.toDouble()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('ANALISIS DAN EVALUASI', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: tealColor)),
              pw.SizedBox(height: 5),
              pw.Text('1. Total pelanggan bulan ini adalah $totalPelanggan orang, dengan rata-rata $rataRata per hari.', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('2. Pelanggan didominasi oleh ${totalSantri > totalUmum ? "Santri" : "Umum"}.', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('3. Tingkatkan pemasaran untuk meningkatkan persentase pelanggan.', style: const pw.TextStyle(fontSize: 9)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Laporan_Keuangan_Garden_Barbershop_${bulan.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildNeracaTable(String title, Map<String, int> items, int total, PdfColor headerColor, PdfColor borderColor) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor)),
      child: pw.Column(
        children: [
          pw.Container(
            color: headerColor,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Keterangan', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.Text('Saldo', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ]
            )
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ),
          for (var item in items.entries)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item.key, style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(CurrencyFormatter.format(item.value), style: const pw.TextStyle(fontSize: 8)),
                ]
              )
            ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: borderColor))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total $title', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(CurrencyFormatter.format(total), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ]
            )
          ),
        ]
      )
    );
  }

  static pw.Widget _buildNeracaTotalRow(String title, int total, PdfColor color, PdfColor borderColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text(CurrencyFormatter.format(total), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ]
      )
    );
  }
}
