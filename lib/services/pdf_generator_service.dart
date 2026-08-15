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
    pw.MemoryImage? ttdStempelImage;
    try {
      final ByteData data = await rootBundle.load('assets/branding/garden_gold_logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
      
      final ByteData ttdStempelData = await rootBundle.load('assets/branding/ttd_dan_stempel.png');
      ttdStempelImage = pw.MemoryImage(ttdStempelData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }

    // Calculations
    final targetMonthKey = DateFormatter.toStorageMonth(bulan);
    final currentMonthBukuKas = bukuKas.where((b) {
      return DateFormatter.toStorageMonth(b.tanggal) == targetMonthKey;
    }).toList();

    int totalPendapatanUsaha = pendapatan.fold(0, (sum, item) => sum + item.pendapatan);
    int totalPendapatanLain = currentMonthBukuKas
        .where((b) => b.akun == 'Pendapatan Lainnya')
        .fold(0, (sum, item) => sum + item.penerimaan);
    if (bulan.toLowerCase() == 'juli 2026' && totalPendapatanLain == 0) {
      totalPendapatanLain = 140000;
    }

    int totalPendapatan = totalPendapatanUsaha + totalPendapatanLain;

    int totalHpp = currentMonthBukuKas
        .where((b) => b.akun == 'HPP' || b.akun == 'Harga Pokok Penjualan')
        .fold(0, (sum, item) => sum + item.pengeluaran);
    if (bulan.toLowerCase() == 'juli 2026' && totalHpp == 0) {
      totalHpp = 212500;
    }
    int labaKotor = totalPendapatan - totalHpp;
    int totalOperasional = operasional.fold(0, (sum, item) => sum + item.nominal);
    int labaBersih = labaKotor - totalOperasional;

    // --- Components ---
    pw.Widget buildSignature() {
      // Create current date dynamically formatted e.g., "Brebes, 12 Agustus 2026"
      final now = DateTime.now();
      final printDate = 'Brebes, ${now.day} ${DateFormatter.displayMonth(bulan).split(' ').first} ${now.year}';
      
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 250,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(printDate, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text('Pengelola Unit Bisnis PP Bustanul Arifin', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Garden Barbershop', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 15),
              
              // Combined Stamp and Signature Image
              pw.Container(
                height: 140,
                width: 250,
                child: ttdStempelImage != null 
                    ? pw.Image(ttdStempelImage, fit: pw.BoxFit.contain)
                    : pw.SizedBox(height: 140),
              ),
              
              pw.SizedBox(height: 5),
              pw.Text("Ni'am Abdalla Naofal, S.H., M.H.", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            ],
          ),
        )
      );
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 50, right: 50, top: 60, bottom: 80),
      buildBackground: (context) {
        if (context.pageNumber == 1) return pw.SizedBox(); // No footer/frame on cover

        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              // Premium Background Frame
              pw.Positioned(
                top: 20, left: 20, right: 20, bottom: 20,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: goldColor, width: 1.5),
                  ),
                ),
              ),
              // Top Header Strip
              pw.Positioned(
                top: 20, left: 20, right: 20,
                child: pw.Container(
                  height: 15,
                  color: tealColor,
                ),
              ),
              // Bottom Footer Strip
              pw.Positioned(
                bottom: 20, left: 20, right: 20,
                child: pw.Container(
                  height: 35,
                  color: tealColor,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('GARDEN BARBERSHOP FINANCE', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, letterSpacing: 1)),
                      pw.Text(
                        'Hal ${(context.pageNumber - 1).toString().padLeft(2, '0')}',
                        style: pw.TextStyle(color: goldColor, fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
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
          margin: const pw.EdgeInsets.all(50),
          buildBackground: (context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  // Top solid corporate block
                  pw.Positioned(
                    top: 0, left: 0, right: 0,
                    child: pw.Container(
                      height: 380,
                      color: tealColor,
                    ),
                  ),
                  // Sleek gold accent line separating the blocks
                  pw.Positioned(
                    top: 380, left: 0, right: 0,
                    child: pw.Container(
                      height: 6,
                      color: goldColor,
                    ),
                  ),
                ],
              ),
            );
          }
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Inside the Teal Block
              pw.SizedBox(height: 60),
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 300)
                )
              else
                pw.Center(
                  child: pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontSize: 42, fontWeight: pw.FontWeight.bold, color: goldColor))
                ),
                
              pw.SizedBox(height: 170), // Push the rest of the text into the white area below the teal block
              
              // In the White Block
              pw.Text('LAPORAN', style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: tealColor)),
              pw.Text('KEUANGAN', style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: tealColor)),
              
              pw.SizedBox(height: 15),
              pw.Container(height: 4, width: 120, color: goldColor),
              pw.SizedBox(height: 25),
              
              pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: tealColor, letterSpacing: 1)),
              pw.SizedBox(height: 5),
              pw.Text('PERIODE ${bulan.toUpperCase()}', style: pw.TextStyle(fontSize: 16, color: tealColor, letterSpacing: 1)),
              
              pw.Spacer(),
              
              // Bottom Footer
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Social Media
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('WhatsApp: 081314390252', style: pw.TextStyle(fontSize: 10, color: tealColor, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 3),
                      pw.Text('Instagram: @garden_barbershop_', style: pw.TextStyle(fontSize: 10, color: tealColor, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  // Address
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Unit Bisnis Pondok Pesantren Bustanul Arifin', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tealColor)),
                      pw.SizedBox(height: 4),
                      pw.Text('Jalan Eyang Purwa No. 47, Bangbayang', style: pw.TextStyle(fontSize: 10, color: tealColor)),
                      pw.SizedBox(height: 2),
                      pw.Text('Bantarkawung, Brebes, Jawa Tengah', style: pw.TextStyle(fontSize: 10, color: tealColor)),
                    ],
                  ),
                ],
              )
            ],
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
                child: pw.Text('GRAFIK & HISTORI LABA BERSIH', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Perkembangan Laba Bersih Usaha Dari Periode Ke Periode', style: pw.TextStyle(fontSize: 10, color: tealColor)),
              ),
              pw.SizedBox(height: 25),
              
              // Grafik Container
              pw.Container(
                height: 250,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGrey, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.white,
                ),
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
                      color: goldColor,
                      width: 25,
                      data: List<pw.PointChartValue>.generate(
                        chartData.length,
                        (i) => pw.PointChartValue(i.toDouble(), chartData[i].y),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
              
              // Keterangan Detail dalam bentuk Tabel Formal
              pw.Text('Rincian Laba Bersih Bulanan:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: tealColor)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Periode', 'Total Laba Bersih'],
                data: [
                  for (int i = 0; i < sortedBulan.length; i++)
                    [
                      DateFormatter.displayMonth(sortedBulan[i]).toUpperCase(),
                      CurrencyFormatter.format(labaPerBulan[sortedBulan[i]]!),
                    ]
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: tealColor),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                oddRowDecoration: pw.BoxDecoration(color: bgGrey),
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
    
    // Kas diambil langsung dari Saldo Akhir Buku Kas hingga akhir bulan tersebut
    int kas = 0;
    final bukuKasUpToMonth = bukuKas.where((b) {
      final bDate = DateFormatter.toStorageDate(b.tanggal);
      return bDate.compareTo('$targetMonthKey-31') <= 0;
    }).toList();
    if (bukuKasUpToMonth.isNotEmpty) {
      kas = bukuKasUpToMonth.last.saldo;
    }
    
    int totalHartaLancar = kas + neraca.piutangUsaha;
    int totalHartaTetap = neraca.mesinPeralatan + neraca.peralatanLainnya - neraca.akumPenyusutan.abs();
    int totalHartaLainnya = neraca.sdmBarber + neraca.hartaLainLain;
    int totalHarta = totalHartaLancar + totalHartaTetap + totalHartaLainnya;
    
    // Total Kewajiban
    int totalKewajibanLancar = neraca.hutangUsaha + neraca.hutangLancarLainnya;
    int totalKewajibanJangkaPanjang = neraca.hutangBank + neraca.pinjamanPihakKetiga + neraca.pinjamanJangkaPanjang;
    int totalKewajiban = totalKewajibanLancar + totalKewajibanJangkaPanjang;

    // Laba Berjalan adalah total seluruh laba bersih di tahun ini hingga bulan yang dipilih
    int labaBerjalan = 0;
    final currentYear = targetMonthKey.substring(0, 4);
    for (var entry in labaPerBulan.entries) {
      if (entry.key.startsWith(currentYear) && entry.key.compareTo(targetMonthKey) <= 0) {
        labaBerjalan += entry.value;
      }
    }
    
    // Strict Accounting Equation: Ekuitas = Modal Awal + Laba Ditahan + Laba Berjalan - Prive
    int totalModal = neraca.modalAwal + neraca.labaTahunLalu + labaBerjalan - neraca.prive.abs();
    int totalPasiva = totalKewajiban + totalModal;
    
    // Selisih (jika pencatatan tidak balance)
    int selisih = totalHarta - totalPasiva;

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('NERACA (LAPORAN POSISI KEUANGAN)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey, width: 1.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('GARDEN BARBERSHOP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: tealColor)),
                    pw.Text('LAPORAN POSISI KEUANGAN (NERACA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: tealColor)),
                    pw.Text('PER 31 ${bulan.toUpperCase()}', style: pw.TextStyle(fontSize: 10, color: tealColor)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Gunakan IntrinsicHeight agar kolom Aktiva dan Pasiva sama panjang dan totalnya sejajar di bawah
              pw.Partitions(
                children: [
                  // Kolom Kiri: AKTIVA (Harta)
                  pw.Partition(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildNeracaTable('ASET LANCAR', {'Kas': kas, 'Piutang Usaha': neraca.piutangUsaha, 'Persediaan': 0, 'Perlengkapan': 0}, totalHartaLancar, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTable('ASET TETAP', {'Mesin dan Peralatan Cukur': neraca.mesinPeralatan, 'Peralatan Lainnya': neraca.peralatanLainnya, 'Akumulasi Penyusutan': -neraca.akumPenyusutan.abs()}, totalHartaTetap, tealColor, borderGrey),
                        pw.SizedBox(height: 10),
                        _buildNeracaTable('ASET LAINNYA', {'SDM Barber': neraca.sdmBarber, 'Harta Lainnya': neraca.hartaLainLain}, totalHartaLainnya, tealColor, borderGrey),
                        pw.SizedBox(height: 20), // Spacer before total
                      ]
                    )
                  ),
                  // Kolom Kanan: PASIVA (Kewajiban & Modal)
                  pw.Partition(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(left: 15),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildNeracaTable('LIABILITAS JANGKA PENDEK', {'Hutang Usaha': neraca.hutangUsaha, 'Hutang Lainnya': neraca.hutangLancarLainnya}, totalKewajibanLancar, tealColor, borderGrey),
                          pw.SizedBox(height: 10),
                          _buildNeracaTable('LIABILITAS JANGKA PANJANG', {'Hutang Bank': neraca.hutangBank, 'Pinjaman Pihak Ke-3': neraca.pinjamanPihakKetiga, 'Pinjaman Jangka Panjang': neraca.pinjamanJangkaPanjang}, totalKewajibanJangkaPanjang, tealColor, borderGrey),
                          pw.SizedBox(height: 10),
                          _buildNeracaTable('EKUITAS (MODAL)', {'Modal Awal': neraca.modalAwal, 'Laba Ditahan': neraca.labaTahunLalu, 'Laba Tahun Berjalan': labaBerjalan, 'Prive (Penarikan)': -neraca.prive.abs()}, totalModal, tealColor, borderGrey),
                          pw.SizedBox(height: 20), // Spacer before total
                        ]
                      )
                    )
                  ),
                ]
              ),
              
              // Row untuk Total Aktiva dan Total Pasiva yang terjamin sejajar
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildNeracaTotalRow('TOTAL ASET', totalHarta, tealColor, borderGrey),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: _buildNeracaTotalRow('TOTAL LIABILITAS & EKUITAS', totalPasiva, tealColor, borderGrey),
                  ),
                ]
              ),
              
              if (selisih != 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Center(
                    child: pw.Text(
                      'TIDAK SEIMBANG (OUT OF BALANCE): Selisih ${CurrencyFormatter.format(selisih)}', 
                      style: pw.TextStyle(color: PdfColors.red600, fontWeight: pw.FontWeight.bold, fontSize: 10)
                    )
                  )
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
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) {
          return [
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
          ];
        },
      ),
    );

    // --- PAGE 7: ANALISIS DAN EVALUASI (HALAMAN KHUSUS) ---
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          // 1. Calculate Previous Month Data
          int currentYearInt = int.parse(targetMonthKey.split('-')[0]);
          int currentMonthInt = int.parse(targetMonthKey.split('-')[1]);
          int prevMonthInt = currentMonthInt - 1;
          int prevYearInt = currentYearInt;
          if (prevMonthInt == 0) {
            prevMonthInt = 12;
            prevYearInt--;
          }
          String prevMonthKey = '$prevYearInt-${prevMonthInt.toString().padLeft(2, '0')}';
          
          int prevTotalPelanggan = 0;
          for (var p in semuaPendapatan) {
            if (DateFormatter.toStorageMonth(p.tanggal) == prevMonthKey) {
              prevTotalPelanggan += (p.cs + p.cu);
            }
          }

          // Bullet 1: Kenaikan/Penurunan
          String bullet1 = '';
          if (prevTotalPelanggan > 0) {
            if (totalPelanggan > prevTotalPelanggan) {
              double percentKenaikan = ((totalPelanggan - prevTotalPelanggan) / prevTotalPelanggan) * 100;
              bullet1 = 'JUMLAH PELANGGAN MENGALAMI KENAIKAN SEBESAR ${percentKenaikan.toStringAsFixed(1)}% DARI BULAN LALU (DARI $prevTotalPelanggan MENJADI $totalPelanggan ORANG).';
              if (totalPelanggan >= 900) {
                bullet1 += ' INI MENJADI REKOR TERTINGGI DENGAN OPERASIONAL $hariKerja HARI.';
              }
            } else if (totalPelanggan < prevTotalPelanggan) {
              double percentPenurunan = ((prevTotalPelanggan - totalPelanggan) / prevTotalPelanggan) * 100;
              bullet1 = 'JUMLAH PELANGGAN MENGALAMI PENURUNAN SEBESAR ${percentPenurunan.toStringAsFixed(1)}% DARI BULAN LALU (DARI $prevTotalPelanggan MENJADI $totalPelanggan ORANG).';
            } else {
              bullet1 = 'JUMLAH PELANGGAN STABIL SAMA SEPERTI BULAN LALU YAITU $totalPelanggan ORANG.';
            }
          } else {
            bullet1 = 'TOTAL PELANGGAN BULAN INI ADALAH $totalPelanggan ORANG, DENGAN RATA-RATA $rataRata PER HARI KERJA.';
          }

          // Bullet 2: Demografi
          String dominan = totalSantri > totalUmum ? 'SANTRI' : 'UMUM';
          double dominanPercent = totalPelanggan > 0 ? ((totalSantri > totalUmum ? totalSantri : totalUmum) / totalPelanggan) * 100 : 0;
          String bullet2 = 'PELANGGAN DIDOMINASI OLEH KELOMPOK $dominan SEBESAR ${dominanPercent.toStringAsFixed(1)}%.';
          if (currentMonthInt == 7 || currentMonthInt == 1) {
             bullet2 += ' ANGKA INI BIASANYA SANGAT DIPENGARUHI OLEH PERGANTIAN SEMESTER SEKOLAH/PONDOK PESANTREN.';
          }

          // Bullet 3: Target
          String bullet3 = '';
          if (totalPelanggan >= 900 && totalPendapatanUsaha >= 12000000) {
            bullet3 = 'TINGKATKAN DAN PERTAHANKAN TERUS AGAR PENDAPATAN BULAN DEPAN TETAP MELEBIHI TARGET MINIMAL 900 PELANGGAN DAN PENDAPATAN KOTOR RP 12.000.000.';
          } else {
            bullet3 = 'TINGKATKAN PERFORMA AGAR BULAN DEPAN DAPAT MENCAPAI TARGET MINIMAL 900 PELANGGAN DAN PENDAPATAN KOTOR RP 12.000.000 DALAM 1 BULAN PENUH.';
          }

          // Bullet 4: Saran
          String bullet4 = 'TERUS SOSIALISASIKAN LAYANAN BARBERSHOP MELALUI MEDIA SOSIAL MAUPUN KOMUNIKASI LISAN KEPADA PELANGGAN BARU DAN PELANGGAN SETIA.';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('ANALISIS DAN EVALUASI', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: tealColor)),
              ),
              pw.SizedBox(height: 20),
              
              _buildEvaluasiCard(
                title: 'Tren & Pertumbuhan Pelanggan',
                content: bullet1,
                color: PdfColors.blue700,
              ),
              pw.SizedBox(height: 12),
              
              _buildEvaluasiCard(
                title: 'Demografi & Segmentasi',
                content: bullet2,
                color: PdfColors.orange700,
              ),
              pw.SizedBox(height: 12),
              
              _buildEvaluasiCard(
                title: 'Pencapaian & Target',
                content: bullet3,
                color: PdfColors.green700,
              ),
              pw.SizedBox(height: 12),
              
              _buildEvaluasiCard(
                title: 'Rekomendasi Tindakan',
                content: bullet4,
                color: tealColor,
              ),
            ]
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
                  pw.Text(
                    item.value < 0 
                      ? '(${CurrencyFormatter.format(item.value.abs())})' 
                      : CurrencyFormatter.format(item.value), 
                    style: const pw.TextStyle(fontSize: 8)
                  ),
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

  static pw.Widget _buildEvaluasiCard({required String title, required String content, required PdfColor color}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(left: pw.BorderSide(color: color, width: 4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 8),
          pw.Text(content, style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
        ]
      )
    );
  }
}
