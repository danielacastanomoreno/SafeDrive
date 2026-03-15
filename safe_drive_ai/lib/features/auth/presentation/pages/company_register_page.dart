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
import '../widgets/nit_field_widget.dart';
import '../widgets/password_field_widget.dart';
import '../widgets/primary_button_widget.dart';

/// Pantalla de registro de empresa.
///
/// Captura los 5 campos requeridos por [AuthCompanyRegisterRequested] y
/// valida confirmación de contraseña localmente. Usa [SingleChildScrollView]
/// para evitar overflow con el teclado abierto.
class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _nitValue;
  final _emailController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _representativeNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_nitValue == null) return;

    context.read<AuthBloc>().add(
          AuthCompanyRegisterRequested(
            name: _nameController.text.trim(),
            nit: _nitValue!.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            representativeName: _representativeNameController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar empresa'),
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
                    const SizedBox(height: 8),
                    const Text(
                      'Crea la cuenta de tu empresa',
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
                    // 1. Nombre de la empresa
                    AuthTextFieldWidget(
                      label: 'Nombre de la empresa',
                      hint: 'Razón social',
                      controller: _nameController,
                      validator: Validators.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.business_outlined,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    // 2. NIT
                    NitFieldWidget(
                      enabled: !isLoading,
                      onChanged: (value) => setState(() => _nitValue = value),
                    ),
                    const SizedBox(height: 16),
                    // 3. Correo electrónico
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
                    // 4. Nombre del representante legal
                    AuthTextFieldWidget(
                      label: 'Nombre del representante legal',
                      hint: 'Nombre completo',
                      controller: _representativeNameController,
                      validator: Validators.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outlined,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    // 5. Contraseña
                    PasswordFieldWidget(
                      label: 'Contraseña',
                      controller: _passwordController,
                      validator: Validators.password,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // 6. Confirmar contraseña
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
