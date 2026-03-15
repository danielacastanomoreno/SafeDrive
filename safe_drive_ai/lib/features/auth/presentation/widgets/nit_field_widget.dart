import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/nit_validator.dart';

/// Campo compuesto para ingresar un NIT colombiano.
///
/// Divide la entrada en dos partes:
/// - Campo de texto para los 9 dígitos base.
/// - Dropdown para seleccionar el dígito de verificación (0–9).
///
/// Cuando se han ingresado los 9 dígitos, calcula automáticamente
/// el dígito de verificación correcto y lo preselecciona.
///
/// El valor combinado final tiene el formato XXXXXXXXX-Y y se obtiene
/// mediante [onChanged].
class NitFieldWidget extends StatefulWidget {
  const NitFieldWidget({
    super.key,
    required this.onChanged,
    this.enabled = true,
  });

  /// Callback con el valor combinado "XXXXXXXXX-Y" cada vez que cambia.
  /// Devuelve null si aún no está completo.
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<NitFieldWidget> createState() => _NitFieldWidgetState();
}

class _NitFieldWidgetState extends State<NitFieldWidget> {
  final _digitsController = TextEditingController();
  int? _selectedDv;

  static const _borderRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _digitsController.addListener(_onDigitsChanged);
  }

  @override
  void dispose() {
    _digitsController.removeListener(_onDigitsChanged);
    _digitsController.dispose();
    super.dispose();
  }

  void _onDigitsChanged() {
    final digits = _digitsController.text;
    if (digits.length == 9) {
      // Auto-calcular el DV correcto
      final calculatedDv = _calculateDv(digits);
      if (_selectedDv != calculatedDv) {
        setState(() => _selectedDv = calculatedDv);
      }
    }
    _notify();
  }

  void _notify() {
    final digits = _digitsController.text;
    if (digits.length == 9 && _selectedDv != null) {
      widget.onChanged('$digits-$_selectedDv');
    } else {
      widget.onChanged(null);
    }
  }

  int _calculateDv(String digits) {
    const weights = [71, 67, 59, 53, 47, 43, 41, 37, 29];
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * weights[i];
    }
    final residuo = sum % 11;
    return residuo >= 2 ? 11 - residuo : residuo;
  }

  InputDecoration _decoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: widget.enabled ? AppColors.surface : AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => NitValidator.getError(
        _digitsController.text.length == 9 && _selectedDv != null
            ? '${_digitsController.text}-$_selectedDv'
            : null,
      ),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Campo de 9 dígitos ──────────────────────────────────
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _digitsController,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration('NIT (9 dígitos)').copyWith(
                      counterText: '',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.textSecondary,
                      ),
                      errorText: field.errorText,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        borderSide:
                            const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ── Guion decorativo ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '–',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ── Dropdown DV ─────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _selectedDv,
                    decoration: _decoration('DV'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    dropdownColor: AppColors.surface,
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('$i'),
                      ),
                    ),
                    onChanged: widget.enabled
                        ? (value) {
                            setState(() => _selectedDv = value);
                            _notify();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
