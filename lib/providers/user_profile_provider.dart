import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AvatarPreset {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;

  const AvatarPreset({
    required this.label,
    required this.icon,
    required this.gradientColors,
  });
}

class UserProfileState {
  final String name;
  final String avatarType; // 'preset' or 'custom'
  final int presetIndex;
  final String? customImagePath;

  const UserProfileState({
    required this.name,
    required this.avatarType,
    required this.presetIndex,
    this.customImagePath,
  });

  UserProfileState copyWith({
    String? name,
    String? avatarType,
    int? presetIndex,
    String? customImagePath,
  }) {
    return UserProfileState(
      name: name ?? this.name,
      avatarType: avatarType ?? this.avatarType,
      presetIndex: presetIndex ?? this.presetIndex,
      customImagePath: customImagePath ?? this.customImagePath,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyName = 'user_profile_name';
  static const String _keyAvatarType = 'user_profile_avatar_type';
  static const String _keyPresetIndex = 'user_profile_preset_index';
  static const String _keyCustomPath = 'user_profile_custom_path';

  static const List<AvatarPreset> presets = [
    AvatarPreset(
      label: 'Klasik',
      icon: Icons.person,
      gradientColors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
    ),
    AvatarPreset(
      label: 'Dompet',
      icon: Icons.account_balance_wallet,
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    AvatarPreset(
      label: 'Roket',
      icon: Icons.rocket_launch,
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    ),
    AvatarPreset(
      label: 'Bintang Emas',
      icon: Icons.star_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
    AvatarPreset(
      label: 'Hati',
      icon: Icons.favorite_rounded,
      gradientColors: [Color(0xFFEF4444), Color(0xFFF87171)],
    ),
    AvatarPreset(
      label: 'Premium',
      icon: Icons.workspace_premium_rounded,
      gradientColors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
    ),
  ];

  UserProfileNotifier()
      : super(const UserProfileState(
          name: 'Keuangan Saya',
          avatarType: 'preset',
          presetIndex: 0,
          customImagePath: null,
        )) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await _storage.read(key: _keyName);
      final avatarType = await _storage.read(key: _keyAvatarType);
      final presetIndexStr = await _storage.read(key: _keyPresetIndex);
      final customPath = await _storage.read(key: _keyCustomPath);

      state = UserProfileState(
        name: name ?? 'Keuangan Saya',
        avatarType: avatarType ?? 'preset',
        presetIndex: presetIndexStr != null ? int.tryParse(presetIndexStr) ?? 0 : 0,
        customImagePath: customPath,
      );
    } catch (_) {}
  }

  Future<void> updateName(String newName) async {
    state = state.copyWith(name: newName);
    await _storage.write(key: _keyName, value: newName);
  }

  Future<void> setPresetAvatar(int index) async {
    state = state.copyWith(
      avatarType: 'preset',
      presetIndex: index,
    );
    await _storage.write(key: _keyAvatarType, value: 'preset');
    await _storage.write(key: _keyPresetIndex, value: index.toString());
  }

  Future<void> setCustomImage(String path) async {
    state = state.copyWith(
      avatarType: 'custom',
      customImagePath: path,
    );
    await _storage.write(key: _keyAvatarType, value: 'custom');
    await _storage.write(key: _keyCustomPath, value: path);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier();
});
