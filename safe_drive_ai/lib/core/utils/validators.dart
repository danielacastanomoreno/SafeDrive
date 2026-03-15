import 'nit_validator.dart';

/// Validadores reutilizables para formularios de Safe Drive AI.
///
/// Cada método retorna:
///   - `null`   → el campo es válido.
///   - `String` → mensaje de error en español.
class Validators {
  Validators._();

  // ── Email ──────────────────────────────────────────────────────────────────

  /// Valida formato de correo electrónico y longitud máxima de 100 caracteres.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio.';
    }
    final trimmed = value.trim();
    if (trimmed.length > 100) {
      return 'El correo no puede superar los 100 caracteres.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  // ── Contraseña ─────────────────────────────────────────────────────────────

  /// Valida que la contraseña tenga al menos 8 caracteres, una mayúscula,
  /// una minúscula, un número y un carácter especial (! @ # $ % &).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra mayúscula.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra minúscula.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número.';
    }
    if (!RegExp(r'[!@#$%&]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un carácter especial (! @ # \$ % &).';
    }
    return null;
  }

  // ── Nombre ─────────────────────────────────────────────────────────────────

  /// Valida que el nombre tenga al menos 3 caracteres y solo letras y espacios.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ ]+$').hasMatch(trimmed)) {
      return 'El nombre solo puede contener letras y espacios.';
    }
    return null;
  }

  // ── Cédula ─────────────────────────────────────────────────────────────────

  /// Valida que la cédula tenga entre 6 y 10 dígitos numéricos.
  static String? cedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cédula es obligatoria.';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(trimmed)) {
      return 'La cédula debe tener entre 6 y 10 dígitos numéricos.';
    }
    return null;
  }

  // ── Teléfono ───────────────────────────────────────────────────────────────

  /// Valida que el teléfono tenga exactamente 10 dígitos y comience con 3.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio.';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^3\d{9}$').hasMatch(trimmed)) {
      return 'El teléfono debe tener 10 dígitos y comenzar con 3.';
    }
    return null;
  }

  // ── NIT ────────────────────────────────────────────────────────────────────

  /// Valida el NIT colombiano usando el algoritmo oficial de la DIAN.
  /// Formato esperado: XXXXXXXXX-Y
  static String? nit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El NIT es obligatorio.';
    }
    return NitValidator.getError(value.trim());
  }
}
