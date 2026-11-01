import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String text = newValue.text;

    // Deteksi jika pengguna mengetik karakter shortcut titik (.), koma (,), atau spasi
    // untuk menambahkan '000' secara instan
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    if (newValue.text.length > oldValue.text.length && newValue.selection.end > 0) {
      final lastTypedChar =
          newValue.text.substring(newValue.selection.end - 1, newValue.selection.end);
      if (lastTypedChar == '.' || lastTypedChar == ',' || lastTypedChar == ' ') {
        if (oldDigits.isNotEmpty && oldDigits != '0') {
          text = '${oldDigits}000';
        } else {
          return oldValue;
        }
      }
    }

    // Ambil hanya digit angka
    final cleanDigits = text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Batasi maksimum 15 digit angka untuk mencegah overflow
    final truncatedDigits =
        cleanDigits.length > 15 ? cleanDigits.substring(0, 15) : cleanDigits;

    // Hapus angka 0 di depan (kecuali hanya angka 0)
    final trimmedDigits = truncatedDigits.replaceFirst(RegExp(r'^0+(?!$)'), '');
    if (trimmedDigits.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    // Format dengan titik separator ribuan Indonesia
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < trimmedDigits.length; i++) {
      if (i > 0 && (trimmedDigits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(trimmedDigits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Helper untuk menambahkan '000' langsung dari tombol aksi cepat di antarmuka
  static void appendZeros(TextEditingController controller, {String zeros = '000'}) {
    final currentDigits = controller.text.replaceAll(RegExp(r'\D'), '');
    if (currentDigits.isEmpty || currentDigits == '0') return;

    final newDigits = '$currentDigits$zeros';
    if (newDigits.length > 15) return;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < newDigits.length; i++) {
      if (i > 0 && (newDigits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(newDigits[i]);
    }

    controller.text = buffer.toString();
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }
}
