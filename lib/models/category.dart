class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final String type; // 'expense' or 'income'

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
      'type': type,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      colorValue: map['color_value'] as int,
      type: map['type'] as String,
    );
  }
}
