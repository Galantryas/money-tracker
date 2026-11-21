import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/thousands_separator_input_formatter.dart';

class CategoryBudgetEdit {
  final bool remove;
  final String? amount;
  const CategoryBudgetEdit({this.remove = false, this.amount});
}

Future<CategoryBudgetEdit?> showCategoryBudgetDialog(BuildContext context, String category, double? limit) {
  return showDialog<CategoryBudgetEdit>(context: context,
      builder: (_) => _BudgetDialog(category: category, limit: limit));
}

class _BudgetDialog extends StatefulWidget {
  final String category;
  final double? limit;
  const _BudgetDialog({required this.category, this.limit});
  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.limit == null ? '' : CurrencyFormatter.format(widget.limit!).replaceAll('Rp ', ''));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Batas ${widget.category}'),
      content: SingleChildScrollView(child: Form(key: formKey, child: TextFormField(
        autofocus: true,
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [ThousandsSeparatorInputFormatter()],
        decoration: const InputDecoration(labelText: 'Batas bulanan (Rp)'),
        validator: (value) {
          final amount = CurrencyFormatter.parse(value ?? '');
          return amount.isFinite && amount > 0 ? null : 'Masukkan batas lebih dari nol.';
        },
      ))),
      actions: [
        if (widget.limit != null) TextButton(onPressed: () => Navigator.pop(context, const CategoryBudgetEdit(remove: true)), child: const Text('Hapus batas')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () {
          if (formKey.currentState!.validate()) Navigator.pop(context, CategoryBudgetEdit(amount: controller.text));
        }, child: const Text('Simpan batas')),
      ],
    );
  }
}
