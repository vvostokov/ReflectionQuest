// lib/widgets/history/weekly_progress_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log.dart';

class WeeklyProgressChart extends StatelessWidget {
  final List<DailyLog> logs;

  const WeeklyProgressChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    // We only want the last 7 days for the chart
    final last7DaysLogs = logs.length > 7 ? logs.sublist(logs.length - 7) : logs;

    final spots = <FlSpot>[];
    for (int i = 0; i < last7DaysLogs.length; i++) {
      final log = last7DaysLogs[i];
      spots.add(FlSpot(i.toDouble(), (log.dailyPoints ?? 0).toDouble()));
    }

    double maxY = 0;
    if (spots.isNotEmpty) {
      maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    }
    // Add some padding to the top of the chart
    maxY = maxY == 0 ? 50 : maxY * 1.2;

    final colorScheme = Theme.of(context).colorScheme;
    final cardBorderRadius = BorderRadius.circular(12);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.8),
                colorScheme.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) =>
                        _bottomTitleWidgets(value, meta, last7DaysLogs),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: _leftTitleWidgets,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, List<DailyLog> logs) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Colors.white70,
    );
    Widget text;
    final index = value.toInt();
    if (index >= 0 && index < logs.length) {
      final date = DateTime.parse(logs[index].date);
      // Format to day of the week initial (e.g., 'Пн')
      text = Text(DateFormat.E('ru_RU').format(date).substring(0, 2), style: style);
    } else {
      text = const Text('', style: style);
    }

    return text;
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Colors.white70,
    );
    String text;
    if (value > 0 && (value == meta.max || value % (meta.max / 4).ceilToDouble() == 0)) {
      text = value.toInt().toString();
    } else {
      text = '';
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }
}
