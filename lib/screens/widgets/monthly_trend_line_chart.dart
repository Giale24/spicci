import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/filter_provider.dart';

class MonthlyTrendLineChart extends ConsumerWidget {
  const MonthlyTrendLineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final stats = ref.watch(budgetStatsProvider);
    final showFixed = ref.watch(showFixedExpensesProvider);
    final showExtraordinary = ref.watch(showExtraordinaryExpensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        final now = DateTime.now();
        final currentDay = now.day;
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

        // Calcola la spesa progressiva cumulativa giorno per giorno
        final List<double> dailySpent = List.filled(daysInMonth + 1, 0.0);
        for (final exp in expenses) {
          if (!showFixed && exp.isFixed) continue;
          if (!showExtraordinary && exp.isExtraordinary) continue;
          if (exp.date.year == now.year && exp.date.month == now.month) {
            final day = exp.date.day.clamp(1, daysInMonth);
            dailySpent[day] += exp.amount;
          }
        }

        final List<FlSpot> spots = [];
        double cumulative = 0.0;
        spots.add(const FlSpot(1, 0));

        for (int day = 1; day <= currentDay; day++) {
          cumulative += dailySpent[day];
          spots.add(FlSpot(day.toDouble(), cumulative));
        }

        final maxY = (stats.monthlyBudget > cumulative ? stats.monthlyBudget : cumulative) * 1.15;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Curva di Spesa del Mese',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Spesi: ${CurrencyUtils.format(cumulative)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY / 4).clamp(10.0, 10000.0),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.border.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 7,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 1,
                    maxX: daysInMonth.toDouble(),
                    minY: 0,
                    maxY: maxY > 0 ? maxY : 100,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surfaceElevated,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Giorno ${spot.x.toInt()}\n',
                              TextStyle(color: AppColors.textMuted, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: CurrencyUtils.format(spot.y),
                                  style: TextStyle(
                                    color: AppColors.purpleLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: AppColors.purple,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.purple.withValues(alpha: 0.35),
                              AppColors.purple.withValues(alpha: 0.0),
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
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: AppColors.purple)),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
