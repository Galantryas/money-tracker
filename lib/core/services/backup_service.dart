import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

class BackupFileInfo {
  final String fileName;
  final DateTime exportedAt;
  final int pocketCount;
  final int categoryCount;
  final int transactionCount;
  final Map<String, dynamic> rawData;

  BackupFileInfo({
    required this.fileName,
    required this.exportedAt,
    required this.pocketCount,
    required this.categoryCount,
    required this.transactionCount,
    required this.rawData,
  });
}

class BackupService {
  /// Ekspor seluruh data SQLite menjadi berkas JSON dan buka dialog Berbagi / Simpan
  static Future<File> createBackupAndShare() async {
    final rawData = await AppDatabase.instance.exportAllData();
    final now = DateTime.now();
    final nowFormatted = DateFormat('yyyyMMdd_HHmmss').format(now);

    final pockets = rawData['pockets'] as List? ?? [];
    final categories = rawData['categories'] as List? ?? [];
    final transactions = rawData['transactions'] as List? ?? [];

    final backupPayload = {
      'app': 'Money Tracker',
      'version': 1,
      'exported_at': now.toIso8601String(),
      'summary': {
        'total_pockets': pockets.length,
        'total_categories': categories.length,
        'total_transactions': transactions.length,
      },
      'data': rawData,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'money_tracker_backup_$nowFormatted.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonString);

    // Buka dialog share sistem (Google Drive, WhatsApp, Simpan ke File, dsb.)
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Cadangan Data Money Tracker ($nowFormatted)',
      text: 'Berkas cadangan data keuangan Money Tracker - $nowFormatted',
    );

    return file;
  }

  /// Membuka file picker untuk memilih berkas backup JSON dan memvalidasi isinya
  static Future<BackupFileInfo?> pickAndValidateBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final pickedFile = result.files.single;
    String content;

    if (pickedFile.path != null) {
      final file = File(pickedFile.path!);
      content = await file.readAsString();
    } else if (pickedFile.bytes != null) {
      content = utf8.decode(pickedFile.bytes!);
    } else {
      throw Exception('Tidak dapat membaca berkas cadangan yang dipilih.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      throw Exception('Format berkas tidak valid. Berkas harus berupa file JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Struktur berkas cadangan salah.');
    }

    if (decoded['app'] != 'Money Tracker' || decoded['data'] == null) {
      throw Exception('Berkas ini bukan cadangan Money Tracker yang valid.');
    }

    final rawData = decoded['data'] as Map<String, dynamic>;
    final pockets = rawData['pockets'] as List? ?? [];
    final categories = rawData['categories'] as List? ?? [];
    final transactions = rawData['transactions'] as List? ?? [];

    DateTime exportedAt = DateTime.now();
    if (decoded['exported_at'] != null) {
      try {
        exportedAt = DateTime.parse(decoded['exported_at']);
      } catch (_) {}
    }

    return BackupFileInfo(
      fileName: pickedFile.name,
      exportedAt: exportedAt,
      pocketCount: pockets.length,
      categoryCount: categories.length,
      transactionCount: transactions.length,
      rawData: rawData,
    );
  }

  /// Memulihkan database dari informasi backup yang telah divalidasi
  static Future<void> restore(BackupFileInfo backupInfo) async {
    await AppDatabase.instance.restoreAllData(backupInfo.rawData);
  }
}
