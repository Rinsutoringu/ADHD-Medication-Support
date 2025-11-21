import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';

/// 血药浓度曲线图组件
class ConcentrationChart extends StatelessWidget {
  final MedicationProvider provider;

  const ConcentrationChart({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartData = provider.getChartData(hours: 12);
    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = chartData.map((point) {
      return FlSpot(point.time.inMinutes / 60.0, point.concentration);
    }).toList();

    final maxY = chartData
        .map((p) => p.concentration)
        .reduce((a, b) => a > b ? a : b);

    final currentHours = (provider.currentDose?.timeSinceDose.inMinutes ?? 0) / 60.0;
    final doseTime = provider.currentDose?.doseTime ?? DateTime.now();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '血药浓度曲线',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(2),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: 12,
                  minY: 0,
                  maxY: maxY * 1.1,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Colors.blueGrey.withOpacity(0.9),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final hours = spot.x;
                          final minutes = (hours * 60).round();
                          final targetTime =
                              doseTime.add(Duration(minutes: minutes));
                          final timeStr = DateFormat('HH:mm').format(targetTime);
                          final concentration = spot.y.toStringAsFixed(2);

                          return LineTooltipItem(
                            '时间: $timeStr\n浓度: $concentration mg/L',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {},
                    handleBuiltInTouches: true,
                  ),
                  lineBarsData: [
                    // 已消耗时间部分（高亮显示）
                    if (currentHours > 0)
                      LineChartBarData(
                        spots: spots.where((s) => s.x <= currentHours).toList(),
                        isCurved: true,
                        color: Colors.blue.shade600,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.shade300.withOpacity(0.5),
                        ),
                      ),
                    // 未来时间部分（半透明显示）
                    LineChartBarData(
                      spots: spots.where((s) => s.x >= currentHours).toList(),
                      isCurved: true,
                      color: Colors.blue.shade600.withOpacity(0.4),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.shade100.withOpacity(0.2),
                      ),
                    ),
                    // 当前时间点标记
                    if (currentHours >= 0.1 && currentHours <= 12)
                      LineChartBarData(
                        spots: [
                          FlSpot(
                            currentHours,
                            provider.currentDose?.currentConcentration ?? 0,
                          ),
                        ],
                        isCurved: false,
                        color: Colors.transparent,
                        barWidth: 0,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.orange.shade600,
                              strokeWidth: 2.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
