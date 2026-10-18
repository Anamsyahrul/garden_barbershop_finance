import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/laporan_bulanan_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/migration_tool.dart';
import '../widgets/responsive_scaffold.dart';

class LaporanLengkapScreen extends StatefulWidget {
  const LaporanLengkapScreen({super.key});

  static const routeName = '/laporan-lengkap';

  @override
  State<LaporanLengkapScreen> createState() => _LaporanLengkapScreenState();
}

class _LaporanLengkapScreenState extends State<LaporanLengkapScreen> {
  late Future<List<LaporanBulanAgregat>> _future;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _future = _fetchData();
  }

  Future<List<LaporanBulanAgregat>> _fetchData() async {
    final rawData = await FirebaseService.instance.getSemuaLaporanBulanan();
    final allPendapatan = await FirebaseService.instance.getPendapatanHarian();
    final Map<String, LaporanBulanAgregat> aggregated = {};
    
    // Group customers by month
    final Map<String, Map<String, int>> customerCounts = {};
    for (var p in allPendapatan) {
      if (p.pendapatan > 0 || p.cs > 0 || p.cu > 0) {
        final displayMonth = DateFormatter.displayMonth(p.tanggal);
        if (!customerCounts.containsKey(displayMonth)) {
          customerCounts[displayMonth] = {'santri': 0, 'umum': 0};
        }
        customerCounts[displayMonth]!['santri'] = customerCounts[displayMonth]!['santri']! + p.cs;
        customerCounts[displayMonth]!['umum'] = customerCounts[displayMonth]!['umum']! + p.cu;
      }
    }

    for (var item in rawData) {
      final bulanDisplay = DateFormatter.displayMonth(item.bulan);
      int tSantri = customerCounts[bulanDisplay]?['santri'] ?? 0;
      int tUmum = customerCounts[bulanDisplay]?['umum'] ?? 0;

      if (aggregated.containsKey(item.bulan)) {
        final existing = aggregated[item.bulan]!;
        aggregated[item.bulan] = LaporanBulanAgregat(
          bulan: existing.bulan,
          pendapatanKotor: existing.pendapatanKotor + item.pendapatanKotor,
          totalOperasional: existing.totalOperasional,
          pendapatanBersih: existing.pendapatanBersih + item.pendapatanBersih,
          bagianPondok: existing.bagianPondok + item.bagianPondok,
          sisaDiterimaCapster: existing.sisaDiterimaCapster + item.sisaDiterimaCapster,
          totalSantri: tSantri,
          totalUmum: tUmum,
        );
      } else {
        aggregated[item.bulan] = LaporanBulanAgregat(
          bulan: item.bulan,
          pendapatanKotor: item.pendapatanKotor,
          totalOperasional: item.totalOperasional,
          pendapatanBersih: item.pendapatanBersih,
          bagianPondok: item.bagianPondok,
          sisaDiterimaCapster: item.sisaDiterimaCapster,
          totalSantri: tSantri,
          totalUmum: tUmum,
        );
      }
    }

    final sortedList = aggregated.values.toList()
      ..sort((a, b) => a.bulan.compareTo(b.bulan));

    setState(() => _isLoading = false);
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: LaporanLengkapScreen.routeName,
      appBar: AppBar(
        title: const Text('Laporan Lengkap & Grafik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Reset Data ke Juli 2026',
            onPressed: () async {
              showDialog(
                context: context,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
              try {
                await MigrationTool.execute();
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Berhasil reset data ke Juli 2026')),
                  );
                  setState(() {
                    _isLoading = true;
                    _future = _fetchData();
                  });
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal reset: $e')),
                  );
                }
              }
            },
          ),
          if (!_isLoading && _future != null)
            FutureBuilder<List<LaporanBulanAgregat>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.print_rounded),
                    onPressed: () {
                      PdfGeneratorService.generateAndPrintLaporanLengkap(snapshot.data!);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: FutureBuilder<List<LaporanBulanAgregat>>(
        future: _future,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data laporan bulanan',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + MediaQuery.paddingOf(context).bottom),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBarChart(data),
              const SizedBox(height: 24),
              _buildLineChart(data),
              const SizedBox(height: 24),
              _buildSummaryTable(data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analitik Keuangan',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Ringkasan tren pendapatan dan operasional barbershop.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.1, end: 0, duration: 400.ms);
  }

  Widget _buildBarChart(List<LaporanBulanAgregat> data) {
    // Tampilkan maksimal 6 bulan terakhir
    final chartData = data.length > 6 ? data.sublist(data.length - 6) : data;
    double maxVal = 1;
    for (var d in chartData) {
      if (d.pendapatanKotor > maxVal) maxVal = d.pendapatanKotor.toDouble();
      if (d.totalOperasional > maxVal) maxVal = d.totalOperasional.toDouble();
    }
    // Tambah margin atas 20%
    maxVal = maxVal * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: AppTheme.radiusLarge,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendapatan vs Operasional',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.charcoal),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _indicator(AppColors.teal, 'Pendapatan Kotor'),
              const SizedBox(width: 16),
              _indicator(AppColors.danger, 'Operasional'),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: maxVal,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.ink.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        CurrencyFormatter.format(rod.toY.toInt()),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormatter.displayMonthShort(chartData[index].bulan),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == maxVal || value == 0) return const SizedBox.shrink();
                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}jt',
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.line, strokeWidth: 1),
                ),
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.pendapatanKotor.toDouble(),
                        color: AppColors.teal,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: item.totalOperasional.toDouble(),
                        color: AppColors.danger,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ).animate().fade(duration: 600.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<LaporanBulanAgregat> data) {
    final chartData = data.length > 6 ? data.sublist(data.length - 6) : data;
    double maxVal = 1;
    for (var d in chartData) {
      if (d.bagianPondok > maxVal) maxVal = d.bagianPondok.toDouble();
    }
    maxVal = maxVal * 1.3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink, // Premium dark background
        borderRadius: AppTheme.radiusLarge,
        boxShadow: [
          BoxShadow(color: AppColors.ink.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Keuntungan Bersih (Bagian Pondok)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pergerakan nilai yang disetor ke kas pondok.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                maxY: maxVal,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.brass.withOpacity(0.9),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          CurrencyFormatter.format(spot.y.toInt()),
                          const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              DateFormatter.displayMonthShort(chartData[index].bulan),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white54),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == maxVal || value == 0) return const SizedBox.shrink();
                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}jt',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.bagianPondok.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.brass,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(radius: 5, color: AppColors.brass, strokeWidth: 2, strokeColor: AppColors.ink),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brass.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 800.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTable(List<LaporanBulanAgregat> data) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppTheme.radiusLarge,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
              color: AppColors.panel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_chart_outlined, color: AppColors.charcoal, size: 20),
                SizedBox(width: 10),
                Text('Rincian Tabel per Bulan', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.charcoal)),
              ],
            ),
          ),
          for (var i = data.length - 1; i >= 0; i--) ...[
            _tableRow(data[i]),
            if (i > 0) const Divider(height: 1, color: AppColors.line),
          ],
        ],
      ),
    );
  }

  Widget _tableRow(LaporanBulanAgregat item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.displayMonth(item.bulan),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.charcoal),
          ),
          const SizedBox(height: 12),
          _detailRow('Pendapatan Kotor', item.pendapatanKotor, AppColors.teal),
          const SizedBox(height: 6),
          _detailRow('Total Operasional', -item.totalOperasional, AppColors.danger),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.line),
          ),
          _detailRow('Bagian Capster', item.sisaDiterimaCapster, AppColors.charcoalSoft),
          const SizedBox(height: 6),
          _detailRow('Bagian Pondok', item.bagianPondok, AppColors.brassDark, isBold: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, int value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.charcoalSoft, fontSize: 13, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
        Text(CurrencyFormatter.format(value), style: TextStyle(color: color, fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700)),
      ],
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
