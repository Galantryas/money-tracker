import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../providers/transaction_provider.dart';
import '../reports/date_range_report_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _touchedIndex = -1;

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categorySpendings = ref.watch(categorySpendingProvider(_selectedMonth));
    final transactionsAsync = ref.watch(transactionProvider);

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
                color: Color(0xFF6366F1), // Indigo theme
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statistik Keuangan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DateRangeReportScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.date_range_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Rentang Tanggal',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector Bar (Capsule Pill Design)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF6366F1)),
                            onPressed: _prevMonth,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6366F1)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormatter.formatMonthYear(_selectedMonth),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1)),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Arus Kas Bulan Terpilih (Income vs Expense)
                    transactionsAsync.when(
                      data: (transactions) {
                        double monthIncome = 0;
                        double monthExpense = 0;

                        for (var tx in transactions) {
                          if (tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month) {
                            if (tx.isIncome) monthIncome += tx.amount;
                            if (tx.isExpense) monthExpense += tx.amount;
                          }
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Pemasukan', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyFormatter.format(monthIncome),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Pengeluaran', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyFormatter.format(monthExpense),
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
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 22),

                    // Donut Chart Pengeluaran per Kategori
                    Text(
                      'Pengeluaran per Kategori',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (categorySpendings.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: const Center(
                          child: Text('Tidak ada pengeluaran tercatat di bulan ini'),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 210,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 48,
                                  sections: List.generate(categorySpendings.length, (i) {
                                    final isTouched = i == _touchedIndex;
                                    final fontSize = isTouched ? 15.0 : 11.0;
                                    final radius = isTouched ? 65.0 : 54.0;
                                    final color = IconHelper.availableColors[i % IconHelper.availableColors.length];
                                    final item = categorySpendings[i];

                                    return PieChartSectionData(
                                      color: color,
                                      value: item.totalAmount,
                                      title: '${item.percentage.toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            // List Breakdown Kategori
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categorySpendings.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = categorySpendings[index];
                                final color = IconHelper.availableColors[index % IconHelper.availableColors.length];

                                return Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.categoryName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      '${item.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      CurrencyFormatter.format(item.totalAmount),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),

                    // Top Merchants Ranking Bulan Ini
                    Text(
                      'Top Pengeluaran per Merchant',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    transactionsAsync.when(
                      data: (transactions) {
                        final Map<String, double> merchantSpendings = {};
                        double totalMonthExpense = 0;

                        for (var tx in transactions) {
                          if (tx.date.year == _selectedMonth.year &&
                              tx.date.month == _selectedMonth.month &&
                              tx.isExpense) {
                            final name = tx.merchant.trim().isNotEmpty ? tx.merchant.trim() : 'Lainnya';
                            merchantSpendings[name] = (merchantSpendings[name] ?? 0) + tx.amount;
                            totalMonthExpense += tx.amount;
                          }
                        }

                        if (merchantSpendings.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Center(
                              child: Text('Belum ada transaksi pengeluaran bulan ini'),
                            ),
                          );
                        }

                        final sortedMerchants = merchantSpendings.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                        final topMerchants = sortedMerchants.take(5).toList();

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topMerchants.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = topMerchants[index];
                              final percentage = totalMonthExpense > 0 ? (item.value / totalMonthExpense) : 0.0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Color(0xFF6366F1),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.key,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        CurrencyFormatter.format(item.value),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage.clamp(0.0, 1.0),
                                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF818CF8)),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
