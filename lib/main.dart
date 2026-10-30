import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializzazione localizzazione italiana per date
  await initializeDateFormatting('it_IT', null);

  // Inizializzazione database (SQLite FFI su desktop/mobile)
  await AppDatabase.instance.init();

  runApp(
    const ProviderScope(
      child: SpicciApp(),
    ),
  );
}

class SpicciApp extends ConsumerWidget {
  const SpicciApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePalette = ref.watch(themeProvider);

    return MaterialApp(
      key: ValueKey(activePalette.id),
      title: 'Spicci',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(activePalette),
      home: const MainNavigationScreen(),
    );
  }
}
