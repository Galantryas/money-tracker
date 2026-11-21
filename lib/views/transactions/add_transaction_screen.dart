import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/async_action_guard.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/thousands_separator_input_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/balance_privacy_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? preselectedPocketId;
  final TransactionModel? initialTransaction;
  final String? initialType;

  const AddTransactionScreen({
    super.key,
    this.preselectedPocketId,
    this.initialTransaction,
    this.initialType,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saveGuard = AsyncActionGuard();

  late String _type; // 'expense' or 'income'
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _merchantController;

  PageController? _pocketPageController;
  int _currentPocketIndex = 0;

  String? _selectedPocketId;
  String? _selectedCategory;
  late DateTime _selectedDate;

  bool get _isEditing => widget.initialTransaction != null;

  final List<String> _commonMerchants = [
    'Gofood',
    'Gojek',
    'Shopee',
    'Astro',
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;

    _type = tx?.type ?? widget.initialType ?? 'expense';
    _amountController = TextEditingController(
      text: tx != null
          ? CurrencyFormatter.format(tx.amount).replaceAll('Rp ', '')
          : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _merchantController = TextEditingController(text: tx?.merchant ?? '');
    _selectedPocketId = tx?.pocketId ?? widget.preselectedPocketId;
    _selectedCategory = tx?.category;
    _selectedDate = tx?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    _pocketPageController?.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }

  String _formatDisplayDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hari Ini';
    }
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  void _showPocketPickerSheet(List<PocketWithBalance> pockets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Kantong',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pockets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pwb = pockets[index];
                      final isSelected = pwb.pocket.id == _selectedPocketId;
                      final color = Color(pwb.pocket.colorValue);

                      return InkWell(
                        onTap: () {
                          final targetIdx = pockets.indexWhere((p) => p.pocket.id == pwb.pocket.id);
                          setState(() {
                            _selectedPocketId = pwb.pocket.id;
                            if (targetIdx >= 0) {
                              _currentPocketIndex = targetIdx;
                              if (_pocketPageController?.hasClients == true) {
                                _pocketPageController!.animateToPage(
                                  targetIdx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(IconHelper.getIcon(pwb.pocket.iconName), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pwb.pocket.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(CurrencyFormatter.privateAmount(pwb.currentBalance, isVisible: ref.read(balancePrivacyProvider)),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: color, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPickerSheet(List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Kategori ${_type == 'expense' ? 'Pengeluaran' : 'Pemasukan'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final name = cat['name'] as String;
                      final isSelected = name == _selectedCategory;
                      final color = Color(cat['color_value'] as int);
                      final iconName = cat['icon_name'] as String;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedCategory = name);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(IconHelper.getIcon(iconName), color: color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: color, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() => _saveGuard.run(() async {
    try {
      await _saveTransaction();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi gagal disimpan. Periksa data dan coba lagi.')),
        );
      }
    }
  });

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPocketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kantong terlebih dahulu')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori transaksi')),
      );
      return;
    }

    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transaksi harus lebih dari 0')),
      );
      return;
    }

    if (_isEditing) {
      final updated = widget.initialTransaction!.copyWith(
        pocketId: _selectedPocketId,
        type: _type,
        amount: amount,
        category: _selectedCategory,
        note: _noteController.text.trim(),
        merchant: _merchantController.text.trim(),
        date: _selectedDate,
      );
      await ref.read(transactionProvider.notifier).updateTransaction(updated);
    } else {
      final newTx = TransactionModel(
        id: const Uuid().v4(),
        pocketId: _selectedPocketId!,
        type: _type,
        amount: amount,
        category: _selectedCategory!,
        note: _noteController.text.trim(),
        merchant: _merchantController.text.trim(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );
      await ref.read(transactionProvider.notifier).addTransaction(newTx);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pocketsAsync = ref.watch(pocketProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark midnight slate header like Gambar 1
      body: SafeArea(
        bottom: false,
        child: pocketsAsync.when(
          data: (pockets) {
            if (pockets.isNotEmpty) {
              _selectedPocketId ??= pockets.first.pocket.id;
              final targetIdx = pockets.indexWhere((p) => p.pocket.id == _selectedPocketId);
              final validIdx = targetIdx >= 0 ? targetIdx : 0;
              if (_pocketPageController == null) {
                _currentPocketIndex = validIdx;
                _selectedPocketId = pockets[_currentPocketIndex].pocket.id;
                _pocketPageController = PageController(initialPage: _currentPocketIndex);
              }
            }

            return categoriesAsync.when(
              data: (categories) {
                final rawCategories = categories.where((c) => c['type'] == _type).toList();
                final normalCategories = rawCategories.where((c) {
                  final name = (c['name'] as String? ?? '').toLowerCase();
                  final icon = (c['icon_name'] as String? ?? '').toLowerCase();
                  return !name.contains('lain') && icon != 'more_horizontal';
                }).toList();
                final otherCategories = rawCategories.where((c) {
                  final name = (c['name'] as String? ?? '').toLowerCase();
                  final icon = (c['icon_name'] as String? ?? '').toLowerCase();
                  return name.contains('lain') || icon == 'more_horizontal';
                }).toList();
                final filteredCategories = [...normalCategories, ...otherCategories];

                if (_selectedCategory == null && filteredCategories.isNotEmpty) {
                  _selectedCategory = filteredCategories.first['name'] as String;
                }

                final selectedCatData = filteredCategories.firstWhere(
                  (c) => c['name'] == _selectedCategory,
                  orElse: () => filteredCategories.isNotEmpty
                      ? filteredCategories.first
                      : {'name': 'Pengeluaran Lain', 'icon_name': 'more_horizontal', 'color_value': 0xFF64748B},
                );

                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Top Header Section (Dark Midnight Slate)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Edit Transaksi'
                                  : (_type == 'expense' ? 'Tambah Pengeluaran' : 'Tambah Pemasukan'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isEditing)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus Transaksi?'),
                                      content: const Text('Transaksi ini akan dihapus dari catatan keuangan.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                        FilledButton(
                                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await ref.read(transactionProvider.notifier).deleteTransaction(widget.initialTransaction!.id);
                                    if (mounted) Navigator.of(context).pop();
                                  }
                                },
                              )
                            else
                              const SizedBox(width: 42),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Swipeable Pocket Selector Card (Gambar 1 style: swipeable PageView)
                      if (pockets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Belum Ada Kantong',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 64,
                          child: PageView.builder(
                            controller: _pocketPageController,
                            itemCount: pockets.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPocketIndex = index;
                                _selectedPocketId = pockets[index].pocket.id;
                              });
                            },
                            itemBuilder: (context, index) {
                              final pwb = pockets[index];
                              final color = Color(pwb.pocket.colorValue);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: InkWell(
                                  onTap: () => _showPocketPickerSheet(pockets),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.85),
                                          color,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            IconHelper.getIcon(pwb.pocket.iconName),
                                            color: color,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            pwb.pocket.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.privateAmount(pwb.currentBalance, isVisible: ref.watch(balancePrivacyProvider)),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Dynamic dot indicators below pocket card (Gambar 1)
                      if (pockets.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pockets.length, (idx) {
                            final isCurrent = idx == _currentPocketIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: isCurrent ? 14 : 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isCurrent ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ],

                      // Large Nominal Display: Rp 0 (Gambar 1)
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'Rp',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IntrinsicWidth(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [ThousandsSeparatorInputFormatter()],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.white38, fontSize: 40, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty || val.trim() == '0') {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bottom White Sheet Container (Gambar 1)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Category Dropdown Card (Gambar 1)
                                InkWell(
                                  onTap: () => _showCategoryPickerSheet(filteredCategories),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F6FA),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            IconHelper.getIcon(selectedCatData['icon_name'] as String),
                                            color: Color(selectedCatData['color_value'] as int),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            selectedCatData['name'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 2. Catatan (Notes) Field (Gambar 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF38BDF8).withOpacity(0.4) : const Color(0xFF7DD3FC),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Catatan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.black45,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _noteController,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'cth. Makan Siang, Makan Malam',
                                          hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 3. Row: Merchant & Tanggal (Gambar 1)
                                Row(
                                  children: [
                                    // Merchant Field
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F6FA),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Merchant',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.white60 : Colors.black45,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            TextFormField(
                                              controller: _merchantController,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'e.g. Fried Chicken',
                                                hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
                                                suffixIconConstraints: const BoxConstraints(maxHeight: 24),
                                                suffixIcon: PopupMenuButton<String>(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                                                  tooltip: 'Pilih Merchant',
                                                  position: PopupMenuPosition.under,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  onSelected: (val) {
                                                    setState(() {
                                                      _merchantController.text = val;
                                                    });
                                                  },
                                                  itemBuilder: (context) {
                                                    return _commonMerchants.map((m) {
                                                      final isSelected = _merchantController.text.trim().toLowerCase() == m.toLowerCase();
                                                      return PopupMenuItem<String>(
                                                        value: m,
                                                        child: Text(
                                                          m,
                                                          style: TextStyle(
                                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                            color: isSelected ? const Color(0xFF6366F1) : null,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Tanggal Field
                                    Expanded(
                                      flex: 2,
                                      child: InkWell(
                                        onTap: _pickDate,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F6FA),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tanggal',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white60 : Colors.black45,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    _formatDisplayDate(_selectedDate),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.keyboard_arrow_down_rounded,
                                                    size: 18,
                                                    color: isDark ? Colors.white70 : Colors.black54,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // 4. Bottom Button: Catat Transaksi (Gambar 1 style: Lavender/Indigo Rounded Button)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9398F7), // Soft Lavender/Purple from Gambar 1
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Catat Transaksi',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
