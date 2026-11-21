import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/gemini_service.dart';
import 'pocket_provider.dart';
import 'transaction_provider.dart';

List<T> requireFinancialData<T>(AsyncValue<List<T>> value) {
  if (value.isLoading || value.hasError || value.valueOrNull == null) {
    throw Exception('Data keuangan belum tersedia. Pastikan data berhasil dimuat, lalu coba lagi.');
  }
  return value.valueOrNull!;
}

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class GeminiState {
  final String? apiKey;
  final bool isConfigured;
  final bool isLoading;
  final bool isTestingKey;
  final String? errorMessage;
  final List<AiChatMessage> messages;

  const GeminiState({
    this.apiKey,
    this.isConfigured = false,
    this.isLoading = false,
    this.isTestingKey = false,
    this.errorMessage,
    this.messages = const [],
  });

  GeminiState copyWith({
    String? apiKey,
    bool clearApiKey = false,
    bool? isConfigured,
    bool? isLoading,
    bool? isTestingKey,
    String? errorMessage,
    List<AiChatMessage>? messages,
  }) {
    return GeminiState(
      apiKey: clearApiKey ? null : apiKey ?? this.apiKey,
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      isTestingKey: isTestingKey ?? this.isTestingKey,
      errorMessage: errorMessage,
      messages: messages ?? this.messages,
    );
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final geminiProvider = StateNotifierProvider<GeminiNotifier, GeminiState>((ref) {
  final service = ref.watch(geminiServiceProvider);
  return GeminiNotifier(ref, service);
});

class GeminiNotifier extends StateNotifier<GeminiState> {
  final Ref _ref;
  final GeminiService _service;

  static const _uuid = Uuid();

  GeminiNotifier(this._ref, this._service) : super(const GeminiState()) {
    init();
  }

  Future<void> init() async {
    final key = await _service.getApiKey();
    final hasKey = key != null && key.trim().isNotEmpty;
    state = state.copyWith(
      apiKey: key,
      isConfigured: hasKey,
      messages: [
        AiChatMessage(
          id: _uuid.v4(),
          text: 'Halo! Saya **Asisten Finansial Cerdas** Anda bertenaga Google Gemini. 🤖✨\n\n'
              'Saya siap menganalisa catatan keuangan, mendeteksi kebocoran anggaran, memberikan tips berhemat praktis, atau menjawab pertanyaan apa pun seputar kondisi keuangan Anda.\n\n'
              'Pilih salah satu **Analisis Cepat** di atas atau ketik pertanyaan Anda di bawah!',
          isUser: false,
          timestamp: DateTime.now(),
        )
      ],
    );
  }

  Future<void> saveApiKey(String key) async {
    final cleanKey = key.trim();
    await _service.saveApiKey(cleanKey);
    state = state.copyWith(
      apiKey: cleanKey,
      isConfigured: cleanKey.isNotEmpty,
      errorMessage: null,
    );
  }

  Future<void> removeApiKey() async {
    await _service.removeApiKey();
    state = state.copyWith(
      clearApiKey: true,
      isConfigured: false,
      errorMessage: null,
    );
  }

  Future<bool> testApiKey(String key) async {
    state = state.copyWith(isTestingKey: true, errorMessage: null);
    try {
      final isValid = await _service.testApiKey(key);
      state = state.copyWith(isTestingKey: false);
      return isValid;
    } catch (e) {
      state = state.copyWith(
        isTestingKey: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  void clearChat() {
    state = state.copyWith(
      messages: [
        AiChatMessage(
          id: _uuid.v4(),
          text: 'Percakapan telah direset. Silakan ajukan pertanyaan atau pilih analisis baru seputar keuangan Anda! 📊',
          isUser: false,
          timestamp: DateTime.now(),
        )
      ],
    );
  }

  Future<void> sendPrompt(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return;

    if (state.apiKey == null || state.apiKey!.trim().isEmpty) {
      final userMsg = AiChatMessage(
        id: _uuid.v4(),
        text: cleanPrompt,
        isUser: true,
        timestamp: DateTime.now(),
      );
      final errorMsg = AiChatMessage(
        id: _uuid.v4(),
        text: '⚠️ **Gemini API Key Belum Diatur**\n\n'
            'Silakan masukkan Google Gemini API Key Anda terlebih dahulu dengan menekan tombol **Atur API Key** di pojok kanan atas.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      state = state.copyWith(
        messages: [...state.messages, userMsg, errorMsg],
      );
      return;
    }

    final userMsg = AiChatMessage(
      id: _uuid.v4(),
      text: cleanPrompt,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      messages: [...state.messages, userMsg],
    );

    try {
      // 1. Gather current financial data from Riverpod providers
      final pockets = requireFinancialData(_ref.read(pocketProvider));
      final transactions = requireFinancialData(_ref.read(transactionProvider));

      // Calculate totals
      final totalBalance = pockets.fold<double>(0.0, (sum, p) => sum + p.currentBalance);

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthlyTx = transactions.where((tx) =>
          tx.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfMonth.add(const Duration(seconds: 1)))).toList();

      final monthlyIncome = monthlyTx
          .where((tx) => tx.isIncome)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);

      final monthlyExpense = monthlyTx
          .where((tx) => tx.isExpense)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);

      final expenseByCategory = <String, double>{};
      final incomeByCategory = <String, double>{};
      final merchantTotals = <String, double>{};

      for (final tx in monthlyTx) {
        if (tx.isExpense) {
          expenseByCategory[tx.category] = (expenseByCategory[tx.category] ?? 0.0) + tx.amount;
          if (tx.merchant.trim().isNotEmpty) {
            final m = tx.merchant.trim();
            merchantTotals[m] = (merchantTotals[m] ?? 0.0) + tx.amount;
          }
        } else if (tx.isIncome) {
          incomeByCategory[tx.category] = (incomeByCategory[tx.category] ?? 0.0) + tx.amount;
        }
      }

      final topMerchants = merchantTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 2. Build structured financial context
      final financialContext = GeminiService.buildFinancialContext(
        pockets: pockets,
        transactions: transactions,
        totalBalance: totalBalance,
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        expenseByCategory: expenseByCategory,
        incomeByCategory: incomeByCategory,
        topMerchants: topMerchants,
      );

      // 3. Prepare recent chat history (last 6 turns, omitting errors)
      final history = <Map<String, String>>[];
      final validPrevious = state.messages
          .where((m) => !m.isError && m.id != userMsg.id)
          .toList();

      for (final msg in validPrevious.reversed.take(6).toList().reversed) {
        history.add({
          'role': msg.isUser ? 'user' : 'model',
          'text': msg.text,
        });
      }

      // 4. Call Gemini
      final responseText = await _service.askGemini(
        apiKey: state.apiKey!,
        prompt: cleanPrompt,
        financialContext: financialContext,
        chatHistory: history,
      );

      final assistantMsg = AiChatMessage(
        id: _uuid.v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, assistantMsg],
      );
    } catch (e) {
      final errText = e.toString().replaceFirst('Exception: ', '');
      final errorMsg = AiChatMessage(
        id: _uuid.v4(),
        text: '❌ **Gagal Menganalisa Keuangan**\n\n$errText',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: errText,
        messages: [...state.messages, errorMsg],
      );
    }
  }
}
