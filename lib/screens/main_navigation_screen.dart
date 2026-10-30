import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import 'analytics_screen.dart';
import 'lampo_sheet.dart';
import 'overview_screen.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';

import '../providers/theme_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    OverviewScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunchTutorial();
  }

  Future<void> _checkFirstLaunchTutorial() async {
    final shouldShow = await TutorialScreen.shouldShowTutorial();
    if (shouldShow && mounted) {
      // Breve ritardo per permettere al frame iniziale di caricare fluidamente
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        TutorialScreen.showAsModal(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text(
          'SEGNA',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
        onPressed: () {
          LampoSheet.show(context);
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: activeTheme.isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.purple.withValues(alpha: activeTheme.isDark ? 0.25 : 0.15),
              selectedIndex: _currentIndex,
              elevation: 0,
              height: 60,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.purple),
                  label: 'Spese',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline_rounded, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.pie_chart_rounded, color: AppColors.purple),
                  label: 'Analisi',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.purple),
                  label: 'Salvadanaio',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
