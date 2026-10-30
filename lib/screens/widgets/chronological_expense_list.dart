import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../models/expense.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/filter_provider.dart';
import '../lampo_sheet.dart';
import 'expense_tile.dart';

class ChronologicalExpenseList extends ConsumerWidget {
  const ChronologicalExpenseList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredExpenses = ref.watch(filteredExpensesProvider);

    if (filteredExpenses.isEmpty) {
      final query = ref.watch(searchQueryProvider);
      final selectedCat = ref.watch(selectedCategoryFilterProvider);

      String title = 'Ancora nessuna spesa registrata';
      String subtitle = 'Tocca il tasto SEGNA in basso per registrare una spesa in 3 secondi!';

      if (query.isNotEmpty) {
        title = 'Nessuna spesa trovata per "$query"';
        subtitle = 'Prova a cercare un\'altra parola chiave o cancella la ricerca.';
      } else if (selectedCat != null) {
        title = 'Nessuna spesa in questa categoria';
        subtitle = 'Tocca il chip della categoria in alto per rimuovere il filtro.';
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              query.isNotEmpty || selectedCat != null
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Raggruppamento per data (Giorno)
    final Map<DateTime, List<Expense>> grouped = {};
    for (final exp in filteredExpenses) {
      final dayKey = DateTime(exp.date.year, exp.date.month, exp.date.day);
      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(exp);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayExpenses = grouped[day]!;
        final dayTotal = dayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intestazione del giorno con totale giornaliero
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppDateUtils.formatDayHeader(day).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(dayTotal),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Voci del giorno
              ...dayExpenses.map((exp) {
                return ExpenseTile(
                  expense: exp,
                  onTap: () {
                    LampoSheet.show(context, expense: exp);
                  },
                  onDelete: () {
                    ref.read(expensesProvider.notifier).deleteExpense(exp.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Spesa eliminata (${CurrencyUtils.format(exp.amount)})'),
                        action: SnackBarAction(
                          label: 'ANNULLA',
                          textColor: AppColors.purpleLight,
                          onPressed: () {
                            ref.read(expensesProvider.notifier).restoreExpense(exp);
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
