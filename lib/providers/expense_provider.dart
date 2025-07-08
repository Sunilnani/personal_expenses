// lib/providers/expense_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/friend_expense_model.dart';

/// Holds both regular expenses and friend-related expenses & names
class ExpenseProvider extends ChangeNotifier {
  final Directory storageDir;
  static const _expenseFile = 'expenses.json';
  static const _friendExpenseFile = 'friend_expenses.json';
  static const _friendNamesFile = 'friend_names.json';

  List<Expense> _expenses = [];
  List<FriendExpense> _friendExpenses = [];
  List<String> _friendNames = [];

  ExpenseProvider(this.storageDir) {
    _loadExpenses();
    _loadFriendExpenses();
    _loadFriendNames();
  }

  // --- Regular Expenses ---
  List<Expense> get expenses => _expenses;

  double totalFor(ExpenseType type) =>
      _expenses.where((e) => e.type == type).fold(0.0, (sum, e) => sum + e.price);

  List<Expense> monthlyExpenses(ExpenseType type, DateTime month) =>
      _expenses.where((e) => e.type == type && e.date.year == month.year && e.date.month == month.month).toList();

  Future<void> addExpense(Expense e) async {
    _expenses.add(e);
    await _saveExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(Expense oldE, Expense newE) async {
    final idx = _expenses.indexOf(oldE);
    if (idx != -1) {
      _expenses[idx] = newE;
      await _saveExpenses();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(Expense e) async {
    _expenses.remove(e);
    await _saveExpenses();
    notifyListeners();
  }

  Future<void> _loadExpenses() async {
    final file = File('${storageDir.path}/$_expenseFile');
    if (await file.exists()) {
      final data = json.decode(await file.readAsString()) as List<dynamic>;
      _expenses = data.map((j) => Expense.fromJson(j)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveExpenses() async {
    final file = File('${storageDir.path}/$_expenseFile');
    await file.writeAsString(json.encode(_expenses.map((e) => e.toJson()).toList()));
  }

  // --- Friend Names Management ---
  List<String> allFriends() => List.unmodifiable(_friendNames);

  Future<void> addFriend(String name) async {
    if (!_friendNames.contains(name)) {
      _friendNames.add(name);
      await _saveFriendNames();
      notifyListeners();
    }
  }

  Future<void> _loadFriendNames() async {
    final file = File('${storageDir.path}/$_friendNamesFile');
    if (await file.exists()) {
      final data = json.decode(await file.readAsString()) as List<dynamic>;
      _friendNames = data.cast<String>();
      notifyListeners();
    }
  }

  Future<void> _saveFriendNames() async {
    final file = File('${storageDir.path}/$_friendNamesFile');
    await file.writeAsString(json.encode(_friendNames));
  }

  // --- Friend Expenses ---
  List<FriendExpense> get friendExpenses => _friendExpenses;

  double totalFriendsOwed() =>
      _friendExpenses.fold(0.0, (sum, e) => sum + e.amount);

  List<FriendTotal> friendsWithTotals() {
    // include all friend names, even with zero
    final totals = { for (var n in _friendNames) n: 0.0 };
    for (var e in _friendExpenses) {
      totals[e.name] = (totals[e.name] ?? 0) + e.amount;
    }
    return totals.entries.map((e) => FriendTotal(e.key, e.value)).toList();
  }

  List<FriendExpense> expensesForFriend(String name) =>
      _friendExpenses.where((e) => e.name == name).toList();

  Future<void> addFriendExpense(FriendExpense e) async {
    // ensure friend exists
    if (!_friendNames.contains(e.name)) {
      _friendNames.add(e.name);
      await _saveFriendNames();
    }
    _friendExpenses.add(e);
    await _saveFriendExpenses();
    notifyListeners();
  }

  Map<String, double> categoryTotals(ExpenseType type) {
    final totals = <String, double>{};
    for (final e in _expenses) {              // assuming your list is named `_expenses`
      if (e.type == type) {
        totals.update(
          e.category,
              (prev) => prev + e.price,
          ifAbsent: () => e.price,
        );
      }
    }
    return totals;
  }

  Future<void> _loadFriendExpenses() async {
    final file = File('${storageDir.path}/$_friendExpenseFile');
    if (await file.exists()) {
      final data = json.decode(await file.readAsString()) as List<dynamic>;
      _friendExpenses = data.map((j) => FriendExpense.fromJson(j)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveFriendExpenses() async {
    final file = File('${storageDir.path}/$_friendExpenseFile');
    await file.writeAsString(json.encode(_friendExpenses.map((e) => e.toJson()).toList()));
  }
}