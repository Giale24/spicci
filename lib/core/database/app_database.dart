import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/expense.dart';
import '../../models/recurring_expense.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<void> init() async {
    if (kIsWeb) {
      // Sul Web usiamo SharedPreferences per persistenza locale rapida e compatibile
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spicci.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      final docDir = await getApplicationDocumentsDirectory();
      path = join(docDir.path, filePath);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        tag TEXT,
        note TEXT,
        date TEXT NOT NULL,
        isFixed INTEGER NOT NULL DEFAULT 0,
        isExtraordinary INTEGER NOT NULL DEFAULT 0,
        calculationNote TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        dayOfMonth INTEGER NOT NULL DEFAULT 1,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // --- Operazioni Spese ---

  Future<List<Expense>> getAllExpenses() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('web_expenses') ?? [];
      final list = rawList
          .map((e) => Expense.fromMap(jsonDecode(e)))
          .where((e) =>
              !e.id.startsWith('sample-') &&
              !e.id.startsWith('test-') &&
              !e.id.startsWith('demo-'))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (list.length != rawList.length) {
        final cleanRaw = list.map((e) => jsonEncode(e.toMap())).toList();
        await prefs.setStringList('web_expenses', cleanRaw);
      }
      return list;
    }

    final db = await database;
    await db.delete('expenses',
        where: "id LIKE 'sample-%' OR id LIKE 'test-%' OR id LIKE 'demo-%'");
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllExpenses();
      list.insert(0, expense);
      final rawList = list.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('web_expenses', rawList);
      return;
    }

    final db = await database;
    await db.insert('expenses', expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertExpensesBatch(List<Expense> expenses) async {
    if (expenses.isEmpty) return;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllExpenses();
      final Map<String, Expense> map = {for (var e in list) e.id: e};
      for (var e in expenses) {
        map[e.id] = e;
      }
      final merged = map.values.toList()..sort((a, b) => b.date.compareTo(a.date));
      final rawList = merged.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('web_expenses', rawList);
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final exp in expenses) {
      batch.insert('expenses', exp.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> replaceAllExpenses(List<Expense> expenses) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final sorted = List<Expense>.from(expenses)
        ..sort((a, b) => b.date.compareTo(a.date));
      final rawList = sorted.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('web_expenses', rawList);
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
      final batch = txn.batch();
      for (final exp in expenses) {
        batch.insert('expenses', exp.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> clearAllExpenses() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('web_expenses');
      return;
    }

    final db = await database;
    await db.delete('expenses');
  }

  Future<void> deleteExpense(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllExpenses();
      list.removeWhere((e) => e.id == id);
      final rawList = list.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('web_expenses', rawList);
      return;
    }

    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateExpense(Expense expense) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllExpenses();
      final index = list.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        list[index] = expense;
        final rawList = list.map((e) => jsonEncode(e.toMap())).toList();
        await prefs.setStringList('web_expenses', rawList);
      }
      return;
    }

    final db = await database;
    await db.update('expenses', expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
  }

  // --- Operazioni Spese Ricorrenti ---

  Future<List<RecurringExpense>> getRecurringExpenses() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('web_recurring') ?? [];
      return rawList.map((e) => RecurringExpense.fromMap(jsonDecode(e))).toList();
    }

    final db = await database;
    final maps = await db.query('recurring_expenses');
    return maps.map((map) => RecurringExpense.fromMap(map)).toList();
  }

  Future<void> insertRecurringExpense(RecurringExpense rec) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await getRecurringExpenses();
      list.add(rec);
      final rawList = list.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('web_recurring', rawList);
      return;
    }

    final db = await database;
    await db.insert('recurring_expenses', rec.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRecurringExpense(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await getRecurringExpenses();
      list.removeWhere((e) => e.id == id);
      final rawList = list.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList('web_recurring', rawList);
      return;
    }

    final db = await database;
    await db.delete('recurring_expenses', where: 'id = ?', whereArgs: [id]);
  }
}
