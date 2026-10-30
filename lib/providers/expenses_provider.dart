import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/database/app_database.dart';
import '../models/expense.dart';

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  ExpensesNotifier() : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final list = await AppDatabase.instance.getAllExpenses();
      // Rimuove e pulisce automaticamente eventuali vecchie spese di prova
      final cleanList = list.where((e) => !e.id.startsWith('sample-')).toList();
      if (cleanList.length != list.length) {
        for (final sample in list.where((e) => e.id.startsWith('sample-'))) {
          await AppDatabase.instance.deleteExpense(sample.id);
        }
      }
      state = AsyncValue.data(cleanList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    final currentList = state.value ?? [];
    // Aggiornamento ottimistico immediato per massima reattività (< 3 tocchi)
    final updated = [expense, ...currentList];
    state = AsyncValue.data(updated);

    try {
      await AppDatabase.instance.insertExpense(expense);
    } catch (e) {
      loadExpenses();
    }
  }

  Future<void> deleteExpense(String id) async {
    final currentList = state.value ?? [];
    final updated = currentList.where((e) => e.id != id).toList();
    state = AsyncValue.data(updated);

    try {
      await AppDatabase.instance.deleteExpense(id);
    } catch (e) {
      loadExpenses();
    }
  }

  Future<void> restoreExpense(Expense expense) async {
    await addExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    final currentList = state.value ?? [];
    final updated = currentList.map((e) => e.id == expense.id ? expense : e).toList();
    state = AsyncValue.data(updated);

    try {
      await AppDatabase.instance.updateExpense(expense);
    } catch (e) {
      loadExpenses();
    }
  }

  Future<void> clearAllExpenses() async {
    final currentList = state.value ?? [];
    state = const AsyncValue.data([]);
    for (final exp in currentList) {
      await AppDatabase.instance.deleteExpense(exp.id);
    }
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpensesNotifier();
});
