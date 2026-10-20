// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:expense_tracker/data/expense_database.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';

void main() {
  testWidgets('ExpenseTracker app renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ExpenseProvider(_TestExpenseDatabase()),
        child: const ExpenseTrackerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('ExpenseTracker'), findsOneWidget);
    expect(find.text('No expenses found'), findsOneWidget);
  });
}

class _TestExpenseDatabase extends ExpenseDatabase {
  @override
  Future<List<Expense>> getExpenses() async => [];
}
