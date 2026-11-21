import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../models/transaction_model.dart';
import '../../providers/balance_privacy_provider.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transfer_screen.dart';
import '../widgets/card_wave_painter.dart';
import 'pocket_form_dialog.dart';

class PocketDetailScreen extends ConsumerWidget {
  final String pocketId;

  const PocketDetailScreen({super.key, required this.pocketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isBalanceVisible = ref.watch(balancePrivacyProvider);
    final pocketsAsync = ref.watch(pocketProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return pocketsAsync.when(
      data: (pockets) {
        final pwbIndex = pockets.indexWhere((p) => p.pocket.id == pocketId);
        if (pwbIndex == -1) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Kantong tidak ditemukan atau telah dihapus')),
          );
        }

        final pwb = pockets[pwbIndex];
        final pocket = pwb.pocket;
        final color = Color(pocket.colorValue);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Purple/Pocket Header Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF4F46E5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                          Text(
                            pocket.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white,
                            ),
                            tooltip: isBalanceVisible ? 'Sembunyikan Saldo' : 'Tampilkan Saldo',
                            onPressed: () => ref.read(balancePrivacyProvider.notifier).toggle(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white),
                            tooltip: 'Edit Kantong',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PocketFormDialog(initialPocket: pocket),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wavy Pocket Hero Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                Color.lerp(color, Colors.black, 0.25) ?? color,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: CardWavePainter(waveColor: Colors.white.withOpacity(0.15)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  IconHelper.getIcon(pocket.iconName),
                                                  color: color,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pocket.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Saldo Kantong',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Aktif',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        isBalanceVisible ? CurrencyFormatter.format(pwb.currentBalance) : '••••••••••',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      if (pocket.budgetLimit != null) ...[
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: (pwb.budgetUsagePercentage ?? 0.0).clamp(0.0, 1.0),
                                            backgroundColor: Colors.white24,
                                            valueColor: AlwaysStoppedAnimation(
                                              ((pwb.budgetUsagePercentage ?? 0) >= 1.0) ? Colors.amberAccent : Colors.white,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Keluar: ${isBalanceVisible ? CurrencyFormatter.format(pwb.spentThisMonth) : '••••'}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            ),
                                            Text(
                                              'Limit: ${isBalanceVisible ? CurrencyFormatter.format(pocket.budgetLimit!) : '••••'}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Action Buttons for this Pocket
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionScreen(preselectedPocketId: pocket.id),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_card_rounded, size: 18),
                                label: const Text('Catat Transaksi'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransferScreen(preselectedSourcePocketId: pocket.id),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF6366F1)),
                                label: const Text('Transfer Dana', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),

                        // Riwayat Transaksi Khusus Kantong Ini
                        const Text(
                          'Riwayat Transaksi Kantong Ini',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),

                        transactionsAsync.when(
                          data: (transactions) {
                            final pocketTxs = transactions
                                .where((t) => t.pocketId == pocket.id || t.targetPocketId == pocket.id)
                                .toList();

                            if (pocketTxs.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Center(
                                  child: Text('Belum ada transaksi di kantong ini'),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pocketTxs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final tx = pocketTxs[index];
                                return _buildTxItem(context, tx, pocket.id, isDark, isBalanceVisible);
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                          error: (e, _) => Text('Error: $e'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildTxItem(BuildContext context, TransactionModel tx, String currentPocketId, bool isDark, bool isBalanceVisible) {
    Color amountColor;
    String sign;

    if (tx.isTransfer) {
      if (tx.pocketId == currentPocketId) {
        amountColor = Colors.orange;
        sign = '-';
      } else {
        amountColor = const Color(0xFF10B981);
        sign = '+';
      }
    } else if (tx.isIncome) {
      amountColor = const Color(0xFF10B981);
      sign = '+';
    } else {
      amountColor = Colors.red;
      sign = '-';
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
              child: Icon(
                tx.isTransfer
                    ? Icons.swap_horiz_rounded
                    : (tx.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                color: amountColor,
                size: 20,
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    '${tx.category} • ${DateFormatter.formatRelative(tx.date)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  if (tx.note.isNotEmpty)
                    Text(
                      tx.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.privateAmount(tx.amount, isVisible: isBalanceVisible, sign: sign),
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
