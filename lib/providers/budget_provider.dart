import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/date_utils.dart';
import 'expenses_provider.dart';

class BudgetNotifier extends StateNotifier<double> {
  static const _prefKey = 'user_monthly_budget';

  BudgetNotifier() : super(1500.0) {
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefKey);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setBudget(double newBudget) async {
    state = newBudget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, newBudget);
  }
}

final monthlyBudgetProvider = StateNotifierProvider<BudgetNotifier, double>((ref) {
  return BudgetNotifier();
});

class BudgetStats {
  final double monthlyBudget;
  final double totalSpentMonth;
  final double fixedExpensesMonth;
  final double extraordinaryExpensesMonth;
  final double variableExpensesMonth;
  final double spentToday;
  final double dailyAllowance;
  final int daysRemaining;
  final double percentMonthUsed;
  final double percentDayUsed;

  const BudgetStats({
    required this.monthlyBudget,
    required this.totalSpentMonth,
    required this.fixedExpensesMonth,
    required this.extraordinaryExpensesMonth,
    required this.variableExpensesMonth,
    required this.spentToday,
    required this.dailyAllowance,
    required this.daysRemaining,
    required this.percentMonthUsed,
    required this.percentDayUsed,
  });
}

final budgetStatsProvider = Provider<BudgetStats>((ref) {
  final monthlyBudget = ref.watch(monthlyBudgetProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final now = DateTime.now();
  final daysRemaining = AppDateUtils.daysRemainingInMonth(now);

  final expenses = expensesAsync.maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );

  double totalSpentMonth = 0.0;
  double fixedExpensesMonth = 0.0;
  double extraordinaryExpensesMonth = 0.0;
  double spentToday = 0.0;

  for (final exp in expenses) {
    if (exp.date.year == now.year && exp.date.month == now.month) {
      totalSpentMonth += exp.amount;
      if (exp.isFixed) {
        fixedExpensesMonth += exp.amount;
      }
      if (exp.isExtraordinary) {
        extraordinaryExpensesMonth += exp.amount;
      }
    }
    // Nel conteggio di oggi, le spese straordinarie (es. auto) non erodono il budget per mangiare/caffè
    if (AppDateUtils.isSameDay(exp.date, now) && !exp.isExtraordinary) {
      spentToday += exp.amount;
    }
  }

  final standardSpentMonth = totalSpentMonth - extraordinaryExpensesMonth;
  final variableExpensesMonth = (standardSpentMonth - fixedExpensesMonth).clamp(0.0, double.infinity);
  final remainingBudget = monthlyBudget - standardSpentMonth;

  // Calcolo del budget giornaliero dinamico:
  // Le spese straordinarie (fuori budget) NON azzerano il budget di oggi!
  final dailyAllowance = daysRemaining > 0
      ? (remainingBudget / daysRemaining).clamp(0.0, monthlyBudget)
      : 0.0;

  final percentMonthUsed = monthlyBudget > 0
      ? (standardSpentMonth / monthlyBudget).clamp(0.0, 1.0)
      : 0.0;

  final percentDayUsed = dailyAllowance > 0
      ? (spentToday / dailyAllowance).clamp(0.0, 1.0)
      : 0.0;

  return BudgetStats(
    monthlyBudget: monthlyBudget,
    totalSpentMonth: totalSpentMonth,
    fixedExpensesMonth: fixedExpensesMonth,
    extraordinaryExpensesMonth: extraordinaryExpensesMonth,
    variableExpensesMonth: variableExpensesMonth,
    spentToday: spentToday,
    dailyAllowance: dailyAllowance,
    daysRemaining: daysRemaining,
    percentMonthUsed: percentMonthUsed,
    percentDayUsed: percentDayUsed,
  );
});
