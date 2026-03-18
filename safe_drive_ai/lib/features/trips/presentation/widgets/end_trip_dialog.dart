import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class EndTripDialog extends StatefulWidget {
  final String tripId;

  const EndTripDialog({super.key, required this.tripId});

  @override
  State<EndTripDialog> createState() => _EndTripDialogState();
}

class _EndTripDialogState extends State<EndTripDialog> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripEnded || state is TripPendingApproval) {
          Navigator.of(context).pop(true);
        } else if (state is TripClosureError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is TripError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final hasCompany = authState is AuthDriverAuthenticated && authState.companies.isNotEmpty;

        final isLoading = state is TripClosureLoading || state is TripClosureRequested || state is TripLoading;

        return AlertDialog(
          title: const Text('Finalizar Viaje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state is TripActive && state.trip.closureRequestedAt != null) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                const Text(
                  'El cierre está pendiente de aprobación por la empresa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Puedes esperar la aprobación o finalizar sin ella.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else if (!hasCompany) ...[
                const Text('¿Está seguro de que desea finalizar el viaje?'),
              ] else ...[
                const Text('Solicite autorización para terminar el viaje de forma segura.'),
              ],
            ],
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            if (!isLoading)
              ElevatedButton(
                onPressed: () {
                  context.read<TripBloc>().add(TripEndRequested(tripId: widget.tripId));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(hasCompany ? 'Finalizar Sin Aprobación' : 'Finalizar'),
              ),
          ],
        );
      },
    );
  }
}
