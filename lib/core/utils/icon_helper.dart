import 'package:flutter/material.dart';

class IconOption {
  final String key;
  final String label;
  final IconData icon;

  const IconOption({required this.key, required this.label, required this.icon});
}

class IconHelper {
  static const List<IconOption> availableIcons = [
    IconOption(key: 'wallet', label: 'Dompet', icon: Icons.account_balance_wallet),
    IconOption(key: 'piggy_bank', label: 'Tabungan', icon: Icons.savings),
    IconOption(key: 'credit_card', label: 'Kartu', icon: Icons.credit_card),
    IconOption(key: 'utensils', label: 'Makan & Minum', icon: Icons.restaurant),
    IconOption(key: 'shopping_bag', label: 'Belanja', icon: Icons.shopping_bag),
    IconOption(key: 'car', label: 'Transportasi', icon: Icons.directions_car),
    IconOption(key: 'receipt', label: 'Tagihan', icon: Icons.receipt_long),
    IconOption(key: 'film', label: 'Hiburan', icon: Icons.movie),
    IconOption(key: 'heart_pulse', label: 'Kesehatan', icon: Icons.favorite),
    IconOption(key: 'book', label: 'Pendidikan', icon: Icons.menu_book),
    IconOption(key: 'banknote', label: 'Gaji', icon: Icons.payments),
    IconOption(key: 'gift', label: 'Hadiah', icon: Icons.card_giftcard),
    IconOption(key: 'family', label: 'Keluarga', icon: Icons.family_restroom),
    IconOption(key: 'trending_up', label: 'Investasi', icon: Icons.trending_up),
    IconOption(key: 'laptop', label: 'Kerja/Bisnis', icon: Icons.laptop_mac),
    IconOption(key: 'home', label: 'Rumah', icon: Icons.home),
    IconOption(key: 'fitness', label: 'Olahraga', icon: Icons.fitness_center),
    IconOption(key: 'flight', label: 'Liburan', icon: Icons.flight),
    IconOption(key: 'more_horizontal', label: 'Lain-lain', icon: Icons.more_horiz),
  ];

  static const List<Color> availableColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEAB308), // Yellow
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFF64748B), // Slate
    Color(0xFF84CC16), // Lime
  ];

  static IconData getIcon(String key) {
    for (var opt in availableIcons) {
      if (opt.key == key) return opt.icon;
    }
    return Icons.category;
  }
}
