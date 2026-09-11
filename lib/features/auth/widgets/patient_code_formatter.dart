// lib/features/auth/widgets/patient_code_formatter.dart
//
// Custom TextInputFormatter that auto-formats Patient Access Codes
// into the clean, readable format: SMR-XXXX-YY as the user types.

import 'package:flutter/services.dart';

class PatientCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (text.isEmpty) {
      return const TextEditingValue();
    }

    // Strip existing prefix if user typed it
    if (text.startsWith('SMR')) {
      text = text.substring(3);
    }

    // Limit body to 6 characters (4 chars group 1, 2 chars group 2)
    if (text.length > 6) {
      text = text.substring(0, 6);
    }

    final buffer = StringBuffer('SMR');
    if (text.isNotEmpty) {
      buffer.write('-');
      if (text.length <= 4) {
        buffer.write(text);
      } else {
        buffer.write(text.substring(0, 4));
        buffer.write('-');
        buffer.write(text.substring(4));
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
