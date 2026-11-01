import 'dart:io';
import 'package:flutter/material.dart';
import '../../providers/user_profile_provider.dart';

class UserAvatarWidget extends StatelessWidget {
  final UserProfileState profile;
  final double size;

  const UserAvatarWidget({
    super.key,
    required this.profile,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    if (profile.avatarType == 'custom' &&
        profile.customImagePath != null &&
        File(profile.customImagePath!).existsSync()) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(profile.customImagePath!)),
      );
    }

    final safePresetIndex = (profile.presetIndex >= 0 &&
            profile.presetIndex < UserProfileNotifier.presets.length)
        ? profile.presetIndex
        : 0;
    final preset = UserProfileNotifier.presets[safePresetIndex];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: preset.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: preset.gradientColors.first.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        preset.icon,
        color: Colors.white,
        size: size * 0.54,
      ),
    );
  }
}
