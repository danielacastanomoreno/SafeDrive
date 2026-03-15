// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

/// Paleta de colores oficial de Safe Drive AI.
/// Usar siempre estas constantes — nunca Color() literal en widgets.
abstract class AppColors {
  AppColors._();

  // ── Primario — Azul institucional ─────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);       // Azul oscuro principal
  static const Color primaryDark = Color(0xFF003C8F);   // Azul muy oscuro (AppBar, header)
  static const Color primaryLight = Color(0xFF5E92F3);  // Azul claro (hover, estados)
  static const Color primarySurface = Color(0xFFE3F2FD);// Fondo azul suave (tarjetas)

  // ── Acento ────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF0288D1);        // Azul acento (íconos, chips)

  // ── Neutros ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);    // Fondo general de la app
  static const Color surface = Color(0xFFFFFFFF);       // Fondo de tarjetas
  static const Color divider = Color(0xFFE0E0E0);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);   // Texto principal
  static const Color textSecondary = Color(0xFF757575); // Texto secundario / hints
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Texto sobre fondo primario

  // ── Semánticos ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);       // Verde éxito
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);       // Amarillo advertencia
  static const Color warningSurface = Color(0xFFFFFDE7);
  static const Color error = Color(0xFFC62828);         // Rojo error / alerta crítica
  static const Color errorSurface = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);          // Azul info

  // ── Estados de viaje ─────────────────────────────────────────────────────
  static const Color tripActive = Color(0xFF2E7D32);    // Verde — viaje activo
  static const Color tripCompleted = Color(0xFF1565C0); // Azul — viaje completado
  static const Color alertDrowsiness = Color(0xFFF57F17); // Naranja — somnolencia L1
  static const Color alertCritical = Color(0xFFC62828);   // Rojo — somnolencia L2

  // ── Sombras ───────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);        // Sombra suave (10% negro)
}
