class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String? tag;
  final String? note;
  final DateTime date;
  final bool isFixed;
  final bool isExtraordinary; // Spesa straordinaria / una tantum (es. auto, viaggio)
  final String? calculationNote;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.tag,
    this.note,
    required this.date,
    this.isFixed = false,
    this.isExtraordinary = false,
    this.calculationNote,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? tag,
    String? note,
    DateTime? date,
    bool? isFixed,
    bool? isExtraordinary,
    String? calculationNote,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      tag: tag ?? this.tag,
      note: note ?? this.note,
      date: date ?? this.date,
      isFixed: isFixed ?? this.isFixed,
      isExtraordinary: isExtraordinary ?? this.isExtraordinary,
      calculationNote: calculationNote ?? this.calculationNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'tag': tag,
      'note': note,
      'date': date.toIso8601String(),
      'isFixed': isFixed ? 1 : 0,
      'isExtraordinary': isExtraordinary ? 1 : 0,
      'calculationNote': calculationNote,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      tag: map['tag'] as String?,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      isFixed: (map['isFixed'] as int?) == 1,
      isExtraordinary: (map['isExtraordinary'] as int?) == 1,
      calculationNote: map['calculationNote'] as String?,
    );
  }
}
