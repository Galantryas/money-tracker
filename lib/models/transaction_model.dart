class TransactionModel {
  final String id;
  final String pocketId;
  final String? targetPocketId;
  final String type; // 'expense', 'income', 'transfer'
  final double amount;
  final String category;
  final String note;
  final String merchant;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.pocketId,
    this.targetPocketId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.merchant,
    required this.date,
    required this.createdAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pocket_id': pocketId,
      'target_pocket_id': targetPocketId,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      pocketId: map['pocket_id'] as String,
      targetPocketId: map['target_pocket_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String,
      merchant: map['merchant'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? pocketId,
    String? targetPocketId,
    String? type,
    double? amount,
    String? category,
    String? note,
    String? merchant,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      pocketId: pocketId ?? this.pocketId,
      targetPocketId: targetPocketId ?? this.targetPocketId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
