import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../trips/domain/usecases/end_trip_usecase.dart';
import '../../../trips/domain/usecases/get_active_trip_usecase.dart';
import '../../../trips/domain/usecases/save_route_point_usecase.dart';
import '../../../trips/domain/usecases/start_trip_usecase.dart';
import '../../../trips/domain/usecases/request_remote_closure_usecase.dart';
import '../../../trips/domain/usecases/listen_to_approval_stream_usecase.dart';
import '../../../trips/domain/usecases/end_trip_with_zone_check_usecase.dart';
import '../../../trips/presentation/bloc/trip_bloc.dart';
import '../../../trips/presentation/bloc/trip_event.dart';
import '../../../trips/presentation/bloc/trip_state.dart';
import '../../../trips/presentation/pages/trip_map_page.dart';
import '../../../trips/presentation/widgets/trip_panel_widget.dart';
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
/// Provee [DriverBloc] y [TripBloc] para todos los tabs.
/// El índice 3 del [IndexedStack] es el mapa en vivo [TripMapPage].
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
  late final TripBloc _tripBloc;

  @override
  void initState() {
    super.initState();
    _tripBloc = TripBloc(
      startTripUseCase: sl<StartTripUseCase>(),
      endTripUseCase: sl<EndTripUseCase>(),
      getActiveTripUseCase: sl<GetActiveTripUseCase>(),
      saveRoutePointUseCase: sl<SaveRoutePointUseCase>(),
      requestRemoteClosureUseCase: sl<RequestRemoteClosureUseCase>(),
      listenToApprovalStreamUseCase: sl<ListenToApprovalStreamUseCase>(),
      endTripWithZoneCheckUseCase: sl<EndTripWithZoneCheckUseCase>(),
    )..add(TripCheckActiveRequested(driverId: widget.driver.id));
  }

  @override
  void dispose() {
    _tripBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showingMap = _currentIndex == 3;

    return MultiBlocProvider(
      providers: [
        BlocProvider<DriverBloc>(
          create: (_) => DriverBloc(
            getDriverInvitationsUseCase: sl<GetDriverInvitationsUseCase>(),
            acceptInvitationUseCase: sl<AcceptInvitationUseCase>(),
            rejectInvitationUseCase: sl<RejectInvitationUseCase>(),
            getDriverLinkedCompaniesUseCase:
                sl<GetDriverLinkedCompaniesUseCase>(),
            updateDriverProfileUseCase: sl<UpdateDriverProfileUseCase>(),
          ),
        ),
        BlocProvider<TripBloc>.value(value: _tripBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthLoggedOut) {
                context.go('/role-selection');
              }
            },
          ),
          BlocListener<TripBloc, TripState>(
            listener: (context, state) {
              if (state is TripEnded) {
                if (_currentIndex == 3) setState(() => _currentIndex = 0);
                context.push('/trip/summary', extra: state.trip);
              } else if (state is TripFinalizedSuccess) {
                // Remote/PIN closure succeeded - navigate to summary with minimal data
                // The trip is already finalized in Firestore
                if (_currentIndex == 3) setState(() => _currentIndex = 0);
                // Navigate with null - summary page will handle it
                context.push('/trip/summary', extra: null);
              } else if (state is TripActive && state.isNewlyStarted) {
                // Auto-open map the moment a new trip starts
                setState(() => _currentIndex = 3);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: showingMap
              ? null // TripMapPage has its own full-screen UI
              : AppBar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safe Drive AI',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.driver.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
          body: Column(
            children: [
              // Trip panel hidden while map is open (map has its own controls)
              if (!showingMap)
                TripPanelWidget(
                  driverId: widget.driver.id,
                  onOpenMap: () => setState(() => _currentIndex = 3),
                ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    DriverCompaniesPage(driver: widget.driver),
                    DriverInvitationsPage(driver: widget.driver),
                    DriverProfilePage(driver: widget.driver),
                    TripMapPage(
                      onClose: () => setState(() => _currentIndex = 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: showingMap
              ? null
              : BottomNavigationBar(
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
