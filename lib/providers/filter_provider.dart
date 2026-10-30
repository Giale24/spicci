import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/expense.dart';
import 'expenses_provider.dart';

/// Categoria selezionata per il filtro (null = mostra tutte)
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Query per la ricerca testuale
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Interruttore per mostrare o nascondere le spese fisse (affitto, bollette)
final showFixedExpensesProvider = StateProvider<bool>((ref) => true);

/// Interruttore per mostrare o nascondere le spese fuori budget / straordinarie (es. auto, laptop)
final showExtraordinaryExpensesProvider = StateProvider<bool>((ref) => false);

/// Lista delle spese per la cronologia (mostra sempre tutte le spese reali, filtrando per ricerca e categoria)
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  return expensesAsync.maybeWhen(
    data: (expenses) {
      return expenses.where((exp) {
        // Filtro Categoria
        if (selectedCategory != null && exp.categoryId != selectedCategory) {
          return false;
        }

        // Filtro Ricerca
        if (searchQuery.isNotEmpty) {
          final noteMatch = exp.note?.toLowerCase().contains(searchQuery) ?? false;
          final tagMatch = exp.tag?.toLowerCase().contains(searchQuery) ?? false;
          final calcMatch = exp.calculationNote?.toLowerCase().contains(searchQuery) ?? false;
          final amountMatch = exp.amount.toString().contains(searchQuery);
          if (!noteMatch && !tagMatch && !calcMatch && !amountMatch) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
