import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/category.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/filter_provider.dart';

class DonutChartWidget extends ConsumerStatefulWidget {
  const DonutChartWidget({super.key});

  @override
  ConsumerState<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends ConsumerState<DonutChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final selectedFilterCategory = ref.watch(selectedCategoryFilterProvider);
    final showFixed = ref.watch(showFixedExpensesProvider);
    final showExtraordinary = ref.watch(showExtraordinaryExpensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        // Filtriamo le spese del mese corrente
        final now = DateTime.now();
        final monthExpenses = expenses.where((e) {
          if (!showFixed && e.isFixed) return false;
          if (!showExtraordinary && e.isExtraordinary) return false;
          return e.date.year == now.year && e.date.month == now.month;
        }).toList();

        if (monthExpenses.isEmpty) {
          return Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Nessuna spesa registrata questo mese.\nUsa il tasto SEGNA per cominciare!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          );
        }

        // Raggruppamento per categoria
        final Map<String, double> totalsByCategory = {};
        double grandTotal = 0;
        for (final exp in monthExpenses) {
          totalsByCategory[exp.categoryId] = (totalsByCategory[exp.categoryId] ?? 0) + exp.amount;
          grandTotal += exp.amount;
        }

        final sortedCategories = totalsByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Determina la categoria attiva (selezionata o toccata)
        Category? activeCategory;
        double activeAmount = 0.0;
        if (selectedFilterCategory != null) {
          activeCategory = Category.byId(selectedFilterCategory);
          activeAmount = totalsByCategory[selectedFilterCategory] ?? 0.0;
        } else if (_touchedIndex >= 0 && _touchedIndex < sortedCategories.length) {
          final entry = sortedCategories[_touchedIndex];
          activeCategory = Category.byId(entry.key);
          activeAmount = entry.value;
        }

        final List<PieChartSectionData> sections = [];
        for (int i = 0; i < sortedCategories.length; i++) {
          final entry = sortedCategories[i];
          final cat = Category.byId(entry.key);
          final isSelected = selectedFilterCategory == entry.key;
          final isTouched = i == _touchedIndex || isSelected;

          // Dimensioni calibrate per evitare qualsiasi overflow o compenetrazione
          final radius = isTouched ? 30.0 : 24.0;

          sections.add(
            PieChartSectionData(
              color: cat.color,
              value: entry.value,
              showTitle: false, // I dettagli appaiono fluidamente al centro
              radius: radius,
            ),
          );
        }

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
              // Header del grafico
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spese per Categoria',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (selectedFilterCategory != null)
                    GestureDetector(
                      onTap: () {
                        ref.read(selectedCategoryFilterProvider.notifier).state = null;
                        setState(() => _touchedIndex = -1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.purple),
                        ),
                        child: Row(
                          children: [
                            Text(
                              Category.byId(selectedFilterCategory).name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.purpleLight,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close_rounded, size: 13, color: AppColors.purpleLight),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      'Tocca una fetta per filtrare',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Grafico a ciambella e legenda rapida
              Row(
                children: [
                  // Ciambella fl_chart con centro intelligente anti-compenetrazione
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    return;
                                  }
                                  final touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                  if (touchedIndex >= 0 &&
                                      touchedIndex < sortedCategories.length) {
                                    _touchedIndex = touchedIndex;
                                    final catId = sortedCategories[touchedIndex].key;
                                    final current = ref.read(selectedCategoryFilterProvider);
                                    ref.read(selectedCategoryFilterProvider.notifier).state =
                                        current == catId ? null : catId;
                                  }
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 48,
                            sections: sections,
                          ),
                        ),
                        // Centro della ciambella: mostra categoria toccata o totale
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: activeCategory != null
                              ? Column(
                                  key: ValueKey(activeCategory.id),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      activeCategory.icon,
                                      size: 20,
                                      color: activeCategory.color,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activeCategory.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: activeCategory.color,
                                      ),
                                    ),
                                    Text(
                                      CurrencyUtils.formatCompact(activeAmount),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('total'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      CurrencyUtils.formatCompact(grandTotal),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Totale Mese',
                                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legenda Categorie Top
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedCategories.take(4).map((entry) {
                        final cat = Category.byId(entry.key);
                        final isSelected = selectedFilterCategory == entry.key;
                        final percentage = grandTotal > 0 ? (entry.value / grandTotal) * 100 : 0.0;

                        return InkWell(
                          onTap: () {
                            final current = ref.read(selectedCategoryFilterProvider);
                            ref.read(selectedCategoryFilterProvider.notifier).state =
                                current == entry.key ? null : entry.key;
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: cat.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? AppColors.purpleLight : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.format(entry.value),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.purpleLight : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
