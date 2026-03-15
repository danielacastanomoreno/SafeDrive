import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../widgets/driver_invitation_card_widget.dart';

/// Pestaña que lista las invitaciones del conductor.
///
/// Invitaciones pending muestran botones de aceptar/rechazar.
/// Invitaciones resolved muestran solo el estado.
class DriverInvitationsPage extends StatefulWidget {
  const DriverInvitationsPage({super.key, required this.driver});

  final UserEntity driver;

  @override
  State<DriverInvitationsPage> createState() => _DriverInvitationsPageState();
}

class _DriverInvitationsPageState extends State<DriverInvitationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(
          DriverInvitationsRequested(driverId: widget.driver.id),
        );
  }

  Future<void> _refresh() async {
    context.read<DriverBloc>().add(
          DriverInvitationsRequested(driverId: widget.driver.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverBloc, DriverState>(
      listenWhen: (previous, current) =>
          current is DriverActionSuccess || current is DriverError,
      listener: (context, state) {
        if (state is DriverActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
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
          current is DriverInvitationsLoaded ||
          current is DriverError,
      builder: (context, state) {
        if (state is DriverLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is DriverError) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is DriverInvitationsLoaded) {
          if (state.invitations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: AppColors.divider,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes invitaciones pendientes',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.invitations.length,
              itemBuilder: (context, index) => DriverInvitationCardWidget(
                invitation: state.invitations[index],
                driverId: widget.driver.id,
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
