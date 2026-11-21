import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/async_action_guard.dart';
import '../../providers/balance_privacy_provider.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/thousands_separator_input_formatter.dart';
import '../../models/pocket.dart';
import '../../models/transaction_model.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? preselectedSourcePocketId;

  const TransferScreen({super.key, this.preselectedSourcePocketId});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _saveGuard = AsyncActionGuard();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _sourcePocketId;
  String? _targetPocketId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sourcePocketId = widget.preselectedSourcePocketId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapPockets() {
    setState(() {
      final temp = _sourcePocketId;
      _sourcePocketId = _targetPocketId;
      _targetPocketId = temp;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
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

  void _showPocketPickerSheet({
    required bool isSource,
    required List<PocketWithBalance> pockets,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentSelected = isSource ? _sourcePocketId : _targetPocketId;
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
                  isSource ? 'Pilih Kantong Sumber (Dari)' : 'Pilih Kantong Tujuan (Ke)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pockets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pwb = pockets[index];
                      final isSelected = pwb.pocket.id == currentSelected;
                      final color = Color(pwb.pocket.colorValue);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSource) {
                              _sourcePocketId = pwb.pocket.id;
                            } else {
                              _targetPocketId = pwb.pocket.id;
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
                                child: Icon(
                                  IconHelper.getIcon(pwb.pocket.iconName),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pwb.pocket.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      CurrencyFormatter.privateAmount(pwb.currentBalance, isVisible: ref.read(balancePrivacyProvider)),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: color, size: 20),
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

  Future<void> _submitTransfer() => _saveGuard.run(() async {
    try {
      await _saveTransfer();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer gagal disimpan. Periksa data dan coba lagi.')),
        );
      }
    }
  });

  Future<void> _saveTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sourcePocketId == null || _targetPocketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kantong sumber dan kantong tujuan')),
      );
      return;
    }

    if (_sourcePocketId == _targetPocketId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kantong sumber dan tujuan tidak boleh sama')),
      );
      return;
    }

    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transfer harus lebih dari 0')),
      );
      return;
    }

    final pockets = ref.read(pocketProvider).valueOrNull ?? [];
    final sourcePocket = pockets.firstWhere(
      (p) => p.pocket.id == _sourcePocketId,
      orElse: () => throw Exception('Kantong sumber tidak ditemukan'),
    );

    if (sourcePocket.currentBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo ${sourcePocket.pocket.name} tidak cukup (${CurrencyFormatter.privateAmount(sourcePocket.currentBalance, isVisible: ref.read(balancePrivacyProvider))})',
          ),
        ),
      );
      return;
    }

    final targetPocket = pockets.firstWhere(
      (p) => p.pocket.id == _targetPocketId,
      orElse: () => throw Exception('Kantong tujuan tidak ditemukan'),
    );

    final transferTx = TransactionModel(
      id: const Uuid().v4(),
      pocketId: _sourcePocketId!,
      targetPocketId: _targetPocketId!,
      type: 'transfer',
      amount: amount,
      category: 'Antar Kantong',
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : 'Pindah dana ke ${targetPocket.pocket.name}',
      merchant: targetPocket.pocket.name,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await ref.read(transactionProvider.notifier).addTransaction(transferTx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            'Berhasil transfer ${CurrencyFormatter.privateAmount(amount, isVisible: ref.read(balancePrivacyProvider))} ke ${targetPocket.pocket.name}',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pocketsAsync = ref.watch(pocketProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF6366F1), // Purple gradient header matching Gambar 2
      body: SafeArea(
        bottom: false,
        child: pocketsAsync.when(
          data: (pockets) {
            if (pockets.isNotEmpty) {
              _sourcePocketId ??= pockets.first.pocket.id;
              if (_targetPocketId == null && pockets.length > 1) {
                _targetPocketId = pockets.firstWhere((p) => p.pocket.id != _sourcePocketId).pocket.id;
              }
            }

            final sourcePocket = pockets.firstWhere(
              (p) => p.pocket.id == _sourcePocketId,
              orElse: () => pockets.isNotEmpty
                  ? pockets.first
                  : PocketWithBalance(
                      pocket: Pocket(
                        id: 'src_empty',
                        name: 'Kantong Asal',
                        iconName: 'wallet',
                        colorValue: 0xFF2563EB,
                        initialBalance: 0,
                        createdAt: DateTime.now(),
                      ),
                      currentBalance: 0,
                      spentThisMonth: 0,
                      incomeThisMonth: 0,
                    ),
            );

            final targetPocket = pockets.firstWhere(
              (p) => p.pocket.id == _targetPocketId,
              orElse: () => pockets.length > 1
                  ? pockets[1]
                  : PocketWithBalance(
                      pocket: Pocket(
                        id: 'tgt_empty',
                        name: 'Kantong Tujuan',
                        iconName: 'savings',
                        colorValue: 0xFF10B981,
                        initialBalance: 0,
                        createdAt: DateTime.now(),
                      ),
                      currentBalance: 0,
                      spentThisMonth: 0,
                      incomeThisMonth: 0,
                    ),
            );

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  // Top Purple Header Section
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
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const Text(
                          'Transfer Dana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 42),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dual Pocket Cards Row ("Dari" <-> Swap <-> "Ke") matching Gambar 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            // "Dari" Card
                            Expanded(
                              child: InkWell(
                                onTap: () => _showPocketPickerSheet(isSource: true, pockets: pockets),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dari',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Color(sourcePocket.pocket.colorValue).withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              IconHelper.getIcon(sourcePocket.pocket.iconName),
                                              color: Color(sourcePocket.pocket.colorValue),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              sourcePocket.pocket.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        CurrencyFormatter.privateAmount(sourcePocket.currentBalance, isVisible: ref.watch(balancePrivacyProvider)),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Space for centered swap button
                            // "Ke" Card
                            Expanded(
                              child: InkWell(
                                onTap: () => _showPocketPickerSheet(isSource: false, pockets: pockets),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ke',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Color(targetPocket.pocket.colorValue).withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              IconHelper.getIcon(targetPocket.pocket.iconName),
                                              color: Color(targetPocket.pocket.colorValue),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              targetPocket.pocket.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        CurrencyFormatter.privateAmount(targetPocket.currentBalance, isVisible: ref.watch(balancePrivacyProvider)),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Swap Circular Button in the middle
                        GestureDetector(
                          onTap: _swapPockets,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: Color(0xFF6366F1),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Large Centered Nominal Input Display ("Rp 0") matching Gambar 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: IntrinsicWidth(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        textAlign: TextAlign.center,
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        decoration: const InputDecoration(
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nominal wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // White Bottom Sheet Section matching Gambar 2
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Card ("Antar Akun") matching Gambar 2
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.sync_alt_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kategori',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Antar Kantong',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Transfer',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Side-by-side Row: Catatan and Tanggal matching Gambar 2
                            Row(
                              children: [
                                // Catatan Box
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.edit_note_rounded,
                                              size: 16,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Catatan',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _noteController,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                            border: InputBorder.none,
                                            hintText: 'contoh Top Up',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Tanggal Box
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 15,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Tanggal',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatDisplayDate(_selectedDate),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Submit Button "Catat Transaksi" matching Gambar 2
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submitTransfer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF818CF8), // Lavender button matching Gambar 2
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Catat Transaksi',
                                  style: TextStyle(
                                    fontSize: 16,
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
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}
