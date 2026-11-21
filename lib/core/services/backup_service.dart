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
  static Map<String, dynamic> validatePayload(dynamic decoded) {
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'Money Tracker' ||
        (decoded['version'] != null && decoded['version'] != 1) ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Berkas cadangan tidak valid atau versinya tidak didukung.');
    }
    final data = decoded['data'] as Map<String, dynamic>;
    const requiredFields = <String, Map<String, Type>>{
      'pockets': {'id': String, 'name': String, 'icon_name': String, 'color_value': num, 'initial_balance': num, 'created_at': String},
      'categories': {'id': String, 'name': String, 'icon_name': String, 'color_value': num, 'type': String},
      'transactions': {'id': String, 'pocket_id': String, 'type': String, 'amount': num, 'category': String, 'note': String, 'merchant': String, 'date': String, 'created_at': String},
    };
    for (final section in requiredFields.entries) {
      final rows = data[section.key];
      if (rows is! List) throw Exception('Bagian ${section.key} tidak lengkap.');
      final ids = <String>{};
      for (final row in rows) {
        if (row is! Map<String, dynamic>) throw Exception('Data ${section.key} tidak valid.');
        for (final field in section.value.entries) {
          final value = row[field.key];
          if ((field.value == String && value is! String) ||
              (field.value == num && value is! num)) {
            throw Exception('Data ${section.key}.${field.key} tidak valid.');
          }
        }
        if (!ids.add(row['id'] as String)) throw Exception('ID ganda pada ${section.key}.');
        for (final key in ['date', 'created_at']) {
          if (row.containsKey(key) && DateTime.tryParse(row[key] as String) == null) {
            throw Exception('Tanggal pada ${section.key} tidak valid.');
          }
        }
      }
    }
    if (data.containsKey('category_budgets')) {
      final budgets = data['category_budgets'];
      if (budgets is! List) throw Exception('Data anggaran tidak valid.');
      final names = <String>{};
      for (final row in budgets) {
        if (row is! Map || row['category'] is! String ||
            (row['category'] as String).trim().isEmpty ||
            row['monthly_limit'] is! num || !(row['monthly_limit'] as num).isFinite ||
            (row['monthly_limit'] as num) <= 0 || !names.add(row['category'] as String)) {
          throw Exception('Data anggaran tidak valid.');
        }
      }
    }
    return data;
  }

  static int countMissingPocketReferences(Map<String, dynamic> data) {
    final pocketIds = (data['pockets'] as List).map((p) => p['id']).toSet();
    return (data['transactions'] as List).where((tx) =>
        !pocketIds.contains(tx['pocket_id']) ||
        (tx['target_pocket_id'] != null && !pocketIds.contains(tx['target_pocket_id']))).length;
  }

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

    final rawData = validatePayload(decoded);
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
    validatePayload({'app': 'Money Tracker', 'version': 1, 'data': backupInfo.rawData});
    await AppDatabase.instance.restoreAllData(backupInfo.rawData);
  }
}
