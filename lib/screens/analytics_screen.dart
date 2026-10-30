import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_utils.dart';
import '../models/category.dart';
import '../providers/budget_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/filter_provider.dart';
import 'widgets/donut_chart_widget.dart';
import 'widgets/monthly_trend_line_chart.dart';
import 'widgets/weekly_bar_chart_widget.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedChartTab = 0; // 0 = Categorie, 1 = Settimana, 2 = Trend Mese

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(budgetStatsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final showFixed = ref.watch(showFixedExpensesProvider);
    final showExtraordinary = ref.watch(showExtraordinaryExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analisi & Statistiche'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selettore grafico a 3 opzioni (Ciambella, Settimana, Trend Mese)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      icon: Icons.pie_chart_outline_rounded,
                      label: 'Categorie',
                      isSelected: _selectedChartTab == 0,
                      onTap: () => setState(() => _selectedChartTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      icon: Icons.bar_chart_rounded,
                      label: 'Settimana',
                      isSelected: _selectedChartTab == 1,
                      onTap: () => setState(() => _selectedChartTab = 1),
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      icon: Icons.show_chart_rounded,
                      label: 'Trend Mese',
                      isSelected: _selectedChartTab == 2,
                      onTap: () => setState(() => _selectedChartTab = 2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Due bottoni filtro per i grafici: Spese Fisse & Fuori Budget
            Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    icon: Icons.push_pin_rounded,
                    label: 'Spese Fisse',
                    isActive: showFixed,
                    activeColor: AppColors.goldCoin,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(showFixedExpensesProvider.notifier).state = !showFixed;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterButton(
                    icon: Icons.diamond_rounded,
                    label: 'Fuori Budget',
                    isActive: showExtraordinary,
                    activeColor: AppColors.cyan,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(showExtraordinaryExpensesProvider.notifier).state = !showExtraordinary;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Grafico selezionato con animazione di transizione
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedChartTab == 0
                  ? const DonutChartWidget()
                  : (_selectedChartTab == 1
                      ? const WeeklyBarChartWidget()
                      : const MonthlyTrendLineChart()),
            ),

            const SizedBox(height: 20),

            // Statistiche rapide in card a griglia
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Media Giornaliera',
                    value: CurrencyUtils.format(
                      (stats.totalSpentMonth / (DateTime.now().day).clamp(1, 31)),
                    ),
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Spese Fisse',
                    value: CurrencyUtils.format(stats.fixedExpensesMonth),
                    icon: Icons.repeat_rounded,
                    iconColor: AppColors.purpleLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Spese Quotidiane',
                    value: CurrencyUtils.format(stats.variableExpensesMonth),
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.mint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Budget Residuo',
                    value: CurrencyUtils.format(
                      (stats.monthlyBudget - stats.totalSpentMonth).clamp(0.0, stats.monthlyBudget),
                    ),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.goldCoin,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dettaglio Categorie del mese
            Text(
              'Ripartizione Categorie Mese',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            expensesAsync.maybeWhen(
              data: (expenses) {
                final now = DateTime.now();
                final monthExpenses = expenses.where((e) {
                  if (!showFixed && e.isFixed) return false;
                  if (!showExtraordinary && e.isExtraordinary) return false;
                  return e.date.year == now.year && e.date.month == now.month;
                }).toList();

                if (monthExpenses.isEmpty) {
                  return const SizedBox.shrink();
                }

                final Map<String, double> catTotals = {};
                double total = 0;
                for (final exp in monthExpenses) {
                  catTotals[exp.categoryId] = (catTotals[exp.categoryId] ?? 0) + exp.amount;
                  total += exp.amount;
                }

                final sorted = catTotals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  children: sorted.map((entry) {
                    final cat = Category.byId(entry.key);
                    final percent = total > 0 ? (entry.value / total) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(cat.icon, size: 20, color: cat.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${(percent * 100).toStringAsFixed(1)}% del totale speso',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyUtils.format(entry.value),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 4,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.purple.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.purpleLight : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.14)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 13,
              color: isActive ? activeColor : AppColors.borderLight,
            ),
          ],
        ),
      ),
    );
  }
}
