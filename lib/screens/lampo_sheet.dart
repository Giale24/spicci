import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_utils.dart';
import '../core/utils/date_utils.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import 'widgets/category_grid.dart';
import 'widgets/custom_keypad.dart';
import 'widgets/smart_tags_bar.dart';

class LampoSheet extends ConsumerStatefulWidget {
  final Expense? initialExpense; // Se fornito, è in modalità modifica

  const LampoSheet({super.key, this.initialExpense});

  static Future<void> show(BuildContext context, {Expense? expense}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => LampoSheet(initialExpense: expense),
    );
  }

  @override
  ConsumerState<LampoSheet> createState() => _LampoSheetState();
}

class _LampoSheetState extends ConsumerState<LampoSheet> {
  String _amountInput = '';
  String? _divisorInput; // Per il dividi-conto (tasto ÷)
  bool _isDividing = false;

  String _selectedCategoryId = 'cibo';
  String? _selectedTag;
  late DateTime _selectedDate;
  bool _isFixed = false;
  bool _isExtraordinary = false;

  bool _isNoteFieldVisible = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      final exp = widget.initialExpense!;
      _amountInput = exp.amount.toStringAsFixed(2).replaceAll('.', ',');
      _selectedCategoryId = exp.categoryId;
      _selectedTag = exp.tag;
      _selectedDate = exp.date;
      _isFixed = exp.isFixed;
      _isExtraordinary = exp.isExtraordinary;
      if (exp.note != null && exp.note!.isNotEmpty) {
        _noteController.text = exp.note!;
        _isNoteFieldVisible = true;
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _calculatedAmount {
    if (_amountInput.isEmpty) return 0.0;
    final normalized = _amountInput.replaceAll(',', '.');
    final base = double.tryParse(normalized) ?? 0.0;

    if (_isDividing && _divisorInput != null && _divisorInput!.isNotEmpty) {
      final divisor = double.tryParse(_divisorInput!) ?? 1.0;
      if (divisor > 0) {
        return base / divisor;
      }
    }
    return base;
  }

  void _onDigit(String digit) {
    setState(() {
      if (_isDividing) {
        // Stiamo inserendo il divisore (es. per quante persone dividere)
        if (_divisorInput == null) {
          if (digit != '0' && digit != ',') {
            _divisorInput = digit;
          }
        } else if (_divisorInput!.length < 2) {
          _divisorInput = '$_divisorInput$digit';
        }
      } else {
        if (digit == ',') {
          if (!_amountInput.contains(',')) {
            _amountInput = _amountInput.isEmpty ? '0,' : '$_amountInput,';
          }
        } else {
          // Limita i decimali a 2 cifre
          if (_amountInput.contains(',')) {
            final parts = _amountInput.split(',');
            if (parts.length > 1 && parts[1].length >= 2) return;
          }
          if (_amountInput == '0') {
            _amountInput = digit;
          } else {
            _amountInput = '$_amountInput$digit';
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_isDividing) {
        if (_divisorInput != null && _divisorInput!.isNotEmpty) {
          _divisorInput = _divisorInput!.substring(0, _divisorInput!.length - 1);
          if (_divisorInput!.isEmpty) _divisorInput = null;
        } else {
          _isDividing = false;
        }
      } else {
        if (_amountInput.isNotEmpty) {
          _amountInput = _amountInput.substring(0, _amountInput.length - 1);
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      _amountInput = '';
      _divisorInput = null;
      _isDividing = false;
    });
  }

  void _onDivide() {
    if (_amountInput.isEmpty) return;
    setState(() {
      _isDividing = !_isDividing;
      if (!_isDividing) {
        _divisorInput = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.mint,
              onPrimary: Colors.black,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _submit() {
    final amount = _calculatedAmount;
    if (amount <= 0) return;

    String? calcNote;
    if (_isDividing && _divisorInput != null) {
      calcNote = '$_amountInput€ ÷ $_divisorInput persone';
    }

    final expense = Expense(
      id: widget.initialExpense?.id ?? const Uuid().v4(),
      amount: amount,
      categoryId: _selectedCategoryId,
      tag: _selectedTag,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      date: _selectedDate,
      isFixed: _isFixed,
      isExtraordinary: _isExtraordinary,
      calculationNote: calcNote,
    );

    if (widget.initialExpense != null) {
      ref.read(expensesProvider.notifier).updateExpense(expense);
    } else {
      ref.read(expensesProvider.notifier).addExpense(expense);
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.initialExpense != null
                  ? 'Spesa aggiornata in un lampo!'
                  : 'Spesa segnata in un lampo! (${CurrencyUtils.format(amount)})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialExpense != null;
    final canSubmit = _calculatedAmount > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superiore: Titolo e Data Intelligente
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Modifica Spesa' : 'Quanto hai speso?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Selettori data rapidi
                  Row(
                    children: [
                      // Chip rapido Oggi / Ieri
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (AppDateUtils.isToday(_selectedDate)) {
                              _selectedDate = DateTime.now().subtract(const Duration(days: 1));
                            } else {
                              _selectedDate = DateTime.now();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: AppColors.mint),
                              const SizedBox(width: 4),
                              Text(
                                AppDateUtils.isToday(_selectedDate) ? 'Oggi' : 'Ieri',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Calendario per altra data
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Display cifra enorme con feedback interattivo
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _amountInput.isNotEmpty ? AppColors.purple.withValues(alpha: 0.5) : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _amountInput.isEmpty ? '0,00' : _amountInput,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: _amountInput.isEmpty ? AppColors.textMuted : AppColors.purpleLight,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '€',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lilac,
                        ),
                      ),
                    ],
                  ),
                  // Se la divisione conto è attiva (es. 80 ÷ 4 = 20,00 €)
                  if (_isDividing)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Dividi conto per ${_divisorInput ?? "?"} persone  →  ${CurrencyUtils.format(_calculatedAmount)} a testa',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amberLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Campo nota testuale facoltativo (aperto solo con "+ Nota")
            if (_isNoteFieldVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _noteController,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Aggiungi un dettaglio specifico (es. con Marco)...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.purple),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // Barra opzioni categoria e inserimento Badge Spesa Fissa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Categoria',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  // Inserimento Badge Spesa Fissa
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isFixed = !_isFixed;
                        if (_isFixed) _isExtraordinary = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isFixed
                            ? AppColors.goldCoin.withValues(alpha: 0.18)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isFixed ? AppColors.goldCoin : AppColors.border,
                          width: _isFixed ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFixed ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            size: 13,
                            color: _isFixed ? AppColors.goldCoin : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isFixed ? 'Fissa: SI' : '+ Fissa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _isFixed ? FontWeight.bold : FontWeight.w500,
                              color: _isFixed ? AppColors.goldCoin : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Inserimento Badge Spesa Straordinaria / Fuori Budget (es. auto, laptop, trasloco)
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isExtraordinary = !_isExtraordinary;
                        if (_isExtraordinary) _isFixed = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isExtraordinary
                            ? AppColors.cyan.withValues(alpha: 0.18)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isExtraordinary ? AppColors.cyan : AppColors.border,
                          width: _isExtraordinary ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExtraordinary ? Icons.diamond_rounded : Icons.diamond_outlined,
                            size: 13,
                            color: _isExtraordinary ? AppColors.cyan : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExtraordinary ? 'Fuori Budget: SI' : '+ Fuori Budget',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _isExtraordinary ? FontWeight.bold : FontWeight.w500,
                              color: _isExtraordinary ? AppColors.cyan : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Griglia Categorie (Tocco 2)
            CategoryGrid(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (catId) {
                setState(() {
                  _selectedCategoryId = catId;
                  _selectedTag = null; // reset tag se cambio categoria
                });
              },
            ),

            const SizedBox(height: 8),

            // Barra Smart Tag (Addio tastiera)
            SmartTagsBar(
              categoryId: _selectedCategoryId,
              selectedTag: _selectedTag,
              isNoteFieldVisible: _isNoteFieldVisible,
              onToggleNoteField: () {
                setState(() {
                  _isNoteFieldVisible = !_isNoteFieldVisible;
                });
              },
              onTagSelected: (tag) {
                setState(() {
                  _selectedTag = tag;
                });
              },
            ),

            const SizedBox(height: 6),

            // Tastierino Numerico (Tocco 1 e Tocco 3)
            CustomKeypad(
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              onClearPressed: _onClear,
              onDividePressed: _onDivide,
              onSubmitPressed: _submit,
              canSubmit: canSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
