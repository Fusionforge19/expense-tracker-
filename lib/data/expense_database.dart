import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class ExpenseDatabase {
  static const _databaseName = 'expense_tracker.db';
  static const _tableName = 'expenses';
  static const _settingsTable = 'settings';
  Database? _database;
  Future<Database>? _databaseFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_databaseFuture != null) return _databaseFuture!;

    final initialization = _openDatabase();
    _databaseFuture = initialization;
    try {
      return await initialization;
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      join(databasesPath, _databaseName),
      version: 2,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE $_settingsTable (
            key TEXT PRIMARY KEY,
            value REAL
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            CREATE TABLE $_settingsTable (
              key TEXT PRIMARY KEY,
              value REAL
            )
          ''');
        }
      },
    );
    return _database!;
  }

  Future<List<Expense>> getExpenses() async {
    final rows = await (await database).query(
      _tableName,
      columns: const ['id', 'title', 'amount', 'category', 'date'],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    return (await database).insert(_tableName, expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    return (await database).delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateExpense(Expense expense) async {
    return (await database).update(
      _tableName,
      expense.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> clearExpenses() async {
    return (await database).delete(_tableName);
  }

  Future<double?> getMonthlyBudget() async {
    final rows = await (await database).query(_settingsTable, where: 'key = ?', whereArgs: ['monthly_budget'], limit: 1);
    final value = rows.firstOrNull?['value'];
    return value is num ? value.toDouble() : null;
  }

  Future<void> setMonthlyBudget(double? amount) async {
    final db = await database;
    if (amount == null) {
      await db.delete(_settingsTable, where: 'key = ?', whereArgs: ['monthly_budget']);
      return;
    }
    await db.insert(_settingsTable, {'key': 'monthly_budget', 'value': amount}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
