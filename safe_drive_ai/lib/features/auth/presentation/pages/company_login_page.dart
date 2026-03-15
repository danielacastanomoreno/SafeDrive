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

/// Pantalla de inicio de sesión para empresas.
///
/// Valida email y contraseña, luego despacha [AuthCompanyLoginRequested].
/// La navegación post-login se maneja en el listener del [BlocConsumer].
class CompanyLoginPage extends StatefulWidget {
  const CompanyLoginPage({super.key});

  @override
  State<CompanyLoginPage> createState() => _CompanyLoginPageState();
}

class _CompanyLoginPageState extends State<CompanyLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthCompanyLoginRequested(
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
        title: const Text('Iniciar sesión — Empresa'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthCompanyAuthenticated) {
            context.go('/company/home', extra: state.company);
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
                    const SizedBox(height: 16),
                    const Text(
                      'Acceso empresarial',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingresa los datos de tu empresa para continuar',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthTextFieldWidget(
                      label: 'Correo electrónico',
                      hint: 'empresa@correo.com',
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.email_outlined,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    PasswordFieldWidget(
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La contraseña es requerida';
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
                      label: 'Iniciar sesión',
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push('/forgot-password'),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push('/company/register'),
                        child: const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ),
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
