import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/usecases/get_driver_profile_usecase.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

class CompanyPendingTripsPage extends StatefulWidget {
  const CompanyPendingTripsPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  State<CompanyPendingTripsPage> createState() => _CompanyPendingTripsPageState();
}

class _CompanyPendingTripsPageState extends State<CompanyPendingTripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(
          CompanyPendingTripsRequested(companyId: widget.companyId),
        );
  }

  Future<void> _onRefresh() async {
    context.read<CompanyBloc>().add(
          CompanyPendingTripsRequested(companyId: widget.companyId),
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
          current is CompanyPendingTripsLoaded ||
          current is CompanyError,
      builder: (context, state) {
        if (state is CompanyLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is CompanyPendingTripsLoaded) {
          return _buildTripsList(context, state.pendingTrips);
        }

        if (state is CompanyError) {
          return _buildError(context, state.message);
        }

        return _buildTripsList(context, const []);
      },
    );
  }

  Widget _buildTripsList(BuildContext context, List<TripEntity> trips) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: trips.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.divider,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay viajes pendientes de aprobación',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _PendingTripCard(
                  trip: trip,
                  companyId: widget.companyId,
                );
              },
            ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<CompanyBloc>().add(
                      CompanyPendingTripsRequested(companyId: widget.companyId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingTripCard extends StatefulWidget {
  const _PendingTripCard({
    required this.trip,
    required this.companyId,
  });

  final TripEntity trip;
  final String companyId;

  @override
  State<_PendingTripCard> createState() => _PendingTripCardState();
}

class _PendingTripCardState extends State<_PendingTripCard> {
  String _driverName = 'Cargando conductor...';

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    final useCase = di.sl<GetDriverProfileUseCase>();
    final result = await useCase(GetDriverProfileParams(driverId: widget.trip.driverId));
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _driverName = 'Conductor Desconocido',
          (profile) => _driverName = profile.name,
        );
      });
    }
  }

  void _showTripDetails(BuildContext context) {
    context.push('/company/trip-approval', extra: {
      'trip': widget.trip,
      'companyId': widget.companyId,
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(
                    Icons.directions_car_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID Conductor: ${widget.trip.driverId.substring(0, 8)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Iniciado: ${_formatDate(widget.trip.startTime)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (widget.trip.closureRequestedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Solicitado: ${_formatDate(widget.trip.closureRequestedAt!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTripDetails(context),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
