import 'package:flutter/services.dart';

/// Formateador de entrada para campos NIT colombiano.
///
/// Inserta automáticamente el guion después del noveno dígito.
/// Formato resultante: XXXXXXXXX-Y
/// Máximo 11 caracteres (9 dígitos + guion + 1 dígito verificación).
class NitInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo permite dígitos y el guion
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Máximo 10 dígitos (9 base + 1 verificación)
    final limited =
        digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    // Insertar guion después del dígito 9
    final String formatted;
    if (limited.length <= 9) {
      formatted = limited;
    } else {
      formatted = '${limited.substring(0, 9)}-${limited.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
