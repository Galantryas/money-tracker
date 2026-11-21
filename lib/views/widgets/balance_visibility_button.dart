import 'package:flutter/material.dart';

class BalanceVisibilityButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const BalanceVisibilityButton({super.key, required this.isVisible, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isVisible ? 'Sembunyikan saldo' : 'Tampilkan saldo',
      onPressed: onPressed,
      icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white, size: 20),
    );
  }
}
