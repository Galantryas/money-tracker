import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/transaction_csv_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gemini_provider.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_budget_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../ai/ai_advisor_screen.dart';
import '../widgets/user_avatar_widget.dart';
import 'edit_profile_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSetPinDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Atur PIN Keamanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan 4 digit PIN baru untuk fallback saat sidik jari tidak dapat digunakan:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.length != 4) {
                    return 'PIN harus terdiri dari 4 digit angka';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(authProvider.notifier).setPin(pinController.text.trim());
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF10B981),
                      content: Text('PIN keamanan berhasil diperbarui!'),
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactionsCsv(BuildContext context, WidgetRef ref) async {
    final state = ref.read(transactionProvider);
    if (state.valueOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data transaksi belum tersedia. Coba lagi.')),
      );
      return;
    }
    final transactions = state.valueOrNull!;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi untuk diekspor')),
      );
      return;
    }

    try {
      await TransactionCsvService.share(transactions);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membagikan CSV. Silakan coba lagi.')),
        );
      }
    }
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 16),
                  Text('Menyiapkan berkas cadangan...'),
                ],
              ),
            ),
          ),
        ),
      );

      final file = await BackupService.createBackupAndShare();

      if (context.mounted) {
        Navigator.pop(context); // tutup dialog loading
        final fileName = file.path.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berkas cadangan siap: $fileName'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // tutup dialog jika masih terbuka
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencadangkan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    var isRestoring = false;
    try {
      final backupInfo = await BackupService.pickAndValidateBackup();
      if (backupInfo == null) {
        return;
      }

      if (!context.mounted) return;

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Konfirmasi Pemulihan', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin memulihkan data dari berkas ini? Seluruh data saat ini akan digantikan dengan data cadangan.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Berkas: ${backupInfo.fileName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Waktu Cadangan: ${DateFormatter.formatShort(backupInfo.exportedAt)}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Jumlah Kantong: ${backupInfo.pocketCount}', style: const TextStyle(fontSize: 12)),
                    Text('Jumlah Kategori: ${backupInfo.categoryCount}', style: const TextStyle(fontSize: 12)),
                    Text('Jumlah Transaksi: ${backupInfo.transactionCount}', style: const TextStyle(fontSize: 12)),
                    if (BackupService.countMissingPocketReferences(backupInfo.rawData) > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${BackupService.countMissingPocketReferences(backupInfo.rawData)} transaksi merujuk ke kantong yang tidak ada. Data akan dipertahankan, tetapi saldo atau laporan mungkin tidak lengkap.',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pulihkan Data'),
            ),
          ],
        ),
      );

      if (shouldRestore == true) {
        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 16),
                    Text('Memulihkan data...'),
                  ],
                ),
              ),
            ),
          ),
        );
        isRestoring = true;

        await BackupService.restore(backupInfo);

        // Refresh providers agar UI seketika terupdate
        ref.invalidate(pocketProvider);
        ref.invalidate(transactionProvider);
        ref.invalidate(categoryBudgetLimitsProvider);
        ref.invalidate(categoriesProvider);

        if (context.mounted) {
          Navigator.pop(context); // tutup dialog loading
          isRestoring = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data berhasil dipulihkan! (${backupInfo.pocketCount} kantong, ${backupInfo.transactionCount} transaksi)',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (isRestoring) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final userProfile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeProvider);
    final reminderState = ref.watch(reminderProvider);
    final geminiState = ref.watch(geminiProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Purple Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1), // Indigo header
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                children: [
                  // Section Profil Akun
                  const Text(
                    'Profil Akun',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const EditProfileDialog(),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          UserAvatarWidget(profile: userProfile, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Ketuk untuk ubah nama & foto profil',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Keamanan
                  const Text(
                    'Keamanan Aplikasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: const Color(0xFF6366F1),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF6366F1), size: 20),
                          ),
                          title: const Text('Kunci Sidik Jari (Biometrik)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Kunci aplikasi saat dibuka demi privasi', style: TextStyle(fontSize: 12)),
                          value: authState.isBiometricEnabled,
                          onChanged: (val) {
                            ref.read(authProvider.notifier).setBiometricEnabled(val);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pin_outlined, color: Colors.amber, size: 20),
                          ),
                          title: const Text('Atur / Ganti PIN Fallback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(authState.hasPin ? 'PIN sudah diatur' : 'PIN bawaan aktif', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _showSetPinDialog(context, ref),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_clock_outlined, color: Colors.blueGrey, size: 20),
                          ),
                          title: const Text('Uji Coba Kunci Sekarang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Kunci dan buka aplikasi kembali', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            ref.read(authProvider.notifier).lockApp();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Pengingat Harian
                  const Text(
                    'Pengingat & Alarm Harian',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: const Color(0xFF6366F1),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF818CF8).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alarm_rounded, color: Color(0xFF818CF8), size: 20),
                          ),
                          title: const Text('Alarm Pengingat Catat Keuangan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            reminderState.errorMessage ?? 'Notifikasi pengingat setiap hari',
                            style: TextStyle(fontSize: 12, color: reminderState.errorMessage == null ? null : Colors.red),
                          ),
                          value: reminderState.isEnabled,
                          onChanged: (val) {
                            ref.read(reminderProvider.notifier).toggleReminder(val);
                          },
                        ),
                        if (reminderState.isEnabled) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF6366F1), size: 20),
                            ),
                            title: const Text('Jam Pengingat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              'Pukul ${reminderState.time.hour.toString().padLeft(2, '0')}:${reminderState.time.minute.toString().padLeft(2, '0')} waktu perangkat',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: reminderState.time,
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                await ref.read(reminderProvider.notifier).setTime(picked);
                                if (context.mounted && ref.read(reminderProvider).errorMessage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF6366F1),
                                      content: Text(
                                        'Waktu pengingat disetel ke ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} waktu perangkat',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF10B981), size: 20),
                            ),
                            title: const Text('Uji Coba Notifikasi Sekarang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Kirim notifikasi contoh ke ponsel', style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () async {
                              try {
                                await ref.read(reminderProvider.notifier).testNotification();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Notifikasi contoh telah dikirimkan ke ponsel Anda!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal mengirim notifikasi: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Tampilan
                  const Text(
                    'Tampilan & Tema',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          activeColor: const Color(0xFF6366F1),
                          secondary: const Icon(Icons.brightness_auto_outlined),
                          title: const Text('Ikuti Sistem Operasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          value: ThemeMode.system,
                          groupValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          activeColor: const Color(0xFF6366F1),
                          secondary: const Icon(Icons.light_mode_outlined, color: Colors.orange),
                          title: const Text('Tema Terang (Light Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          value: ThemeMode.light,
                          groupValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          activeColor: const Color(0xFF6366F1),
                          secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6366F1)),
                          title: const Text('Tema Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          value: ThemeMode.dark,
                          groupValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) ref.read(themeProvider.notifier).setThemeMode(mode);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Gemini AI
                  const Text(
                    'Kecerdasan Buatan (Gemini AI)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 20),
                          ),
                          title: const Text('Buka Asisten Finansial AI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Analisa keuangan & rekomendasi cerdas', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: geminiState.isConfigured
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : Colors.amber.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.vpn_key_rounded,
                              color: geminiState.isConfigured ? const Color(0xFF10B981) : Colors.amber,
                              size: 20,
                            ),
                          ),
                          title: const Text('Google Gemini API Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            geminiState.isConfigured ? 'API Key Terhubung' : 'Kunci belum diatur (ketuk untuk atur)',
                            style: TextStyle(
                              fontSize: 12,
                              color: geminiState.isConfigured ? const Color(0xFF10B981) : Colors.amber.shade700,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Data & Laporan
                  const Text(
                    'Data & Cadangan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF6366F1), size: 20),
                          ),
                          title: const Text('Cadangkan Data (Backup)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Simpan seluruh kantong & transaksi ke Google Drive/file', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _handleBackup(context, ref),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings_backup_restore_outlined, color: Color(0xFFF59E0B), size: 20),
                          ),
                          title: const Text('Pulihkan Data (Restore)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Muat kembali data dari berkas cadangan JSON', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _handleRestore(context, ref),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981), size: 20),
                          ),
                          title: const Text('Ekspor Laporan Transaksi (CSV)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Rekap data transaksi untuk spreadsheet/Excel', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _exportTransactionsCsv(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Info Aplikasi
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Money Tracker',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Versi 1.0.0',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aplikasi Pencatatan Keuangan Pribadi dengan Kantong Kustom & Biometrik',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
