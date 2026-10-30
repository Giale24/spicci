import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/budget_provider.dart';
import '../../providers/filter_provider.dart';

class MonthlySummaryCard extends ConsumerWidget {
  final VoidCallback onOpenSettings;

  const MonthlySummaryCard({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(budgetStatsProvider);
    final showFixed = ref.watch(showFixedExpensesProvider);
    final showExtraordinary = ref.watch(showExtraordinaryExpensesProvider);
    final currentMonth = AppDateUtils.formatCurrentMonth(DateTime.now());

    double displaySpent = stats.variableExpensesMonth;
    if (showFixed) displaySpent += stats.fixedExpensesMonth;
    if (showExtraordinary) displaySpent += stats.extraordinaryExpensesMonth;

    String? subtitle;
    if (!showFixed && !showExtraordinary) {
      subtitle = '(solo quotidiane)';
    } else if (!showFixed && showExtraordinary) {
      subtitle = '(senza spese fisse)';
    } else if (showFixed && showExtraordinary) {
      subtitle = '(tutte le spese)';
    } else if (stats.extraordinaryExpensesMonth > 0) {
      subtitle = '(senza fuori budget)';
    }

    final progressValue = stats.monthlyBudget > 0
        ? (displaySpent / stats.monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo mese e bottone impostazioni / budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentMonth.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onOpenSettings,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Budget: ${CurrencyUtils.formatCompact(stats.monthlyBudget)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Importo totale speso in evidenza
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyUtils.format(displaySpent),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Barra di progresso del budget mensile
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                (stats.monthlyBudget > 0 && displaySpent > stats.monthlyBudget)
                    ? AppColors.red
                    : AppColors.purple,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Due bottoni filtro: Spese Fisse & Fuori Budget
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
