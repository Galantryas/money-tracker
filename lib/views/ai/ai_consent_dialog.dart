import 'package:flutter/material.dart';

Future<bool> showAiConsentDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data yang dikirim ke Gemini'),
          content: const Text(
            'Pertanyaan, riwayat percakapan terbaru, ringkasan saldo dan anggaran, '
            'serta hingga 30 transaksi terakhir termasuk merchant dan catatan akan '
            'dikirim ke Google Gemini untuk menjawab pertanyaan Anda. '
            'Jangan kirim jika Anda tidak ingin membagikan data tersebut.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kirim ke Gemini')),
          ],
        ),
      ) ??
      false;
}
