import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/role_button_widget.dart';

const _userRolePrefsKey = 'user_role';

/// Pantalla de selección de rol.
///
/// El usuario elige entre 'Conductor' y 'Empresa'. No requiere autenticación
/// previa. No tiene lógica de negocio: delega la navegación al router.
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRolePrefsKey, role);

    if (!context.mounted) return;
    if (role == 'driver') {
      context.push('/driver/login');
    } else {
      context.push('/company/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bienvenido a Safe Drive AI'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Safe Drive AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona tu tipo de cuenta para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),
              RoleButtonWidget(
                label: 'Soy conductor',
                icon: Icons.drive_eta,
                color: AppColors.primary,
                onTap: () => _selectRole(context, 'driver'),
              ),
              const SizedBox(height: 16),
              RoleButtonWidget(
                label: 'Soy empresa',
                icon: Icons.business,
                color: AppColors.accent,
                onTap: () => _selectRole(context, 'company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
