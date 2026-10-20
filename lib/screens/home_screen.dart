import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Utilities':
        return Icons.bolt_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  List<Expense> _filteredExpenses(List<Expense> expenses) {
    final query = _searchQuery.trim().toLowerCase();
    return expenses.where((expense) {
      final matchesCategory = _categoryFilter == 'All' || expense.category == _categoryFilter;
      final matchesSearch = query.isEmpty || expense.title.toLowerCase().contains(query) || expense.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList(growable: false);
  }

  Future<bool> _confirmDelete(BuildContext context, Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.title}" from your history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await context.read<ExpenseProvider>().deleteExpense(expense);
      return true;
    }
    return false;
  }

  Future<void> _clearAll(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all expenses?'),
        content: const Text('Are you sure you want to clear all expenses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (shouldClear == true && context.mounted) {
      await context.read<ExpenseProvider>().clearAllExpenses();
    }
  }

  Future<void> _editBudget(BuildContext context, double? currentBudget) async {
    final controller = TextEditingController(text: currentBudget?.toStringAsFixed(2) ?? '');
    final budget = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Optional'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, 0), child: const Text('Remove')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted || budget == null) return;
    context.read<ExpenseProvider>().setMonthlyBudget(budget == 0 ? null : budget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpenseTracker', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () => context.read<ExpenseProvider>().loadExpenses(), icon: const Icon(Icons.refresh), tooltip: 'Refresh expenses'),
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = context.read<ExpenseProvider>();
              if (value == 'budget') _editBudget(context, provider.monthlyBudget);
              if (value == 'clear') _clearAll(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'budget', child: Text('Set monthly budget')),
              PopupMenuItem(value: 'clear', child: Text('Clear all expenses')),
            ],
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final expenses = _filteredExpenses(provider.expenses);
          final budget = provider.monthlyBudget;
          final progress = budget == null || budget == 0 ? 0.0 : (provider.monthlyTotal / budget).clamp(0.0, 1.0);
          return RefreshIndicator(
            onRefresh: provider.loadExpenses,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(child: _SummaryCard(total: provider.monthlyTotal, count: provider.expenses.length, budget: budget, progress: progress)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: SliverToBoxAdapter(child: _SearchAndFilter(controller: _searchController, category: _categoryFilter, onSearch: (value) => setState(() => _searchQuery = value), onCategory: (value) => setState(() => _categoryFilter = value))),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  sliver: SliverToBoxAdapter(child: _CategoryBreakdown(totals: provider.categoryTotals, total: provider.total)),
                ),
                if (provider.isLoading)
                  const SliverToBoxAdapter(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())))
                else if (expenses.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return Dismissible(
                          key: ValueKey(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          confirmDismiss: (_) => _confirmDelete(context, expense),
                          child: _ExpenseTile(
                            expense: expense,
                            icon: _categoryIcon(expense.category),
                            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense))),
                            onDelete: () => _confirmDelete(context, expense),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.count, required this.budget, required this.progress});
  final double total;
  final int count;
  final double? budget;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final overBudget = budget != null && total > budget!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: overBudget ? Colors.red.shade700 : const Color(0xFF1D6B5B), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('This month', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontWeight: FontWeight.w600)),
          const Icon(Icons.insights_outlined, color: Color(0xFFB9E5C9)),
        ]),
        const SizedBox(height: 10),
        Text(NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(total), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('$count ${count == 1 ? 'expense' : 'expenses'} recorded${budget == null ? '' : '  •  Budget ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(budget)}'}', style: TextStyle(color: Colors.white.withValues(alpha: .75))),
        if (budget != null) ...[
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white24, color: Colors.white)),
          if (overBudget) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Budget exceeded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ]),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({required this.controller, required this.category, required this.onSearch, required this.onCategory});
  final TextEditingController controller;
  final String category;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    const categories = ['All', 'Food', 'Transport', 'Utilities', 'Entertainment', 'Shopping', 'Other'];
    return Column(children: [
      TextField(controller: controller, onChanged: onSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search expenses', suffixIcon: Icon(Icons.tune), border: OutlineInputBorder())),
      const SizedBox(height: 10),
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final value = categories[index];
            return ChoiceChip(label: Text(value), selected: category == value, onSelected: (_) => onCategory(value));
          },
        ),
      ),
    ]);
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.totals, required this.total});
  final Map<String, double> totals;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const SizedBox.shrink();
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Category breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ...entries.take(4).map((entry) {
        final share = total == 0 ? 0.0 : entry.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(children: [
            Expanded(flex: 2, child: Text(entry.key)),
            Expanded(flex: 5, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: share, minHeight: 7))),
            const SizedBox(width: 8),
            Text('${(share * 100).round()}%'),
          ]),
        );
      }),
    ]);
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.icon, required this.onEdit, required this.onDelete});
  final Expense expense;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(backgroundColor: const Color(0xFFDDF1E3), foregroundColor: const Color(0xFF1D6B5B), child: Icon(icon)),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${expense.category}  •  ${DateFormat('MMM d, yyyy').format(expense.date)}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(expense.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline), tooltip: 'Delete expense'),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_outlined, size: 52, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 12),
      const Text('No expenses found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Tap “Add expense” to start tracking.'),
    ]));
  }
}
