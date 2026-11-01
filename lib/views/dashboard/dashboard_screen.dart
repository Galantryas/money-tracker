import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_privacy_provider.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../ai/ai_advisor_screen.dart';
import '../pockets/pocket_detail_screen.dart';
import '../pockets/pocket_form_dialog.dart';
import '../settings/edit_profile_dialog.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transfer_screen.dart';
import '../widgets/card_wave_painter.dart';
import '../widgets/user_avatar_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalBalance = ref.watch(totalBalanceProvider);
    final isBalanceVisible = ref.watch(balancePrivacyProvider);
    final userProfile = ref.watch(userProfileProvider);
    final monthlySummary = ref.watch(currentMonthSummaryProvider);
    final pocketsAsync = ref.watch(pocketProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () async {
            await ref.read(pocketProvider.notifier).loadPockets();
            await ref.read(transactionProvider.notifier).loadTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const EditProfileDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                        child: Row(
                          children: [
                            UserAvatarWidget(profile: userProfile, size: 44),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Halo, Selamat Datang',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ],
                                ),
                                Text(
                                  userProfile.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Tombol Asisten AI Gemini
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                            tooltip: 'Asisten Finansial AI',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                              );
                            },
                          ),
                        ),
                        // Tombol Kunci Aplikasi (Fingerprint lock)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6366F1), size: 20),
                            tooltip: 'Kunci Aplikasi',
                            onPressed: () {
                              ref.read(authProvider.notifier).lockApp();
                            },
                          ),
                        ),
                        // Pengaturan
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Color(0xFF6366F1), size: 20),
                            tooltip: 'Pengaturan',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Total Saldo Card (Sleek Purple/Indigo Gradient with Wavy Lines)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Wavy background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CardWavePainter(waveColor: Colors.white.withOpacity(0.16)),
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
                                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Total Saldo Semua Kantong',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => ref.read(balancePrivacyProvider.notifier).toggle(),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isBalanceVisible ? CurrencyFormatter.format(totalBalance) : '••••••••••',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(height: 1, color: Colors.white24),
                              const SizedBox(height: 16),

                              // Income vs Expense Bulan Berjalan
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.18),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Pemasukan', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                                            Text(
                                              isBalanceVisible ? CurrencyFormatter.formatCompact(monthlySummary.totalIncome) : '•••',
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 30, color: Colors.white24),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.18),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 16),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Pengeluaran', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                                              Text(
                                                isBalanceVisible ? CurrencyFormatter.formatCompact(monthlySummary.totalExpense) : '•••',
                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Bagian Kantong Keuangan (Custom Pockets Carousel)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kantong Saya',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const PocketFormDialog(),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Buat Kantong', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                pocketsAsync.when(
                  data: (pockets) {
                    if (pockets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, size: 44, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Belum ada kantong dibuat'),
                              TextButton(
                                onPressed: () {
                                  showDialog(context: context, builder: (_) => const PocketFormDialog());
                                },
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                                child: const Text('+ Buat Kantong Pertama', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 128,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pockets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final pwb = pockets[index];
                          final color = Color(pwb.pocket.colorValue);

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PocketDetailScreen(pocketId: pwb.pocket.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 146,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.14),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          IconHelper.getIcon(pwb.pocket.iconName),
                                          color: color,
                                          size: 17,
                                        ),
                                      ),
                                      if (pwb.pocket.budgetLimit != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: ((pwb.budgetUsagePercentage ?? 0) >= 1.0)
                                                ? Colors.red.withOpacity(0.12)
                                                : const Color(0xFF6366F1).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${((pwb.budgetUsagePercentage ?? 0) * 100).toInt()}%',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: ((pwb.budgetUsagePercentage ?? 0) >= 1.0) ? Colors.red : const Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pwb.pocket.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isBalanceVisible ? CurrencyFormatter.format(pwb.currentBalance) : '••••••',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (pwb.pocket.budgetLimit != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: (pwb.budgetUsagePercentage ?? 0.0).clamp(0.0, 1.0),
                                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                        valueColor: AlwaysStoppedAnimation(
                                          ((pwb.budgetUsagePercentage ?? 0) >= 1.0) ? Colors.red : color,
                                        ),
                                        minHeight: 3,
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 3),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Gagal memuat kantong: $e'),
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons (Pengeluaran, Pemasukan, Transfer)
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.remove_circle_outline,
                        label: 'Pengeluaran',
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddTransactionScreen(initialType: 'expense'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.add_circle_outline,
                        label: 'Pemasukan',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddTransactionScreen(initialType: 'income'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfer',
                        color: const Color(0xFF6366F1), // Modern Indigo theme
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TransferScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // AI Financial Advisor Banner
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF312E81).withOpacity(0.5)]
                            : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Analisis Cerdas AI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Gemini',
                                    style: TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Evaluasi arus kas, tips berhemat & deteksi kebocoran dana.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Transaksi Terkini
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terkini',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateTab(2), // Pindah ke tab Riwayat
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                      child: const Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: const Center(
                          child: Text('Belum ada transaksi dicatat'),
                        ),
                      );
                    }

                    final recentTx = transactions.take(5).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTx.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = recentTx[index];
                        return _buildTransactionItem(context, tx, isDark);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx, bool isDark) {
    Color amountColor;
    String sign;
    IconData icon;

    if (tx.isIncome) {
      amountColor = const Color(0xFF10B981);
      sign = '+';
      icon = Icons.arrow_downward_rounded;
    } else if (tx.isTransfer) {
      amountColor = const Color(0xFF6366F1); // Indigo theme for transfer
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
                borderRadius: BorderRadius.circular(12),
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
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatRelative(tx.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
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
