/// Validador de NIT colombiano según el algoritmo oficial de la DIAN.
///
/// Formato esperado: XXXXXXXXX-Y
/// donde X son los 9 dígitos del NIT y Y es el dígito de verificación (0–9).
///
/// Algoritmo:
///   1. Multiplicar cada uno de los 9 dígitos por la secuencia de pesos
///      [71, 67, 59, 53, 47, 43, 41, 37, 29] (de izquierda a derecha).
///   2. Sumar todos los productos.
///   3. Calcular residuo = suma % 11.
///   4. Si residuo >= 2  → DV = 11 - residuo.
///      Si residuo es 0 o 1 → DV = residuo.
///   5. El dígito Y declarado debe coincidir con el DV calculado.
class NitValidator {
  NitValidator._();

  static const List<int> _weights = [71, 67, 59, 53, 47, 43, 41, 37, 29];

  /// Devuelve `true` si el NIT cumple el formato y supera la validación DIAN.
  static bool isValid(String nit) => getError(nit) == null;

  /// Devuelve `null` si el NIT es válido, o un mensaje de error descriptivo.
  static String? getError(String? nit) {
    if (nit == null || nit.trim().isEmpty) return 'El NIT es obligatorio.';
    final trimmed = nit.trim();

    // Verificar formato: 9 dígitos, guion, 1 dígito.
    final formatRegex = RegExp(r'^\d{9}-\d$');
    if (!formatRegex.hasMatch(trimmed)) {
      return 'El NIT debe tener el formato XXXXXXXXX-Y (9 dígitos, guion, dígito de verificación).';
    }

    final parts = trimmed.split('-');
    final digits = parts[0]; // los 9 dígitos
    final declaredDv = int.parse(parts[1]);

    // Calcular el dígito de verificación esperado.
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * _weights[i];
    }

    final residuo = sum % 11;
    final expectedDv = residuo >= 2 ? 11 - residuo : residuo;

    if (declaredDv != expectedDv) {
      return 'El dígito de verificación del NIT no es válido.';
    }

    return null;
  }
}
