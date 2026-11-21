class Pocket {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final double initialBalance;
  final double? budgetLimit;
  final DateTime createdAt;

  Pocket({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.initialBalance,
    this.budgetLimit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
      'initial_balance': initialBalance,
      'budget_limit': budgetLimit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Pocket.fromMap(Map<String, dynamic> map) {
    return Pocket(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      colorValue: map['color_value'] as int,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      budgetLimit: map['budget_limit'] != null ? (map['budget_limit'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Pocket copyWith({
    String? id,
    String? name,
    String? iconName,
    int? colorValue,
    double? initialBalance,
    double? budgetLimit,
    bool clearBudgetLimit = false,
    DateTime? createdAt,
  }) {
    return Pocket(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      initialBalance: initialBalance ?? this.initialBalance,
      budgetLimit: clearBudgetLimit ? null : budgetLimit ?? this.budgetLimit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
