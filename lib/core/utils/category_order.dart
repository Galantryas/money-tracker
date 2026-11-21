List<Map<String, dynamic>> orderCategories(List<Map<String, dynamic>> categories) {
  bool isOther(Map<String, dynamic> row) =>
      (row['name']?.toString().toLowerCase() ?? '').contains('lain') || row['icon_name'] == 'more_horizontal';
  final indexed = categories.asMap().entries.toList()
    ..sort((a, b) {
      final type = (a.value['type']?.toString() ?? '').compareTo(b.value['type']?.toString() ?? '');
      if (type != 0) return type;
      if (isOther(a.value) != isOther(b.value)) return isOther(a.value) ? 1 : -1;
      return a.key.compareTo(b.key);
    });
  final result = indexed.map((entry) => entry.value).toList();
  final housing = result.where((row) => row['type'] == 'expense' && row['name'] == 'Tempat Tinggal').toList();
  final services = result.indexWhere((row) => row['type'] == 'expense' && row['name'] == 'Layanan');
  if (services >= 0 && housing.isNotEmpty) {
    result.removeWhere((row) => housing.contains(row));
    final position = result.indexWhere((row) => row['type'] == 'expense' && row['name'] == 'Layanan');
    result.insertAll(position + 1, housing);
  }
  return result;
}
