class Expense {
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
      );
}
