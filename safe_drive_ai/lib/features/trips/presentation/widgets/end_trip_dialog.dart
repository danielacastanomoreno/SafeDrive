import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';

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
        if (state is TripEnded) {
          Navigator.of(context).pop(true);
        } else if (state is TripError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is TripLoading;

        return AlertDialog(
          title: const Text('Finalizar viaje'),
          content: const Text('¿Confirmas que quieres finalizar el viaje?'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<TripBloc>().add(
                            TripEndRequested(
                              tripId: widget.tripId,
                              endedAt: DateTime.now(),
                            ),
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sí, finalizar'),
            ),
          ],
        );
      },
    );
  }
}
