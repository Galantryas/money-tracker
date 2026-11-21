import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../providers/balance_privacy_provider.dart';
import '../../providers/pocket_provider.dart';
import 'pocket_detail_screen.dart';
import 'pocket_form_dialog.dart';
import '../widgets/balance_visibility_button.dart';

class PocketsScreen extends ConsumerWidget {
  const PocketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pocketsAsync = ref.watch(pocketProvider);
    final isBalanceVisible = ref.watch(balancePrivacyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF6366F1), // Purple header
      body: SafeArea(
        bottom: false,
        child: pocketsAsync.when(
          data: (pockets) {
            final totalBalance = pockets.fold<double>(0.0, (sum, p) => sum + p.currentBalance);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Purple Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screen Title: "Kantong"
                      const Text(
                        'Kantong',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total Saldo Section
                      Text(
                        'Total Saldo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              isBalanceVisible ? CurrencyFormatter.format(totalBalance) : '••••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          BalanceVisibilityButton(
                            isVisible: isBalanceVisible,
                            onPressed: () => ref.read(balancePrivacyProvider.notifier).toggle(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total saldo dari semua kantong 💳',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // White Curved Bottom Sheet Section
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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      children: [
                        // "+ Tambah Kantong Baru" Dashed Outline Button
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const PocketFormDialog(),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: CustomPaint(
                            painter: DashedRectPainter(
                              color: const Color(0xFF818CF8),
                              strokeWidth: 1.5,
                              radius: 16,
                            ),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tambah Kantong Baru',
                                    style: TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Section Header: "Daftar Kantong"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar Kantong',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${pockets.length} Kantong',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Empty State if list is empty
                        if (pockets.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada kantong',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ketuk "+ Tambah Kantong Baru" untuk membuat kantong pertama Anda.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          // List of Full-Width Cards with Wavy Gradient Backgrounds
                          ...pockets.map((pwb) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildPocketWavyCard(
                                context: context,
                                pwb: pwb,
                                isBalanceVisible: isBalanceVisible,
                                isDark: isDark,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildPocketWavyCard({
    required BuildContext context,
    required PocketWithBalance pwb,
    required bool isBalanceVisible,
    required bool isDark,
  }) {
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.25) ?? color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Flowing Wave Decoration
              Positioned.fill(
                child: CustomPaint(
                  painter: CardWavePainter(waveColor: Colors.white.withOpacity(0.15)),
                ),
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: White Circle Icon + Name + Popup Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // White Circular Icon
                        Container(
                          width: 38,
                          height: 38,
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

                        // Pocket Name & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pwb.pocket.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aktif',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 3-dots Menu Button
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (val) {
                            if (val == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) => PocketFormDialog(initialPocket: pwb.pocket),
                              );
                            } else if (val == 'detail') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PocketDetailScreen(pocketId: pwb.pocket.id),
                                ),
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Lihat Rincian'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Ubah Kantong'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Row: Saldo Display + Budget Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isBalanceVisible ? CurrencyFormatter.format(pwb.currentBalance) : '••••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        if (pwb.pocket.budgetLimit != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                ((pwb.budgetUsagePercentage ?? 0) >= 1.0)
                                    ? 'Limit Terlampaui!'
                                    : 'Budget ${((pwb.budgetUsagePercentage ?? 0) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: ((pwb.budgetUsagePercentage ?? 0) >= 1.0)
                                      ? Colors.amberAccent
                                      : Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 70,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: (pwb.budgetUsagePercentage ?? 0.0).clamp(0.0, 1.0),
                                    backgroundColor: Colors.white.withOpacity(0.25),
                                    valueColor: AlwaysStoppedAnimation(
                                      ((pwb.budgetUsagePercentage ?? 0) >= 1.0)
                                          ? Colors.amberAccent
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw flowing wavy lines across banking cards
class CardWavePainter extends CustomPainter {
  final Color waveColor;

  CardWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Wave 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.65,
      size.height * 0.8,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(path1, paint);

    // Wave 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);
    path2.cubicTo(
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.95,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(path2, paint);

    // Wave 3
    final path3 = Path();
    path3.moveTo(0, size.height * 0.75);
    path3.cubicTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.75,
      size.height * 1.1,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for dashed rounded rectangle border
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dash = 6,
    this.gap = 4,
    this.radius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dash;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
