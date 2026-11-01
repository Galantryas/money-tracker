import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/utils/currency_formatter.dart';
import '../models/transaction_model.dart';
import '../providers/pocket_provider.dart';

class GeminiService {
  static const String _storageKey = 'gemini_api_key';
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  GeminiService({
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  // Primary models to try
  static const List<String> fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-pro',
  ];

  /// Get saved API Key
  Future<String?> getApiKey() async {
    try {
      return await _secureStorage.read(key: _storageKey);
    } catch (_) {
      return null;
    }
  }

  /// Save API Key securely
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _storageKey, value: apiKey.trim());
  }

  /// Delete saved API Key
  Future<void> removeApiKey() async {
    await _secureStorage.delete(key: _storageKey);
  }

  /// Query available models from Google Gemini API (ModelService.ListModels)
  Future<List<String>> getAvailableModels(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception('API Key tidak boleh kosong.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey',
    );

    try {
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final modelsList = data['models'] as List?;
        if (modelsList != null) {
          final supported = <String>[];
          for (final m in modelsList) {
            final methods = m['supportedGenerationMethods'] as List?;
            final name = m['name'] as String?;
            if (name != null && methods != null && methods.contains('generateContent')) {
              // Format is typically 'models/gemini-2.5-flash' -> convert to 'gemini-2.5-flash'
              final cleanName = name.replaceFirst('models/', '');
              if (isChatModel(cleanName)) {
                supported.add(cleanName);
              }
            }
          }
          if (supported.isNotEmpty) {
            return supported;
          }
        }
        return List.from(fallbackModels);
      }

      final errorBody = _parseErrorMessage(response.statusCode, response.body);
      throw Exception(errorBody);
    } on SocketException {
      throw Exception('Gagal menghubungkan. Periksa koneksi internet perangkat Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan periksa jaringan dan coba lagi.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Check whether model is a general conversational chat model (not TTS, image, audio, embedding)
  static bool isChatModel(String model) {
    final m = model.toLowerCase();
    if (m.contains('tts') ||
        m.contains('embed') ||
        m.contains('image') ||
        m.contains('imagen') ||
        m.contains('audio') ||
        m.contains('transcribe') ||
        m.contains('realtime') ||
        m.contains('robotics')) {
      return false;
    }
    return true;
  }

  /// Priority score for sorting available models
  static int _modelPriorityScore(String model) {
    final m = model.toLowerCase();
    if (!isChatModel(m)) return -1;

    // Exact matches
    if (m == 'gemini-2.5-flash') return 1000;
    if (m == 'gemini-2.0-flash') return 900;
    if (m == 'gemini-2.5-pro') return 800;
    if (m == 'gemini-2.0-flash-lite') return 750;

    // Pattern matches (clean chat models)
    if (m.contains('2.5-flash')) return 500;
    if (m.contains('2.0-flash')) return 400;
    if (m.contains('2.5-pro')) return 300;
    if (m.contains('flash')) return 200;
    if (m.contains('pro')) return 100;
    return 10;
  }

  /// Test whether an API Key is valid by querying available models
  Future<bool> testApiKey(String apiKey) async {
    final models = await getAvailableModels(apiKey);
    return models.isNotEmpty;
  }

  /// Build structured financial context text for Gemini prompt
  static String buildFinancialContext({
    required List<PocketWithBalance> pockets,
    required List<TransactionModel> transactions,
    required double totalBalance,
    required double monthlyIncome,
    required double monthlyExpense,
    required Map<String, double> expenseByCategory,
    required Map<String, double> incomeByCategory,
    required List<MapEntry<String, double>> topMerchants,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== DATA KEUANGAN PENGGUNA TERBARU ===');
    buffer.writeln('- Total Saldo Seluruh Kantong: ${CurrencyFormatter.format(totalBalance)}');
    buffer.writeln('- Total Pemasukan Bulan Ini: ${CurrencyFormatter.format(monthlyIncome)}');
    buffer.writeln('- Total Pengeluaran Bulan Ini: ${CurrencyFormatter.format(monthlyExpense)}');
    final netCashflow = monthlyIncome - monthlyExpense;
    buffer.writeln('- Arus Kas Bersih (Nett): ${CurrencyFormatter.format(netCashflow)} (${netCashflow >= 0 ? "Surplus" : "Defisit"})');

    buffer.writeln('\n--- RINCIAN KANTONG ---');
    if (pockets.isEmpty) {
      buffer.writeln('(Belum ada kantong)');
    } else {
      for (final p in pockets) {
        final limitInfo = p.pocket.budgetLimit != null
            ? ' (Batas Anggaran: ${CurrencyFormatter.format(p.pocket.budgetLimit!)}, Penggunaan: ${((p.budgetUsagePercentage ?? 0) * 100).toStringAsFixed(1)}%)'
            : '';
        buffer.writeln('- ${p.pocket.name}: Saldo ${CurrencyFormatter.format(p.currentBalance)}$limitInfo');
      }
    }

    buffer.writeln('\n--- PENGELUARAN PER KATEGORI (BULAN INI) ---');
    if (expenseByCategory.isEmpty) {
      buffer.writeln('(Belum ada pengeluaran bulan ini)');
    } else {
      final totalExp = monthlyExpense > 0 ? monthlyExpense : 1.0;
      expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          final pct = (entry.value / totalExp * 100).toStringAsFixed(1);
          buffer.writeln('- ${entry.key}: ${CurrencyFormatter.format(entry.value)} ($pct%)');
        });
    }

    buffer.writeln('\n--- PEMASUKAN PER KATEGORI (BULAN INI) ---');
    if (incomeByCategory.isEmpty) {
      buffer.writeln('(Belum ada pemasukan bulan ini)');
    } else {
      incomeByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          buffer.writeln('- ${entry.key}: ${CurrencyFormatter.format(entry.value)}');
        });
    }

    buffer.writeln('\n--- MERCHANT DENGAN PENGELUARAN TERBESAR ---');
    if (topMerchants.isEmpty) {
      buffer.writeln('(Belum ada data merchant)');
    } else {
      for (final m in topMerchants.take(5)) {
        buffer.writeln('- ${m.key}: ${CurrencyFormatter.format(m.value)}');
      }
    }

    buffer.writeln('\n--- 30 TRANSAKSI TERAKHIR ---');
    final recent = transactions.take(30).toList();
    if (recent.isEmpty) {
      buffer.writeln('(Belum ada riwayat transaksi)');
    } else {
      for (final tx in recent) {
        final dateStr = '${tx.date.day}/${tx.date.month}/${tx.date.year}';
        final typeStr = tx.isExpense ? 'Pengeluaran' : (tx.isIncome ? 'Pemasukan' : 'Transfer');
        final noteStr = tx.note.isNotEmpty ? ' (${tx.note})' : '';
        final merchStr = tx.merchant.isNotEmpty ? ' di ${tx.merchant}' : '';
        buffer.writeln('• [$dateStr] $typeStr: ${CurrencyFormatter.format(tx.amount)} | Kat: ${tx.category}$merchStr$noteStr');
      }
    }

    return buffer.toString();
  }

  /// Send prompt to Gemini API with automatic model fallback
  Future<String> askGemini({
    required String apiKey,
    required String prompt,
    String? financialContext,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception('API Key Gemini belum diatur. Silakan atur API Key terlebih dahulu.');
    }

    // Determine models supported by user's API key
    List<String> modelsToTry = [];
    try {
      final dynamicModels = await getAvailableModels(cleanKey);
      dynamicModels.sort((a, b) => _modelPriorityScore(b).compareTo(_modelPriorityScore(a)));
      modelsToTry = dynamicModels;
    } catch (_) {
      modelsToTry = List.from(fallbackModels);
    }

    if (modelsToTry.isEmpty) {
      modelsToTry = List.from(fallbackModels);
    }

    const systemInstruction = '''
Anda adalah Asisten Keuangan Pribadi (AI Financial Advisor) cerdas, bijak, ramah, dan solutif pada aplikasi Money Tracker.
Tugas Anda adalah:
1. Menganalisa data keuangan pengguna secara objektif, akurat, dan berbasis angka riil yang disediakan.
2. Memberikan evaluasi kondisi finansial (arus kas, kebiasaan belanja, alokasi anggaran, tabungan).
3. Mendeteksi kebocoran finansial, pengeluaran berlebihan, atau potensi risiko overbudget.
4. Memberikan rekomendasi penghematan praktis, terukur, dan strategi alokasi dana (misal konsep 50/30/20 atau dana darurat).
5. Berikan jawaban dalam Bahasa Indonesia yang santun, memotivasi, terstruktur rapi dengan poin-poin (bullet points), tebal untuk angka/istilah penting, dan mudah dipahami.
''';

    // Construct request contents
    final contents = <Map<String, dynamic>>[];

    // Include chat history
    for (final msg in chatHistory) {
      contents.add({
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': msg['text']}
        ]
      });
    }

    // Include current prompt with financial context
    final currentPromptText = financialContext != null && financialContext.isNotEmpty
        ? '$financialContext\n\n--- PERTANYAAN / PERMINTAAN PENGGUNA ---\n$prompt'
        : prompt;

    contents.add({
      'role': 'user',
      'parts': [
        {'text': currentPromptText}
      ]
    });

    final payload = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      }
    };

    String? lastError;

    // Try available models in order
    for (final model in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanKey',
      );

      try {
        final response = await _httpClient
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final candidate = candidates[0];
            final content = candidate['content'];
            if (content != null) {
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.trim().isNotEmpty) {
                  return text.trim();
                }
              }
            }
          }
          throw Exception('Gemini tidak memberikan respon teks.');
        }

        // If 404 model not found, or model doesn't support chat / multi-turn, continue loop to next model
        if (response.statusCode == 404 ||
            (response.statusCode == 400 &&
                (response.body.contains('not enabled') ||
                    response.body.contains('not supported') ||
                    response.body.contains('Multiturn') ||
                    response.body.contains('chat')))) {
          lastError = 'Model $model tidak mendukung percakapan chat.';
          continue;
        }

        // Other status codes (e.g. 400 invalid key, 429 quota)
        final errorMsg = _parseErrorMessage(response.statusCode, response.body);
        throw Exception(errorMsg);
      } on SocketException {
        throw Exception('Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.');
      } on TimeoutException {
        throw Exception('Waktu permintaan habis (Timeout). Silakan coba beberapa saat lagi.');
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }

    throw Exception(lastError ?? 'Gagal memproses analisis dengan Gemini AI.');
  }

  static String _parseErrorMessage(int statusCode, String body) {
    try {
      final data = jsonDecode(body);
      final error = data['error'];
      if (error != null) {
        final message = error['message'] as String? ?? '';
        final status = error['status'] as String? ?? '';

        if (statusCode == 400 || status == 'INVALID_ARGUMENT') {
          if (message.toLowerCase().contains('api key')) {
            return 'API Key Gemini tidak valid. Silakan periksa kembali API Key Anda dari Google AI Studio.';
          }
          return 'Permintaan tidak valid: $message';
        }

        if (statusCode == 403 || status == 'PERMISSION_DENIED') {
          return 'Akses ditolak. Pastikan API Key Anda memiliki izin untuk Gemini API.';
        }

        if (statusCode == 429 || status == 'RESOURCE_EXHAUSTED') {
          return 'Batas kuota Gemini API tercapai (Rate Limit). Silakan tunggu sebentar lalu coba kembali.';
        }

        if (message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    switch (statusCode) {
      case 400:
        return 'API Key Gemini tidak valid (HTTP 400). Periksa kunci API Anda.';
      case 403:
        return 'Izin ditolak (HTTP 403). Periksa batasan API Key Anda.';
      case 429:
        return 'Kuota permintaan Gemini API terlampaui (HTTP 429). Silakan coba lagi nanti.';
      case 500:
      case 503:
        return 'Layanan Gemini Google sedang sibuk atau mengalami kendala (HTTP $statusCode).';
      default:
        return 'Terjadi kendala saat menghubungi Gemini AI (HTTP $statusCode).';
    }
  }
}
