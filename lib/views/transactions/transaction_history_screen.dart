import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/transaction_filter.dart';
import '../../models/transaction_model.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/balance_privacy_provider.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  String _searchQuery = '';
  String _selectedType = 'all'; // 'all', 'expense', 'income', 'transfer'
  String? _selectedPocketId; // null = all pockets
  String? _selectedCategory;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1), // Indigo header
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: transactionsAsync.when(
                          data: (txs) => Text(
                            '${txs.length} Transaksi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Bar inside Header
                  Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Cari merchant, catatan, atau kategori...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Pills Row (Type)
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        _buildTypePill('all', 'Semua'),
                        const SizedBox(width: 8),
                        _buildTypePill('expense', 'Pengeluaran'),
                        const SizedBox(width: 8),
                        _buildTypePill('income', 'Pemasukan'),
                        const SizedBox(width: 8),
                        _buildTypePill('transfer', 'Transfer'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Pocket Filter Pills
                  pocketsAsync.when(
                    data: (pockets) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            _buildPocketPill(null, 'Semua Kantong'),
                            const SizedBox(width: 8),
                            ...pockets.map((pwb) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildPocketPill(pwb.pocket.id, pwb.pocket.name),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      TextButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateRange == null ? 'Tanggal' : '${DateFormatter.formatShort(_dateRange!.start)} - ${DateFormatter.formatShort(_dateRange!.end)}'),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            initialDateRange: _dateRange,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (range != null && mounted) setState(() => _dateRange = range);
                        },
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Filter kategori',
                        onSelected: (value) => setState(() => _selectedCategory = value.isEmpty ? null : value),
                        itemBuilder: (_) {
                          final categories = (transactionsAsync.valueOrNull ?? [])
                              .map((tx) => tx.category).toSet().toList()..sort();
                          return [
                            const PopupMenuItem(value: '', child: Text('Semua kategori')),
                            ...categories.map((category) => PopupMenuItem(value: category, child: Text(category))),
                          ];
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(_selectedCategory ?? 'Kategori'),
                        ),
                      ),
                      if (_dateRange != null || _selectedCategory != null)
                        TextButton(onPressed: () => setState(() {
                          _dateRange = null;
                          _selectedCategory = null;
                        }), child: const Text('Hapus filter')),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // List of Transactions
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // Apply filters
                  final filtered = filterTransactions(transactions,
                      category: _selectedCategory,
                      start: _dateRange?.start,
                      end: _dateRange?.end).where((tx) {
                    if (_selectedType != 'all' && tx.type != _selectedType) return false;
                    if (_selectedPocketId != null &&
                        tx.pocketId != _selectedPocketId &&
                        tx.targetPocketId != _selectedPocketId) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      final matchMerchant = tx.merchant.toLowerCase().contains(_searchQuery);
                      final matchNote = tx.note.toLowerCase().contains(_searchQuery);
                      final matchCategory = tx.category.toLowerCase().contains(_searchQuery);
                      if (!matchMerchant && !matchNote && !matchCategory) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    final hasFilters = _selectedType != 'all' || _selectedPocketId != null ||
                        _selectedCategory != null || _dateRange != null || _searchQuery.isNotEmpty;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            transactions.isEmpty
                                ? 'Belum ada transaksi. Tekan Catat untuk menambahkan.'
                                : 'Tidak ada transaksi yang cocok dengan filter.',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hasFilters && _searchQuery.isEmpty)
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedType = 'all';
                                _selectedPocketId = null;
                                _selectedCategory = null;
                                _dateRange = null;
                              }),
                              child: const Text('Hapus filter'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return _buildTxCard(context, tx, isDark);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                error: (_, __) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Riwayat transaksi tidak dapat dimuat.'),
                    TextButton(
                      onPressed: () => ref.read(transactionProvider.notifier).loadTransactions(),
                      child: const Text('Coba lagi'),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.brightness == Brightness.dark
            ? const Color(0xFF4F46E5) : Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTypePill(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedType == key,
      onSelected: (_) => setState(() => _selectedType = key),
    );
  }

  Widget _buildPocketPill(String? id, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPocketId == id,
      onSelected: (_) => setState(() => _selectedPocketId = id),
    );
  }

  Widget _buildTxCard(BuildContext context, TransactionModel tx, bool isDark) {
    Color amountColor;
    String sign;
    IconData icon;

    if (tx.isIncome) {
      amountColor = const Color(0xFF10B981);
      sign = '+';
      icon = Icons.arrow_downward_rounded;
    } else if (tx.isTransfer) {
      amountColor = const Color(0xFF6366F1);
      sign = '';
      icon = Icons.swap_horiz_rounded;
    } else {
      amountColor = Colors.red;
      sign = '-';
      icon = Icons.arrow_upward_rounded;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(initialTransaction: tx),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: amountColor, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(tx.merchant.isNotEmpty ? tx.merchant : tx.category,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            ]),
            const SizedBox(height: 6),
            Text('${tx.category} · ${DateFormatter.formatShort(tx.date)}',
                style: Theme.of(context).textTheme.bodySmall),
            if (tx.note.isNotEmpty) Text(tx.note, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.privateAmount(tx.amount, isVisible: ref.watch(balancePrivacyProvider), sign: sign),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
