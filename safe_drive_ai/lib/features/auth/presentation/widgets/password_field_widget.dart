import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'auth_text_field_widget.dart';

/// Campo de contraseña con botón de toggle para mostrar u ocultar el texto.
///
/// Es el único widget del feature auth que requiere [StatefulWidget] por el
/// estado local [_obscure]. No contiene lógica de negocio.
class PasswordFieldWidget extends StatefulWidget {
  const PasswordFieldWidget({
    super.key,
    this.label = 'Contraseña',
    required this.controller,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordFieldWidget> createState() => _PasswordFieldWidgetState();
}

class _PasswordFieldWidgetState extends State<PasswordFieldWidget> {
  bool _obscure = true;

  void _toggleObscure() {
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextFieldWidget(
      label: widget.label,
      hint: '••••••••',
      controller: widget.controller,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscure,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
        onPressed: _toggleObscure,
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
      ),
    );
  }
}
