import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Banner de error para formularios de autenticación.
///
/// Muestra un ícono de advertencia y el mensaje de error sobre fondo
/// [AppColors.errorSurface]. Stateless y sin lógica de negocio.
class AuthErrorWidget extends StatelessWidget {
  const AuthErrorWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
