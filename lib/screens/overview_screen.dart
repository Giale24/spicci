import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/category.dart';
import '../providers/filter_provider.dart';
import 'tutorial_screen.dart';
import 'widgets/chronological_expense_list.dart';
import 'widgets/daily_budget_banner.dart';
import 'widgets/monthly_summary_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/theme_picker_sheet.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedFilterCategory = ref.watch(selectedCategoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            // Icona della moneta richiesta al posto del fulmine
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.goldCoin.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.goldCoin.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldCoin.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                color: AppColors.goldCoin,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SpicciTrack',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Tasto rapido per cambiare tema e colori
          IconButton(
            icon: Icon(Icons.palette_outlined, color: AppColors.purpleLight),
            tooltip: 'Temi & Colori',
            onPressed: () {
              ThemePickerSheet.show(context);
            },
          ),
          // Tasto rapido per aprire il tutorial
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: AppColors.purpleLight),
            tooltip: 'Tutorial dell\'app',
            onPressed: () {
              TutorialScreen.showAsModal(context);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cruscotto Mensile
            MonthlySummaryCard(
              onOpenSettings: () {
                // Naviga al tab Salvadanaio se desiderato o apre sheet
              },
            ),

            const SizedBox(height: 12),

            // 2. Budget Giornaliero Dinamico
            const DailyBudgetBanner(),

            const SizedBox(height: 16),

            // 3. Barra di ricerca e chip filtro categoria attivo
            Row(
              children: [
                const Expanded(child: SearchBarWidget()),
                if (selectedFilterCategory != null) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                    side: BorderSide(color: AppColors.purple),
                    avatar: Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.purpleLight),
                    label: Text(
                      Category.byId(selectedFilterCategory).name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.purpleLight,
                      ),
                    ),
                    onPressed: () {
                      ref.read(selectedCategoryFilterProvider.notifier).state = null;
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // 5. Lista Cronologica con totale per giorno e swipe elimina/modifica
            const ChronologicalExpenseList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
