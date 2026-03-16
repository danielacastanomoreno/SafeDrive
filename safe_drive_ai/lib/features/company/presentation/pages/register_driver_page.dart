import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/auth_text_field_widget.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

/// Formulario para registrar un conductor nuevo en Safe Drive AI
/// directamente desde la cuenta de empresa.
///
/// Crea cuenta en Firebase Auth (instancia secundaria), documento en `users`,
/// vínculo en `company_drivers` y envía email de restablecimiento.
class RegisterDriverPage extends StatefulWidget {
  const RegisterDriverPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  State<RegisterDriverPage> createState() => _RegisterDriverPageState();
}

class _RegisterDriverPageState extends State<RegisterDriverPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cargoController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  String? _validateCargo(String? value) {
    if (value == null || value.trim().length < 3) {
      return 'Mínimo 3 caracteres.';
    }
    if (value.trim().length > 50) return 'Máximo 50 caracteres.';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9 ]+$').hasMatch(value.trim())) {
      return 'Solo letras, números y espacios.';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;

    context.read<CompanyBloc>().add(
          CompanyDriverRegisterRequested(
            companyId: widget.companyId,
            companyName: widget.companyName,
            name: _nameController.text.trim(),
            cedula: _cedulaController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            cargo: _cargoController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, state) {
        if (state is CompanyLoading) {
          setState(() => _isSubmitting = true);
        } else {
          setState(() => _isSubmitting = false);
        }

        if (state is CompanyActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        } else if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          title: const Text(
            'Registrar conductor nuevo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(
                    'Datos del conductor',
                    'Ingresa la información del nuevo conductor. Se le enviará un correo para que establezca su contraseña.',
                  ),
                  const SizedBox(height: 24),
                  AuthTextFieldWidget(
                    label: 'Nombre completo',
                    hint: 'Juan Pérez García',
                    controller: _nameController,
                    validator: Validators.name,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  AuthTextFieldWidget(
                    label: 'Cédula',
                    hint: '1234567890',
                    controller: _cedulaController,
                    validator: Validators.cedula,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.badge_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AuthTextFieldWidget(
                    label: 'Correo electrónico',
                    hint: 'conductor@correo.com',
                    controller: _emailController,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  AuthTextFieldWidget(
                    label: 'Teléfono',
                    hint: '3001234567',
                    controller: _phoneController,
                    validator: Validators.phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.phone_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AuthTextFieldWidget(
                    label: 'Cargo',
                    hint: 'Conductor urbano',
                    controller: _cargoController,
                    validator: _validateCargo,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.work_outline,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<CompanyBloc, CompanyState>(
      buildWhen: (previous, current) =>
          current is CompanyLoading ||
          current is CompanyActionSuccess ||
          current is CompanyError ||
          current is CompanyDriversLoaded,
      builder: (context, state) {
        final isLoading = state is CompanyLoading;
        return SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.primaryLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Registrar conductor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El conductor recibirá un correo para establecer su contraseña y podrá iniciar sesión en Safe Drive AI.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
