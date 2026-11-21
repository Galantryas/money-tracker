import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gemini_provider.dart';
import 'ai_consent_dialog.dart';

class AiAdvisorScreen extends ConsumerStatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  ConsumerState<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends ConsumerState<AiAdvisorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;
  bool _consentGranted = false;
  bool _consentPending = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final can = _textController.text.trim().isNotEmpty;
      if (can != _canSend) {
        setState(() => _canSend = can);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String prompt) async {
    if (prompt.trim().isEmpty) return;
    if ((ref.read(geminiProvider).apiKey?.trim().isNotEmpty ?? false) && !_consentGranted) {
      if (_consentPending) return;
      _consentPending = true;
      final accepted = await showAiConsentDialog(context);
      _consentPending = false;
      if (!mounted || !accepted) return;
      _consentGranted = true;
    }
    _textController.clear();
    ref.read(geminiProvider.notifier).sendPrompt(prompt);
    _scrollToBottom();
  }

  void _showApiKeyDialog(BuildContext context) {
    final geminiState = ref.read(geminiProvider);
    final keyController = TextEditingController(text: geminiState.apiKey ?? '');
    bool isObscured = true;
    bool isTesting = false;
    String? testResult;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
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
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, color: Color(0xFF6366F1), size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Pengaturan Gemini API Key',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Masukkan Google Gemini API Key Anda untuk mengaktifkan analisa kecerdasan buatan. Kunci API disimpan secara terenkripsi di perangkat lokal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input Field
                    TextField(
                      controller: keyController,
                      obscureText: isObscured,
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                        prefixIcon: const Icon(Icons.key, color: Color(0xFF6366F1), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setModalState(() => isObscured = !isObscured),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Help text with link info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dapatkan API Key gratis di Google AI Studio (aistudio.google.com)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                              color: isSuccess ? const Color(0xFF10B981) : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSuccess ? const Color(0xFF047857) : Colors.red.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions Row
                    Row(
                      children: [
                        // Test Button
                        OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  final inputKey = keyController.text.trim();
                                  if (inputKey.isEmpty) {
                                    setModalState(() {
                                      testResult = 'Masukkan API Key terlebih dahulu.';
                                      isSuccess = false;
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isTesting = true;
                                    testResult = null;
                                  });

                                  try {
                                    await ref.read(geminiProvider.notifier).testApiKey(inputKey);
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = 'Koneksi Berhasil! API Key aktif & valid.';
                                      isSuccess = true;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = e.toString().replaceFirst('Exception: ', '');
                                      isSuccess = false;
                                    });
                                  }
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.speed_rounded, size: 16),
                          label: Text(isTesting ? 'Menguji...' : 'Cek Koneksi'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Save Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final inputKey = keyController.text.trim();
                              await ref.read(geminiProvider.notifier).saveApiKey(inputKey);
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF10B981),
                                    content: Text(
                                      inputKey.isNotEmpty
                                          ? 'Gemini API Key berhasil disimpan!'
                                          : 'API Key telah dikosongkan.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text(
                              'Simpan Kunci',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (geminiState.isConfigured) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await ref.read(geminiProvider.notifier).removeApiKey();
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gemini API Key telah dihapus.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                          label: const Text(
                            'Hapus Kunci API Tersimpan',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final geminiState = ref.watch(geminiProvider);

    // Auto-scroll when new messages arrive
    ref.listen(geminiProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || prev?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Asisten Finansial AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 16),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bertenaga Google Gemini',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Connection Status Pill
                  GestureDetector(
                    onTap: () => _showApiKeyDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: geminiState.isConfigured
                            ? const Color(0xFF10B981).withOpacity(0.25)
                            : Colors.amber.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: geminiState.isConfigured
                              ? const Color(0xFF10B981).withOpacity(0.5)
                              : Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: geminiState.isConfigured
                                  ? const Color(0xFF10B981)
                                  : Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            geminiState.isConfigured ? 'API Aktif' : 'Atur API',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Reset Chat Button
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: 'Reset Percakapan',
                    onPressed: () {
                      ref.read(geminiProvider.notifier).clearChat();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick Prompts Horizontal Scroll
          _buildQuickPromptsBar(context),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: geminiState.messages.length + (geminiState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == geminiState.messages.length && geminiState.isLoading) {
                  return _buildLoadingBubble(isDark);
                }
                final msg = geminiState.messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // Input Bar
          _buildInputBar(isDark, geminiState.isLoading),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar(BuildContext context) {
    final prompts = [
      {
        'icon': '📊',
        'title': 'Analisis Lengkap',
        'prompt': 'Tolong berikan evaluasi lengkap dan komprehensif mengenai kondisi keuangan saya berdasarkan data saldo, pemasukan, pengeluaran, dan kategori bulan ini.',
      },
      {
        'icon': '💡',
        'title': 'Saran Berhemat',
        'prompt': 'Berdasarkan pengeluaran bulan ini, pos kategori atau merchant mana saja yang paling boros atau bisa saya hemat? Berikan rekomendasi alokasi anggaran yang ideal (misal 50/30/20).',
      },
      {
        'icon': '⚠️',
        'title': 'Deteksi Bocor',
        'prompt': 'Identifikasi apakah ada pengeluaran impulsif, transaksi bernominal besar yang tidak biasa, atau pos pengeluaran yang berisiko membuat saya overbudget.',
      },
      {
        'icon': '🎯',
        'title': 'Strategi Menabung',
        'prompt': 'Dengan sisa saldo dan tren arus kas saya saat ini, bagaimana strategi terbaik agar saya bisa meningkatkan porsi tabungan dan menyiapkan dana darurat?',
      },
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = prompts[index];
          return ActionChip(
            avatar: Text(p['icon']!, style: const TextStyle(fontSize: 14)),
            label: Text(
              p['title']!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            backgroundColor: const Color(0xFFEEF2FF),
            side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _handleSend(p['prompt']!),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage msg, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // Assistant / Gemini Message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Sparkle Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: msg.isError
                      ? [Colors.red, Colors.deepOrange]
                      : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
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
              child: Icon(
                msg.isError ? Icons.error_outline_rounded : Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),

            // Bubble Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: msg.isError
                        ? Colors.red.withOpacity(0.4)
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattedText(msg.text, isDark),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Analisis disalin ke papan klip!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Salin',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Gemini sedang menganalisa data...',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isDark) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Headings (## or #)
      if (line.startsWith('## ') || line.startsWith('# ')) {
        final headingText = line.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              headingText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet points
      if (line.trim().startsWith('- ') || line.trim().startsWith('• ') || line.trim().startsWith('* ')) {
        final content = line.trim().substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                Expanded(
                  child: _parseInlineFormatting(content, isDark),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular line
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: _parseInlineFormatting(line, isDark),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _parseInlineFormatting(String text, bool isDark) {
    // Basic bold parsing: **text**
    final parts = text.split('**');
    if (parts.length == 1) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B),
        ),
      );
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF334155)),
            fontSize: 13.5,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(height: 1.45, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (val) {
                  if (!isLoading) _handleSend(val);
                },
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu tentang keuangan Anda...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: (_canSend && !isLoading) ? () => _handleSend(_textController.text) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (_canSend && !isLoading)
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      ),
                boxShadow: (_canSend && !isLoading)
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
