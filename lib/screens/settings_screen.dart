import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/csv_import_helper.dart';
import '../core/utils/currency_utils.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../providers/expenses_provider.dart';
import '../core/utils/file_download_helper.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _editMonthlyBudget() {
    final currentBudget = ref.read(monthlyBudgetProvider);
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Imposta Budget Mensile',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questo importo serve a Spicci per calcolare quanto puoi spendere ogni giorno.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              autofocus: true,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.purpleLight),
              decoration: InputDecoration(
                prefixText: '€ ',
                prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.purpleLight),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.purple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newBudget = double.tryParse(controller.text) ?? currentBudget;
              if (newBudget > 0) {
                ref.read(monthlyBudgetProvider.notifier).setBudget(newBudget);
              }
              Navigator.pop(context);
            },
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportCSV() {
    final expenses = ref.read(expensesProvider).value ?? [];
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun dato registrato da esportare.')),
      );
      return;
    }

    final now = DateTime.now();
    final fileName = 'spicci_export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('ID;Data;Ora;Categoria;Tag;Importo;Fissa;FuoriBudget;Nota;DettaglioCalcolo');

    for (final e in expenses) {
      final dateStr =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}';
      final catName = Category.byId(e.categoryId).name;
      buffer.writeln(
          '${e.id};$dateStr;$timeStr;$catName;${e.tag ?? ""};${e.amount.toStringAsFixed(2)};${e.isFixed ? "SI" : "NO"};${e.isExtraordinary ? "SI" : "NO"};"${e.note ?? ""}";"${e.calculationNote ?? ""}');
    }

    final csvText = buffer.toString();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.purpleLight, size: 24),
            SizedBox(width: 8),
            Text('Esportazione CSV', style: TextStyle(fontSize: 18, color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anteprima delle tue ${expenses.length} transazioni pronte per Excel o Google Fogli:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvText,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copia'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiato negli appunti!')),
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('SCARICA FILE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await saveCsvFile(csvText, fileName);
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
                        const SizedBox(width: 8),
                        Text('File scaricato: $fileName'),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importCSV() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (file == null) {
        return; // Utente ha annullato
      }

      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);

      if (content.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il file CSV selezionato è vuoto.')),
        );
        return;
      }

      final imported = CsvImportHelper.parseExpenses(content);

      if (imported.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nessuna spesa valida trovata nel file. Verifica le colonne (Data, Categoria, Importo).',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      _showImportDialog(imported, file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e')),
      );
    }
  }

  void _showImportDialog(List<Expense> imported, String fileName) {
    bool replaceAll = false;
    final totalAmount = imported.fold<double>(0.0, (sum, e) => sum + e.amount);

    DateTime earliest = imported.first.date;
    DateTime latest = imported.first.date;
    for (final e in imported) {
      if (e.date.isBefore(earliest)) earliest = e.date;
      if (e.date.isAfter(latest)) latest = e.date;
    }

    final dateRangeStr =
        '${earliest.day.toString().padLeft(2, '0')}/${earliest.month.toString().padLeft(2, '0')}/${earliest.year} - ${latest.day.toString().padLeft(2, '0')}/${latest.month.toString().padLeft(2, '0')}/${latest.year}';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.file_upload_outlined, color: AppColors.cyan, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Importa da CSV',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('File:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            fileName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transazioni:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          '${imported.length} spese',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Totale importo:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          CurrencyUtils.format(totalAmount),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.mint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Periodo:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          dateRangeStr,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Modalità di importazione:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setDialogState(() => replaceAll = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: !replaceAll ? AppColors.cyan.withValues(alpha: 0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !replaceAll ? AppColors.cyan : AppColors.border,
                      width: !replaceAll ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !replaceAll ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: !replaceAll ? AppColors.cyan : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aggiungi alle spese esistenti',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !replaceAll ? FontWeight.bold : FontWeight.w500,
                                color: !replaceAll ? AppColors.cyan : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Mantiene le spese attuali e aggiunge le nuove',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setDialogState(() => replaceAll = true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: replaceAll ? AppColors.red.withValues(alpha: 0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: replaceAll ? AppColors.red : AppColors.border,
                      width: replaceAll ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        replaceAll ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: replaceAll ? AppColors.red : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sostituisci tutte le spese',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: replaceAll ? FontWeight.bold : FontWeight.w500,
                                color: replaceAll ? AppColors.red : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Cancella le spese correnti e carica solo il file',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: replaceAll ? AppColors.red : AppColors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final count = await ref
                      .read(expensesProvider.notifier)
                      .importExpenses(imported, replaceAll: replaceAll);

                  HapticFeedback.mediumImpact();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            replaceAll
                                ? '$count spese caricate (archivio sostituito)!'
                                : '$count spese importate con successo!',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Errore importazione: $e')),
                  );
                }
              },
              child: Text(
                'IMPORTA (${imported.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAllExpenses() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded, color: AppColors.red, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Elimina tutte le spese',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare definitivamente tutte le spese registrate?\n\nL\'archivio tornerà vuoto e questa operazione non potrà essere annullata.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(expensesProvider.notifier).clearAllExpenses();
                HapticFeedback.heavyImpact();
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Tutte le spese sono state eliminate con successo.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                );
              }
            },
            child: const Text('ELIMINA TUTTO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBudget = ref.watch(monthlyBudgetProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Salvadanaio Dati'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sezione Tutorial
          Material(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.school_rounded, color: AppColors.purpleLight, size: 22),
                ),
                title: Text(
                  'Tutorial & Guida di Spicci',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Rivedi la regola dei 3 tocchi e il dividi-conto',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                onTap: () {
                  TutorialScreen.showAsModal(context);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sezione Budget
          Material(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.goldCoin.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.monetization_on_rounded, color: AppColors.goldCoin, size: 22),
                ),
                title: Text(
                  'Budget Mensile Desiderato',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Attuale: ${CurrencyUtils.format(currentBudget)} / mese',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                onTap: _editMonthlyBudget,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sezione Esportazione & Privacy
          Material(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.file_download_outlined, color: AppColors.purpleLight, size: 22),
                    ),
                    title: Text(
                      'Esporta in CSV / Excel',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Esporta tutte le spese in un file o negli appunti',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: _exportCSV,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.file_upload_outlined, color: AppColors.cyan, size: 22),
                    ),
                    title: Text(
                      'Importa da CSV',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Carica un file CSV di spese esportato da Spicci o Excel',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: _importCSV,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_sweep_rounded, color: AppColors.red, size: 22),
                    ),
                    title: Text(
                      'Elimina tutte le spese',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.red),
                    ),
                    subtitle: Text(
                      'Cancella definitivamente tutto l\'archivio delle spese',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: _confirmClearAllExpenses,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.lock_outline_rounded, color: AppColors.cyan, size: 22),
                    ),
                    title: Text(
                      '100% Locale e Offline',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Nessun dato viene mai inviato a server esterni.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Info App con moneta
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.goldCoin.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldCoin.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.monetization_on_rounded, color: AppColors.goldCoin, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  'Spicci',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Segna le spese in un lampo • v1.0.0',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
