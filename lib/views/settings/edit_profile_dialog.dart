import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late TextEditingController _nameController;
  late String _avatarType;
  late int _selectedPreset;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _avatarType = profile.avatarType;
    _selectedPreset = profile.presetIndex;
    _selectedImagePath = profile.customImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _avatarType = 'custom';
          _selectedImagePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Widget _buildAvatarPreview() {
    if (_avatarType == 'custom' && _selectedImagePath != null && File(_selectedImagePath!).existsSync()) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: FileImage(File(_selectedImagePath!)),
      );
    }

    final preset = UserProfileNotifier.presets[_selectedPreset];
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: preset.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(preset.icon, color: Colors.white, size: 44),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.account_circle_outlined, color: Color(0xFF6366F1)),
          SizedBox(width: 8),
          Text('Ubah Profil Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar Preview with Edit Button
              Center(
                child: Stack(
                  children: [
                    _buildAvatarPreview(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Button Pilih dari Galeri
              OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Pilih Foto dari Galeri'),
              ),
              const SizedBox(height: 12),

              // Pilihan Avatar Preset
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Atau Pilih Avatar Preset:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(UserProfileNotifier.presets.length, (index) {
                  final p = UserProfileNotifier.presets[index];
                  final isSelected = _avatarType == 'preset' && _selectedPreset == index;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _avatarType = 'preset';
                        _selectedPreset = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: p.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(p.icon, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Nama Akun Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nama Akun / Panggilan',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Misal: Keuangan Saya, Budi, Farhan',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () async {
            final newName = _nameController.text.trim();
            if (newName.isNotEmpty) {
              await ref.read(userProfileProvider.notifier).updateName(newName);
            }
            if (_avatarType == 'custom' && _selectedImagePath != null) {
              await ref.read(userProfileProvider.notifier).setCustomImage(_selectedImagePath!);
            } else {
              await ref.read(userProfileProvider.notifier).setPresetAvatar(_selectedPreset);
            }

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil akun berhasil diperbarui!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
