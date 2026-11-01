import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../models/transaction_model.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/add_transaction_screen.dart';

class DateRangeReportScreen extends ConsumerStatefulWidget {
  const DateRangeReportScreen({super.key});

  @override
  ConsumerState<DateRangeReportScreen> createState() => _DateRangeReportScreenState();
}

class _DateRangeReportScreenState extends ConsumerState<DateRangeReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedType = 'expense'; // 'expense' or 'income'
  String? _selectedPocketId; // null = all pockets
  String _selectedPreset = 'this_month';
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default: awal bulan berjalan sampai hari ini
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  void _setPresetRange(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _selectedPreset = preset;
      if (preset == 'today') {
        _startDate = today;
        _endDate = today;
      } else if (preset == '7days') {
        _startDate = today.subtract(const Duration(days: 6));
        _endDate = today;
      } else if (preset == '30days') {
        _startDate = today.subtract(const Duration(days: 29));
        _endDate = today;
      } else if (preset == 'this_month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = today;
      } else if (preset == 'last_month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        _startDate = lastMonth;
        _endDate = lastDayOfLastMonth;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(elevation: 0),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _toggleCategoryExpand(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  void _expandAll(List<String> categories) {
    setState(() {
      _expandedCategories.addAll(categories);
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final transactionsAsync = ref.watch(transactionProvider);
    final pocketsAsync = ref.watch(pocketProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Purple Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1), // Indigo header
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Rincian Rentang Tanggal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _pickCustomRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Main Body Content
            Expanded(
              child: transactionsAsync.when(
                data: (allTransactions) {
                  final pockets = pocketsAsync.valueOrNull ?? [];

                  // Filter data berdasarkan rentang tanggal dan kantong
                  final filtered = allTransactions.where((tx) {
                    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
                    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
                    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);

                    if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
                    if (_selectedPocketId != null &&
                        tx.pocketId != _selectedPocketId &&
                        tx.targetPocketId != _selectedPocketId) {
                      return false;
                    }
                    return true;
                  }).toList();

                  double rangeIncome = 0;
                  double rangeExpense = 0;

                  for (var tx in filtered) {
                    if (tx.isIncome) {
                      rangeIncome += tx.amount;
                    } else if (tx.isExpense) {
                      rangeExpense += tx.amount;
                    }
                  }
                  final rangeNett = rangeIncome - rangeExpense;

                  final typeTxs = filtered.where((t) => t.type == _selectedType).toList();
                  final totalForType = _selectedType == 'expense' ? rangeExpense : rangeIncome;

                  final Map<String, List<TransactionModel>> categoryMap = {};
                  for (var tx in typeTxs) {
                    categoryMap.putIfAbsent(tx.category, () => []).add(tx);
                  }

                  for (var list in categoryMap.values) {
                    list.sort((a, b) => b.date.compareTo(a.date));
                  }

                  final sortedCategories = categoryMap.entries.toList()
                    ..sort((a, b) {
                      final sumA = a.value.fold<double>(0.0, (s, t) => s + t.amount);
                      final sumB = b.value.fold<double>(0.0, (s, t) => s + t.amount);
                      return sumB.compareTo(sumA);
                    });

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Selector Rentang Tanggal Aktif
                        InkWell(
                          onTap: _pickCustomRange,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Periode Tanggal Terpilih',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${DateFormatter.formatShort(_startDate)}  —  ${DateFormatter.formatShort(_endDate)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF6366F1)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quick Preset Filter Pills
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPresetPill('today', 'Hari Ini'),
                              const SizedBox(width: 6),
                              _buildPresetPill('7days', '7 Hari Terakhir'),
                              const SizedBox(width: 6),
                              _buildPresetPill('this_month', 'Bulan Ini'),
                              const SizedBox(width: 6),
                              _buildPresetPill('last_month', 'Bulan Lalu'),
                              const SizedBox(width: 6),
                              _buildPresetPill('30days', '30 Hari Terakhir'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter Kantong
                        if (pockets.isNotEmpty) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPocketFilterPill(null, 'Semua Kantong'),
                                const SizedBox(width: 6),
                                ...pockets.map((pwb) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: _buildPocketFilterPill(pwb.pocket.id, pwb.pocket.name),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 2. Ringkasan Total Pemasukan & Pengeluaran
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text('Pemasukan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(rangeIncome),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.black12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            CurrencyFormatter.format(rangeExpense),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Selisih Bersih (Nett)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(
                                    CurrencyFormatter.format(rangeNett),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: rangeNett >= 0 ? const Color(0xFF10B981) : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Segment Selector: Pengeluaran vs Pemasukan
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedType = 'expense'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedType == 'expense' ? Colors.red : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 16,
                                            color: _selectedType == 'expense' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Pengeluaran (${filtered.where((t) => t.isExpense).length})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _selectedType == 'expense' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedType = 'income'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedType == 'income' ? const Color(0xFF10B981) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.arrow_downward_rounded,
                                            size: 16,
                                            color: _selectedType == 'income' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Pemasukan (${filtered.where((t) => t.isIncome).length})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _selectedType == 'income' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header Rincian per Kategori
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rincian per Kategori',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (sortedCategories.isNotEmpty)
                              Row(
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _expandAll(sortedCategories.map((e) => e.key).toList()),
                                    child: const Text('Buka Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: _collapseAll,
                                    child: const Text('Tutup', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 4. Daftar Kategori dengan Akordion
                        if (sortedCategories.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    _selectedType == 'expense' ? Icons.receipt_long_outlined : Icons.savings_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada ${_selectedType == 'expense' ? 'pengeluaran' : 'pemasukan'} pada rentang tanggal ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final entry = sortedCategories[index];
                              final categoryName = entry.key;
                              final txList = entry.value;
                              final categoryTotal = txList.fold<double>(0.0, (sum, item) => sum + item.amount);
                              final percentage = totalForType > 0 ? (categoryTotal / totalForType) * 100 : 0.0;
                              final isExpanded = _expandedCategories.contains(categoryName);
                              final color = IconHelper.availableColors[index % IconHelper.availableColors.length];

                              return _buildCategoryCard(
                                context: context,
                                categoryName: categoryName,
                                categoryTotal: categoryTotal,
                                percentage: percentage,
                                transactions: txList,
                                color: color,
                                isExpanded: isExpanded,
                                pockets: pockets,
                                isDark: isDark,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 28),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetPill(String key, String label) {
    final isSelected = _selectedPreset == key;
    return GestureDetector(
      onTap: () => _setPresetRange(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6366F1),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPocketFilterPill(String? id, String label) {
    final isSelected = _selectedPocketId == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedPocketId = isSelected ? null : id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : const Color(0xFF1E293B))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String categoryName,
    required double categoryTotal,
    required double percentage,
    required List<TransactionModel> transactions,
    required Color color,
    required bool isExpanded,
    required List<PocketWithBalance> pockets,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? color.withOpacity(0.5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Kategori (Bisa Ditekan untuk Expand/Collapse)
          InkWell(
            onTap: () => _toggleCategoryExpand(categoryName),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.category_outlined, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${transactions.length} transaksi  •  ${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(categoryTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _selectedType == 'expense' ? Colors.red : const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                isExpanded ? 'Tutup rincian' : 'Lihat isi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 18,
                                color: color,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar Persentase
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Isi Transaksi dalam Kategori Ini (Expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.02),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, txIndex) {
                  final tx = transactions[txIndex];
                  final pocket = pockets.where((p) => p.pocket.id == tx.pocketId).firstOrNull?.pocket;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(initialTransaction: tx),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormatter.formatShort(tx.date),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tx.merchant.isNotEmpty ? tx.merchant : categoryName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    if (pocket != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Color(pocket.colorValue).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          pocket.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(pocket.colorValue),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (tx.note.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(tx.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _selectedType == 'expense' ? Colors.red : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
