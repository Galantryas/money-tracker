import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/thousands_separator_input_formatter.dart';
import '../../models/pocket.dart';
import '../../providers/pocket_provider.dart';

class PocketFormDialog extends ConsumerStatefulWidget {
  final Pocket? initialPocket;

  const PocketFormDialog({super.key, this.initialPocket});

  @override
  ConsumerState<PocketFormDialog> createState() => _PocketFormDialogState();
}

class _PocketFormDialogState extends ConsumerState<PocketFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _budgetController;

  late String _selectedIcon;
  late int _selectedColor;

  bool get _isEditing => widget.initialPocket != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPocket;
    _nameController = TextEditingController(text: p?.name ?? '');
    _balanceController = TextEditingController(
      text: p != null
          ? CurrencyFormatter.format(p.initialBalance).replaceAll('Rp ', '')
          : '',
    );
    _budgetController = TextEditingController(
      text: p?.budgetLimit != null
          ? CurrencyFormatter.format(p!.budgetLimit!).replaceAll('Rp ', '')
          : '',
    );

    _selectedIcon = p?.iconName ?? 'wallet';
    _selectedColor = p?.colorValue ?? IconHelper.availableColors.first.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final initialBalance = CurrencyFormatter.parse(_balanceController.text);
    final budgetLimitText = _budgetController.text.trim();
    final budgetLimit = budgetLimitText.isNotEmpty ? CurrencyFormatter.parse(budgetLimitText) : null;

    if (_isEditing) {
      final updated = widget.initialPocket!.copyWith(
        name: _nameController.text.trim(),
        iconName: _selectedIcon,
        colorValue: _selectedColor,
        initialBalance: initialBalance,
        budgetLimit: budgetLimit,
      );
      await ref.read(pocketProvider.notifier).updatePocket(updated);
    } else {
      final newPocket = Pocket(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        iconName: _selectedIcon,
        colorValue: _selectedColor,
        initialBalance: initialBalance,
        budgetLimit: budgetLimit,
        createdAt: DateTime.now(),
      );
      await ref.read(pocketProvider.notifier).addPocket(newPocket);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Kantong' : 'Buat Kantong Baru',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nama Kantong
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kantong',
                    hintText: 'Misal: Tabungan Liburan, Jajan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama kantong tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Saldo Awal
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: _isEditing ? 'Saldo Dasar' : 'Saldo Awal',
                    hintText: '0',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Batas Pengeluaran (Budget Limit)
                TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Batas Belanja Bulanan (Opsional)',
                    hintText: 'Kosongkan jika tidak dibatasi',
                    prefixText: 'Rp ',
                    helperText: 'Akan muncul indikator progres budget di dashboard',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 20),

                // Pilih Ikon
                Text('Pilih Ikon', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: IconHelper.availableIcons.length,
                    itemBuilder: (context, index) {
                      final opt = IconHelper.availableIcons[index];
                      final isSelected = _selectedIcon == opt.key;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIcon = opt.key;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(_selectedColor).withOpacity(0.2)
                                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Color(_selectedColor) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            opt.icon,
                            color: isSelected ? Color(_selectedColor) : (isDark ? Colors.white70 : Colors.black87),
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Pilih Warna
                Text('Pilih Warna', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: IconHelper.availableColors.map((color) {
                      final isSelected = _selectedColor == color.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color.value;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    if (_isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Hapus Kantong',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Kantong?'),
                              content: const Text(
                                'Semua riwayat transaksi pada kantong ini juga akan dihapus. Lanjutkan?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref.read(pocketProvider.notifier).deletePocket(widget.initialPocket!.id);
                            if (mounted) Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(_isEditing ? 'Simpan' : 'Buat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
