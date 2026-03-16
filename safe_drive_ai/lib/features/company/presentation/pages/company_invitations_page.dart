import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/invitation_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';
import '../widgets/invitation_card_widget.dart';

/// Pestaña de invitaciones: formulario para enviar nuevas y lista de enviadas.
class CompanyInvitationsPage extends StatefulWidget {
  const CompanyInvitationsPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  State<CompanyInvitationsPage> createState() => _CompanyInvitationsPageState();
}

class _CompanyInvitationsPageState extends State<CompanyInvitationsPage> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _cargoController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _formExpanded = true;

  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(
          CompanyInvitationsRequested(companyId: widget.companyId),
        );
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _cargoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitInvitation() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CompanyBloc>().add(
          CompanyInvitationSendRequested(
            companyId: widget.companyId,
            companyName: widget.companyName,
            driverCedula: _cedulaController.text.trim(),
            cargo: _cargoController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );

    _cedulaController.clear();
    _cargoController.clear();
    _phoneController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _onRefresh() async {
    context.read<CompanyBloc>().add(
          CompanyInvitationsRequested(companyId: widget.companyId),
        );
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyBloc, CompanyState>(
      listenWhen: (previous, current) =>
          current is CompanyActionSuccess || current is CompanyError,
      listener: (context, state) {
        if (state is CompanyActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
      buildWhen: (previous, current) =>
          current is CompanyLoading ||
          current is CompanyInvitationsLoaded ||
          current is CompanyError,
      builder: (context, state) {
        final List<InvitationEntity> invitations =
            state is CompanyInvitationsLoaded ? state.invitations : const [];

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildForm(context, state)),
              if (state is CompanyLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (invitations.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyInvitations(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => InvitationCardWidget(
                      key: ValueKey(invitations[index].id),
                      invitation: invitations[index],
                      companyId: widget.companyId,
                    ),
                    childCount: invitations.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, CompanyState state) {
    final isLoading = state is CompanyLoading;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _formExpanded = !_formExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Invitar conductor',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _formExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_formExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Cedula del conductor',
                        hint: 'Ej: 1234567890',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La cedula es requerida';
                        }
                        final digits = value.trim();
                        if (digits.length < 6 || digits.length > 10) {
                          return 'La cedula debe tener entre 6 y 10 digitos';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(digits)) {
                          return 'Solo se permiten numeros';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cargoController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Cargo',
                        hint: 'Ej: Conductor de carga',
                        icon: Icons.work_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El cargo es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        label: 'Telefono de contacto',
                        hint: 'Ej: 3001234567',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El telefono es requerido';
                        }
                        final phone = value.trim();
                        if (!RegExp(r'^3\d{9}$').hasMatch(phone)) {
                          return 'Ingresa un celular colombiano valido (10 digitos, inicia con 3)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitInvitation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Enviar invitacion',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvitations() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mail_outline,
          size: 56,
          color: AppColors.divider,
        ),
        SizedBox(height: 12),
        Text(
          'No has enviado invitaciones',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
