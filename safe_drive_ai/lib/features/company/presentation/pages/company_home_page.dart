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
        child: Scaffold(
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
              ? FloatingActionButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  tooltip: 'Invitar conductor',
                  child: const Icon(Icons.person_add_outlined),
                )
              : null,
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
