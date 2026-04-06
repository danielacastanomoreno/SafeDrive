import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_error_widget.dart';
import '../widgets/auth_text_field_widget.dart';
import '../widgets/password_field_widget.dart';
import '../widgets/primary_button_widget.dart';

/// Pantalla de registro independiente de conductor.
///
/// Captura los 4 campos requeridos por [AuthDriverRegisterRequested] y
/// valida confirmación de contraseña localmente.
class DriverRegisterPage extends StatefulWidget {
  const DriverRegisterPage({super.key});

  @override
  State<DriverRegisterPage> createState() => _DriverRegisterPageState();
}

class _DriverRegisterPageState extends State<DriverRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthDriverRegisterRequested(
            name: _nameController.text.trim(),
            cedula: _cedulaController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrarse como Conductor'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthDriverAuthenticated) {
            context.go('/driver/home', extra: state);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Completa todos los campos para registrarte.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // 1. Nombre
                    AuthTextFieldWidget(
                      label: 'Nombre completo',
                      hint: 'Ingresa tu nombre completo',
                      controller: _nameController,
                      validator: Validators.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outlined,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    // 2. Cédula
                    AuthTextFieldWidget(
                      label: 'Cédula de ciudadanía',
                      hint: 'Ingresa tu número de cédula',
                      controller: _cedulaController,
                      validator: Validators.cedula,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.badge_outlined,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    // 3. Correo electrónico
                    AuthTextFieldWidget(
                      label: 'Correo electrónico',
                      hint: 'conductor@correo.com',
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.email_outlined,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    // 4. Contraseña
                    PasswordFieldWidget(
                      label: 'Contraseña',
                      controller: _passwordController,
                      validator: Validators.password,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // 5. Confirmar contraseña
                    PasswordFieldWidget(
                      label: 'Confirmar contraseña',
                      controller: _confirmPasswordController,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    if (state is AuthError) ...[
                      AuthErrorWidget(message: state.message),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButtonWidget(
                      label: 'Crear cuenta',
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: isLoading ? null : () => context.pop(),
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
