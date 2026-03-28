import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/robee_theme.dart';

class TelemetryGraph extends StatelessWidget {
  final List<Map<String, dynamic>> data; // [{timestamp, value}]
  final String type;
  final Color color;
  final String title;
  final String unit;

  const TelemetryGraph({
    super.key,
    required this.data,
    required this.type,
    required this.color,
    required this.title,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildContainer(
        child: const Center(
          child: Text('No data', style: RoBeeTheme.bodyMedium),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['value'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yRange = (maxY - minY).abs();
    final yPad = yRange < 2 ? 2.0 : yRange * 0.15;

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: RoBeeTheme.labelLarge.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Text(
                '${spots.last.y.toStringAsFixed(1)} $unit',
                style: RoBeeTheme.monoSmall.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yRange > 0 ? yRange / 3 : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: RoBeeTheme.glassWhite10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: minY - yPad,
                maxY: maxY + yPad,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => RoBeeTheme.background,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)} $unit',
                              RoBeeTheme.monoSmall.copyWith(color: color),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoBeeTheme.glassWhite5,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoBeeTheme.glassWhite10),
      ),
      child: child,
    );
  }
}
