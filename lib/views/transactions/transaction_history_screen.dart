import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    height: 46,
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
                ],
              ),
            ),

            const SizedBox(height: 8),

            // List of Transactions
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // Apply filters
                  final filtered = transactions.where((tx) {
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada transaksi yang cocok',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
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
                error: (e, _) => Center(child: Text('Error: $e')),
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
        backgroundColor: const Color(0xFF818CF8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTypePill(String key, String label) {
    final isSelected = _selectedType == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = key),
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

  Widget _buildPocketPill(String? id, String label) {
    final isSelected = _selectedPocketId == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedPocketId = id),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: amountColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchant.isNotEmpty ? tx.merchant : tx.category,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        tx.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatShort(tx.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  if (tx.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        tx.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(tx.amount)}',
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
