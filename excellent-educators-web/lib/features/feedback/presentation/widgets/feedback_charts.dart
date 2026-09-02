import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FeedbackOverallCard extends StatelessWidget {
  const FeedbackOverallCard({super.key, required this.summary});

  final FeedbackSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.overallAverage;
    final progress = average == null ? 0.0 : average / 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2744), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall rating',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                average == null ? '—' : average.toStringAsFixed(1),
                style: const TextStyle(
                  color: Brand.gold,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 6),
                child: Text('/ 10', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.totalSessions}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  const Text('monthly ratings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: Brand.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackMonthlyVolumeChart extends StatelessWidget {
  const FeedbackMonthlyVolumeChart({super.key, required this.months});

  final List<FeedbackMonthSummaryDto> months;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const Text('Submit monthly ratings to see how many students you rated each month.');
    }

    final sorted = [...months]
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) {
          return yearCompare;
        }
        return a.month.compareTo(b.month);
      });

    final maxCount = sorted.map((month) => month.sessionCount).fold(0, (max, count) => count > max ? count : max);
    final maxY = maxCount == 0 ? 1.0 : maxCount.toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 16, color: Brand.goldDark),
                SizedBox(width: 6),
                Text(
                  'Students rated per month',
                  style: TextStyle(color: Brand.muted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE6DCCB),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE6DCCB)),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: maxY <= 5 ? 1 : (maxY / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Brand.muted, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              sorted[index].shortLabel,
                              style: const TextStyle(
                                color: Brand.navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Brand.navy,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = sorted[group.x.toInt()];
                        return BarTooltipItem(
                          '${month.monthLabel}\n${month.sessionCount} students',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < sorted.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: sorted[i].sessionCount.toDouble(),
                            width: sorted.length > 8 ? 12 : 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFF3949AB), Brand.goldDark],
                            ),
                          ),
                        ],
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

class FeedbackMonthlyTrendChart extends StatelessWidget {
  const FeedbackMonthlyTrendChart({super.key, required this.months});

  final List<FeedbackMonthSummaryDto> months;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const Text('Complete a few monthly ratings to see the trend graph.');
    }

    final sorted = [...months]
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) {
          return yearCompare;
        }
        return a.month.compareTo(b.month);
      });

    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final rating = sorted[i].averageRating;
      if (rating != null) {
        spots.add(FlSpot(i.toDouble(), rating));
      }
    }

    if (spots.isEmpty) {
      return const Text('No rating averages available yet.');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 16, color: Brand.goldDark),
                SizedBox(width: 6),
                Text(
                  'Average rating over time',
                  style: TextStyle(color: Brand.muted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text(
                  'Scale: 0–10',
                  style: TextStyle(color: Brand.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (sorted.length - 1).toDouble(),
                  minY: 0,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE6DCCB),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE6DCCB)),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Brand.muted, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              sorted[index].shortLabel,
                              style: const TextStyle(
                                color: Brand.navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Brand.navy,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final index = spot.x.round();
                          if (index < 0 || index >= sorted.length) {
                            return null;
                          }
                          final month = sorted[index];
                          return LineTooltipItem(
                            '${month.monthLabel}\n${spot.y.toStringAsFixed(1)} / 10',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          );
                        }).whereType<LineTooltipItem>().toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: sorted.length > 2,
                      curveSmoothness: 0.2,
                      color: const Color(0xFF3949AB),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: Brand.goldDark,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF3949AB).withValues(alpha: 0.18),
                            const Color(0xFF3949AB).withValues(alpha: 0.02),
                          ],
                        ),
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

class FeedbackDimensionOverview extends StatelessWidget {
  const FeedbackDimensionOverview({super.key, required this.dimensions});

  final List<FeedbackDimensionSummaryDto> dimensions;

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) {
      return const Text('Skill ratings will appear here after your Master Teacher submits feedback.');
    }

    return Column(
      children: [
        for (var i = 0; i < dimensions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DimensionBar(
              label: dimensions[i].targetName,
              rating: dimensions[i].averageRating,
              color: _chartColors[i % _chartColors.length],
            ),
          ),
      ],
    );
  }
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.label, required this.rating, required this.color});

  final String label;
  final double rating;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (rating / 10).clamp(0.05, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: const Color(0xFFEDE4D4)),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const _chartColors = [
  Color(0xFFC6A15B),
  Color(0xFF4E8BC9),
  Color(0xFF5BB98C),
  Color(0xFF3949AB),
  Color(0xFF9B5DE5),
  Color(0xFFE07A5F),
];
