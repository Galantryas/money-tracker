import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:money_tracker/models/pocket.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/pocket_provider.dart';
import 'package:money_tracker/services/gemini_service.dart';

void main() {
  group('Gemini response handling', () {
    test('returns every text part and flags a truncated answer', () async {
      Map<String, dynamic>? sentPayload;
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'models': [
            {'name': 'models/gemini-2.5-flash', 'supportedGenerationMethods': ['generateContent']}
          ]}), 200);
        }
        sentPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'candidates': [
          {'finishReason': 'MAX_TOKENS', 'content': {'parts': [
            {'text': 'First part. '}, {'text': 'Second part.'}
          ]}}
        ]}), 200);
      });
      final service = GeminiService(httpClient: client);

      final response = await service.askGemini(apiKey: 'key', prompt: 'Explain');

      expect(response, contains('First part. Second part.'));
      expect(response.toLowerCase(), contains('terpotong'));
      expect(sentPayload!['generationConfig']['maxOutputTokens'], greaterThan(2048));
      client.close();
    });

    test('does not include thought parts in the visible response', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'models': [
            {'name': 'models/gemini-2.5-flash', 'supportedGenerationMethods': ['generateContent']}
          ]}), 200);
        }
        return http.Response(jsonEncode({'candidates': [
          {'finishReason': 'STOP', 'content': {'parts': [
            {'text': 'internal', 'thought': true}, {'text': 'Final answer.'}
          ]}}
        ]}), 200);
      });
      final service = GeminiService(httpClient: client);
      expect(await service.askGemini(apiKey: 'key', prompt: 'Explain'), 'Final answer.');
      client.close();
    });
  });

  group('GeminiService Financial Context Tests', () {
    test('buildFinancialContext formats numbers and sections correctly', () {
      final now = DateTime.now();
      final pocket1 = Pocket(
        id: 'p-1',
        name: 'BCA Utama',
        iconName: 'account_balance',
        colorValue: 0xFF6366F1,
        initialBalance: 5000000,
        budgetLimit: 3000000,
        createdAt: now,
      );

      final pwb = PocketWithBalance(
        pocket: pocket1,
        currentBalance: 4500000,
        incomeThisMonth: 1000000,
        spentThisMonth: 1500000,
      );

      final tx1 = TransactionModel(
        id: 'tx-1',
        pocketId: 'p-1',
        type: 'expense',
        amount: 50000,
        category: 'Makanan & Minuman',
        merchant: 'Gofood',
        note: 'Makan siang',
        date: now,
        createdAt: now,
      );

      final context = GeminiService.buildFinancialContext(
        pockets: [pwb],
        transactions: [tx1],
        totalBalance: 4500000,
        monthlyIncome: 10000000,
        monthlyExpense: 3500000,
        expenseByCategory: {
          'Makanan & Minuman': 2000000,
          'Transportasi': 1500000,
        },
        incomeByCategory: {
          'Gaji': 10000000,
        },
        topMerchants: [
          const MapEntry('Gofood', 1200000),
          const MapEntry('Shopee', 800000),
        ],
      );

      expect(context.contains('DATA KEUANGAN PENGGUNA TERBARU'), isTrue);
      expect(context.contains('Total Saldo Seluruh Kantong: Rp 4.500.000'), isTrue);
      expect(context.contains('Total Pemasukan Bulan Ini: Rp 10.000.000'), isTrue);
      expect(context.contains('Total Pengeluaran Bulan Ini: Rp 3.500.000'), isTrue);
      expect(context.contains('Surplus'), isTrue);
      expect(context.contains('BCA Utama: Saldo Rp 4.500.000'), isTrue);
      expect(context.contains('Makanan & Minuman: Rp 2.000.000'), isTrue);
      expect(context.contains('Gofood: Rp 1.200.000'), isTrue);
      expect(context.contains('• [${now.day}/${now.month}/${now.year}] Pengeluaran: Rp 50.000 | Kat: Makanan & Minuman di Gofood (Makan siang)'), isTrue);
    });

    test('testApiKey throws exception when empty', () async {
      final service = GeminiService();
      expect(() => service.testApiKey('   '), throwsA(isA<Exception>()));
    });
  });
}
