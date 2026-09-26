/// Operational expense entity for rent, utilities, freight, tea, packaging, and shop overhead
class Expense {
  final int? id;
  final String title;
  final String? category;
  final double amount;
  final String expenseDate;
  final String? paymentMethod;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  const Expense({
    this.id,
    required this.title,
    this.category,
    required this.amount,
    required this.expenseDate,
    this.paymentMethod,
    this.notes,
    this.createdAt = '',
    this.updatedAt,
  });

  /// Factory constructor to deserialize an [Expense] from SQLite row map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String?,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: map['expense_date'] as String,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Converts this [Expense] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [Expense] with updated values
  Expense copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    String? expenseDate,
    String? paymentMethod,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, title: $title, amount: $amount, category: $category, date: $expenseDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amount == other.amount;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ amount.hashCode;
}
