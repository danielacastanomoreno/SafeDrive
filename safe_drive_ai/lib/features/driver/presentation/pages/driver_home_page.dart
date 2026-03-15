import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/usecases/accept_invitation_usecase.dart';
import '../../domain/usecases/get_driver_invitations_usecase.dart';
import '../../domain/usecases/get_driver_linked_companies_usecase.dart';
import '../../domain/usecases/reject_invitation_usecase.dart';
import '../../domain/usecases/update_driver_profile_usecase.dart';
import '../bloc/driver_bloc.dart';
import 'driver_companies_page.dart';
import 'driver_invitations_page.dart';
import 'driver_profile_page.dart';

/// Página principal del conductor.
///
/// Provee el [DriverBloc] para todos los tabs. Escucha [AuthBloc]
/// para redirigir a `/role-selection` cuando la sesión se cierra.
class DriverHomePage extends StatefulWidget {
  const DriverHomePage({
    super.key,
    required this.driver,
    required this.companies,
  });

  final UserEntity driver;
  final List<CompanyLinkEntity> companies;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      DriverCompaniesPage(driver: widget.driver),
      DriverInvitationsPage(driver: widget.driver),
      DriverProfilePage(driver: widget.driver),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DriverBloc>(
      create: (_) => DriverBloc(
        getDriverInvitationsUseCase: sl<GetDriverInvitationsUseCase>(),
        acceptInvitationUseCase: sl<AcceptInvitationUseCase>(),
        rejectInvitationUseCase: sl<RejectInvitationUseCase>(),
        getDriverLinkedCompaniesUseCase: sl<GetDriverLinkedCompaniesUseCase>(),
        updateDriverProfileUseCase: sl<UpdateDriverProfileUseCase>(),
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            context.go('/role-selection');
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
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
                  ),
                ),
                Text(
                  widget.driver.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business),
                label: 'Mis Empresas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                activeIcon: Icon(Icons.mail),
                label: 'Invitaciones',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Mi Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
