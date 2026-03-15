import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';

/// Pestaña de perfil del conductor.
///
/// Muestra datos de solo lectura (cédula, correo) y permite editar
/// nombre y teléfono. También expone el botón de cierre de sesión.
class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key, required this.driver});

  final UserEntity driver;

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  late UserEntity _currentDriver;

  @override
  void initState() {
    super.initState();
    _currentDriver = widget.driver;
    _nameController = TextEditingController(text: widget.driver.name);
    _phoneController = TextEditingController();
    context.read<DriverBloc>().add(
          DriverProfileRequested(driverId: widget.driver.id),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DriverBloc>().add(
          DriverProfileUpdateRequested(
            driverId: _currentDriver.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverBloc, DriverState>(
      listenWhen: (previous, current) =>
          current is DriverActionSuccess ||
          current is DriverProfileLoaded ||
          current is DriverError,
      listener: (context, state) {
        if (state is DriverActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is DriverProfileLoaded) {
          setState(() {
            _currentDriver = state.driver;
            _nameController.text = state.driver.name;
          });
        } else if (state is DriverError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      buildWhen: (previous, current) =>
          current is DriverLoading ||
          current is DriverProfileLoaded ||
          current is DriverInitial ||
          current is DriverError,
      builder: (context, state) {
        final isLoading = state is DriverLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      _currentDriver.name.isNotEmpty
                          ? _currentDriver.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ReadOnlyField(
                  label: 'Cédula',
                  value: _currentDriver.cedula,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: 'Correo electrónico',
                  value: _currentDriver.email,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Datos editables',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length != 10 ||
                          !value.trim().startsWith('3')) {
                        return 'Teléfono inválido (10 dígitos, empieza con 3)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => context
                          .read<AuthBloc>()
                          .add(const AuthLogoutRequested()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
