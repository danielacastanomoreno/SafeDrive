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
  final TextEditingController _pinController = TextEditingController();
  bool _isUsingPin = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripEnded) {
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

        final isLoading =
            state is TripClosureLoading || state is TripClosureRequested || state is TripLoading;

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
                  'El cierre ya fue solicitado y está pendiente de aprobación por la central.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (hasCompany) ...[
                  const Text('Si la central te proporcionó un PIN de contingencia, puedes ingresarlo aquí:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'PIN de Contingencia',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ] else if (_isUsingPin && hasCompany) ...[
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'PIN de Contingencia',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else if (!hasCompany) ...[
                const Text('¿Está seguro de que desea finalizar el viaje?'),
              ] else ...[
                const Text(
                    'Solicite autorización para terminar el viaje de forma segura.'),
              ],
            ],
          ),
          actions: [
            if (!isLoading && !_isUsingPin && hasCompany && (state is! TripActive || state.trip.closureRequestedAt == null))
              TextButton(
                onPressed: () => setState(() => _isUsingPin = true),
                child: const Text('Usar PIN de Contingencia'),
              ),
            if (!isLoading && _isUsingPin && hasCompany && (state is! TripActive || state.trip.closureRequestedAt == null))
              TextButton(
                onPressed: () => setState(() => _isUsingPin = false),
                child: const Text('Volver'),
              ),
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cerrar'),
              ),
            if (!isLoading && (state is! TripActive || state.trip.closureRequestedAt == null || _pinController.text.length == 4))
              ElevatedButton(
                onPressed: () {
                  if (!hasCompany) {
                    context.read<TripBloc>().add(TripEndRequested(tripId: widget.tripId));
                  } else if (_isUsingPin || (state is TripActive && state.trip.closureRequestedAt != null)) {
                    if (_pinController.text.length == 4) {
                      context.read<TripBloc>().add(
                            VerifyManualPinEvent(
                              tripId: widget.tripId,
                              pin: _pinController.text,
                            ),
                          );
                    }
                  } else {
                    context.read<TripBloc>().add(
                          RequestRemoteClosureEvent(tripId: widget.tripId),
                        );
                  }
                },
                style: !hasCompany ? ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white) : null,
                child: Text(!hasCompany ? 'Finalizar' : ((_isUsingPin || (state is TripActive && state.trip.closureRequestedAt != null)) ? 'Validar PIN' : 'Solicitar Aprobación')),
              ),
          ],
        );
      },
    );
  }
}
