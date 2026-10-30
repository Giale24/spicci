import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/filter_provider.dart';

class WeeklyBarChartWidget extends ConsumerWidget {
  const WeeklyBarChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final showFixed = ref.watch(showFixedExpensesProvider);
    final showExtraordinary = ref.watch(showExtraordinaryExpensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        final now = DateTime.now();
        // Ultimi 7 giorni (da 6 giorni fa ad oggi)
        final List<DateTime> last7Days = List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return DateTime(d.year, d.month, d.day);
        });

        final List<double> dailyTotals = List.filled(7, 0.0);
        double maxDay = 10.0;

        for (final exp in expenses) {
          if (!showFixed && exp.isFixed) continue;
          if (!showExtraordinary && exp.isExtraordinary) continue;
          for (int i = 0; i < 7; i++) {
            if (AppDateUtils.isSameDay(exp.date, last7Days[i])) {
              dailyTotals[i] += exp.amount;
              if (dailyTotals[i] > maxDay) maxDay = dailyTotals[i];
            }
          }
        }

        final barGroups = List.generate(7, (i) {
          final isToday = i == 6;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyTotals[i],
                color: isToday ? AppColors.purple : AppColors.surfaceElevated,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxDay * 1.15,
                  color: AppColors.background.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        });

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
                    'Andamento Ultimi 7 Giorni',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Oggi: ${CurrencyUtils.format(dailyTotals[6])}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxDay * 1.15,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surfaceElevated,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = DateFormat('E d', 'it_IT').format(last7Days[group.x]);
                          return BarTooltipItem(
                            '$day\n',
                            TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            children: [
                              TextSpan(
                                text: CurrencyUtils.format(rod.toY),
                                style: TextStyle(
                                  color: AppColors.purpleLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= 7) return const SizedBox.shrink();
                            final date = last7Days[idx];
                            final label = DateFormat('E', 'it_IT').format(date).substring(0, 3);
                            final isToday = idx == 6;

                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                isToday ? 'Oggi' : label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                  color: isToday ? AppColors.purpleLight : AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
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
