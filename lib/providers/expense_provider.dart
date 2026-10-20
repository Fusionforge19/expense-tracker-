import 'package:flutter/foundation.dart';

import '../data/expense_database.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._database) {
    loadExpenses();
  }

  static const _databaseTimeout = Duration(seconds: 3);
  final ExpenseDatabase _database;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  bool _isLoadingFromDatabase = false;
  bool _persistenceAvailable = true;
  int _nextLocalId = -1;
  double? _monthlyBudget;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  double get total => _expenses.fold(0, (sum, expense) => sum + expense.amount);
  double? get monthlyBudget => _monthlyBudget;

  double get monthlyTotal {
    final now = DateTime.now();
    return _expenses
        .where((expense) => expense.date.year == now.year && expense.date.month == now.month)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final expense in _expenses) {
      totals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }
    return totals;
  }

  Future<void> loadExpenses() async {
    if (_isLoadingFromDatabase) return;
    _isLoadingFromDatabase = true;
    try {
      final results = await Future.wait([
        _database.getExpenses(),
        _database.getMonthlyBudget(),
      ]).timeout(_databaseTimeout);
      final expenses = results[0] as List<Expense>;
      _expenses = expenses;
      _monthlyBudget = results[1] as double?;
      _persistenceAvailable = true;
    } catch (_) {
      // Keep the cached list usable when SQLite is unavailable or slow.
      _persistenceAvailable = false;
    } finally {
      _isLoadingFromDatabase = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    int id;
    if (_persistenceAvailable) {
      try {
        id = await _database.insertExpense(expense).timeout(_databaseTimeout);
      } catch (_) {
        _persistenceAvailable = false;
        id = _nextLocalId--;
      }
    } else {
      id = _nextLocalId--;
    }
    final savedExpense = Expense(
      id: id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
    );
    _expenses = [savedExpense, ..._expenses];
    notifyListeners();
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    if (_persistenceAvailable && expense.id! > 0) {
      try {
        await _database.deleteExpense(expense.id!).timeout(_databaseTimeout);
      } catch (_) {
        _persistenceAvailable = false;
      }
    }
    _expenses = _expenses.where((item) => item.id != expense.id).toList();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    if (_persistenceAvailable && expense.id! > 0) {
      try {
        await _database.updateExpense(expense).timeout(_databaseTimeout);
      } catch (_) {
        _persistenceAvailable = false;
      }
    }
    _expenses = [
      for (final item in _expenses) item.id == expense.id ? expense : item,
    ];
    notifyListeners();
  }

  Future<void> clearAllExpenses() async {
    if (_persistenceAvailable) {
      try {
        await _database.clearExpenses().timeout(_databaseTimeout);
      } catch (_) {
        _persistenceAvailable = false;
      }
    }
    _expenses = [];
    notifyListeners();
  }

  void setMonthlyBudget(double? amount) {
    _monthlyBudget = amount;
    notifyListeners();
    _saveMonthlyBudget(amount);
  }

  Future<void> _saveMonthlyBudget(double? amount) async {
    if (!_persistenceAvailable) return;
    try {
      await _database.setMonthlyBudget(amount).timeout(_databaseTimeout);
    } catch (_) {
      _persistenceAvailable = false;
    }
  }
}
