class RecurringExpense {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final int dayOfMonth;
  final bool isActive;

  const RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.dayOfMonth = 1,
    this.isActive = true,
  });

  RecurringExpense copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    int? dayOfMonth,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'dayOfMonth': dayOfMonth,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory RecurringExpense.fromMap(Map<String, dynamic> map) {
    return RecurringExpense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      dayOfMonth: (map['dayOfMonth'] as int?) ?? 1,
      isActive: (map['isActive'] as int?) != 0,
    );
  }
}
