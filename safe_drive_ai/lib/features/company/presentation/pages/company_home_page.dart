import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/company_bloc.dart';
import 'company_drivers_page.dart';
import 'company_invitations_page.dart';
import 'company_profile_page.dart';
import 'company_pending_trips_page.dart';

/// Pantalla principal de la empresa con BottomNavigationBar de 3 pestanas:
///   0 — Conductores
///   1 — Invitaciones
///   2 — Perfil
///
/// Provee [CompanyBloc] para todos los tabs hijos.
/// El [AuthBloc] ya viene provisto desde main.dart.
class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key, required this.company});

  final CompanyEntity company;

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  int _currentIndex = 0;

  static const List<_TabMeta> _tabs = [
    _TabMeta(
      label: 'Conductores',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    _TabMeta(
      label: 'Aprobaciones',
      icon: Icons.playlist_add_check_circle_outlined,
      activeIcon: Icons.playlist_add_check_circle,
    ),
    _TabMeta(
      label: 'Invitaciones',
      icon: Icons.mail_outline,
      activeIcon: Icons.mail,
    ),
    _TabMeta(
      label: 'Perfil',
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
    ),
  ];

  void _showDriverActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Agregar conductor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Registrar conductor nuevo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'El conductor aún no tiene cuenta en Safe Drive AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/company/register-driver',
                      extra: {
                        'companyId': widget.company.id,
                        'companyName': widget.company.name,
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(
                      Icons.mail_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Invitar conductor existente',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'El conductor ya tiene una cuenta en Safe Drive AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _currentIndex = 1);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompanyBloc>(
      create: (_) => di.sl<CompanyBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            context.go('/role-selection');
          }
        },
        child: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safe Drive AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    Text(
                      widget.company.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  CompanyDriversPage(
                    companyId: widget.company.id,
                    companyName: widget.company.name,
                  ),
                  CompanyPendingTripsPage(
                    companyId: widget.company.id,
                  ),
                  CompanyInvitationsPage(
                    companyId: widget.company.id,
                    companyName: widget.company.name,
                  ),
                  CompanyProfilePage(company: widget.company),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                backgroundColor: AppColors.surface,
                elevation: 8,
                type: BottomNavigationBarType.fixed,
                items: _tabs
                    .map(
                      (tab) => BottomNavigationBarItem(
                        icon: Icon(tab.icon),
                        activeIcon: Icon(tab.activeIcon),
                        label: tab.label,
                      ),
                    )
                    .toList(),
              ),
              floatingActionButton: _currentIndex == 0
                  ? FloatingActionButton.extended(
                      onPressed: () => _showDriverActionSheet(context),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text(
                        'Agregar conductor',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _TabMeta {
  const _TabMeta({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
