import 'package:flutter/material.dart';

/// Paleta de colores de Safe Drive AI.
///
/// Todos los valores son constantes estáticas para uso directo en widgets.
/// No depende de ningún otro archivo del proyecto.
abstract final class AppColors {
  // ── Primarios ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primarySurface = Color(0xFFE3F2FD);

  // ── Acento ───────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF0288D1);

  // ── Neutros ──────────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  // ── Texto ────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semánticos ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningSurface = Color(0xFFFFFDE7);
  static const Color error = Color(0xFFC62828);
  static const Color errorSurface = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);
}
