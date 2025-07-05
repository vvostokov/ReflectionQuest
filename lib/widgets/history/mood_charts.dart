import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/daily_log.dart';
import 'package:my_reflection_app/services/content_service.dart';

class MoodCharts extends StatelessWidget {
  final List<DailyLog> logs;

  const MoodCharts({super.key, required this.logs});

  double _getMoodValue(String? moodString) {
    const moodMap = {
      'Отлично': 5.0,
      'Хорошо': 4.0,
      'Нормально': 3.0,
      'Так себе': 2.0,
      'Плохо': 1.0,
    };
    return moodMap[moodString] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final last7DaysLogs = logs.length > 7 ? logs.sublist(logs.length - 7) : logs;

    final moodSpots = <FlSpot>[];
    final energySpots = <FlSpot>[];
    final satisfactionSpots = <FlSpot>[];

    for (int i = 0; i < last7DaysLogs.length; i++) {
      final log = last7DaysLogs[i];
      final answers = log.questionAnswers ?? {};

      final moodValue = _getMoodValue(answers[ContentService.moodQuestion.id]);
      final energyValue = double.tryParse(answers[ContentService.energyQuestion.id] ?? '0') ?? 0.0;
      final satisfactionValue = double.tryParse(answers[ContentService.satisfactionQuestion.id] ?? '0') ?? 0.0;

      moodSpots.add(FlSpot(i.toDouble(), moodValue));
      energySpots.add(FlSpot(i.toDouble(), energyValue));
      satisfactionSpots.add(FlSpot(i.toDouble(), satisfactionValue));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Динамика за неделю", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildChartCard(context, title: 'Настроение', spots: moodSpots, color: Colors.amber, maxY: 5),
          const SizedBox(height: 12),
          _buildChartCard(context, title: 'Энергия', spots: energySpots, color: Colors.lightGreen, maxY: 10),
          const SizedBox(height: 12),
          _buildChartCard(context, title: 'Удовлетворенность', spots: satisfactionSpots, color: Colors.lightBlue, maxY: 10),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required List<FlSpot> spots, required Color color, required double maxY}) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.3),
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